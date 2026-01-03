@isTest
public class BookByPeselActionTest {

    @testSetup
    static void setupData() {
        // KROK 1: Tworzymy pacjenta, który przejdzie Twoją rygorystyczną walidację
        // PESEL: 44051401359
        // 440514 -> Data urodzenia: 1944-05-14
        // 10. cyfra to '5' (nieparzysta) -> Płeć: Male
        
        Patient__c pat = new Patient__c(
            Name = 'Test Patient',
            PESEL__c = '44051401359',
            Email__c = 'test@example.com',
            // Dodajemy wymagane pola zgodne z logiką PESEL:
            Date_of_Birth__c = Date.newInstance(1944, 5, 14),
            Gender__c = 'Male' 
        );
        insert pat;
        
        // KROK 2: Przygotowanie lekarza i dostępności
        Id docId = UserInfo.getUserId();
        
        Availability__c av = new Availability__c(
            Practitioner__c = docId,
            Start__c = DateTime.now(),
            End__c = DateTime.now().addHours(8)
        );
        insert av;

        // KROK 3: Generowanie Slotów
        List<Slot__c> slots = new List<Slot__c>();
        
        // Slot A: Przyszłość (prawidłowy do rezerwacji)
        DateTime futureTime = DateTime.now().addHours(1); 
        slots.add(new Slot__c(
            Practitioner__c = docId,
            Availability__c = av.Id,
            Start__c = futureTime,
            End__c = futureTime.addMinutes(30),
            IsBlocked__c = false
        ));
        
        // Slot B: Przeszłość (do testowania blokady rezerwacji wstecz)
        DateTime pastTime = DateTime.now().addHours(-1);
        slots.add(new Slot__c(
            Practitioner__c = docId,
            Availability__c = av.Id,
            Start__c = pastTime,
            End__c = pastTime.addMinutes(30),
            IsBlocked__c = false
        ));
        
        insert slots;
    }

    @isTest
    static void testBookingSuccess() {
        // Ustawiamy Mocka dla Calloutu wideo
        Test.setMock(HttpCalloutMock.class, new VideoServiceMock());
        
        // Pobieramy slot z przyszłości
        Slot__c futureSlot = [SELECT Start__c FROM Slot__c WHERE Start__c > :DateTime.now() LIMIT 1];
        String timeStr = futureSlot.Start__c.format('HH:mm');
        
        // Przygotowujemy request z poprawnym PESELem
        BookByPeselAction.Request req = new BookByPeselAction.Request();
        req.pesel = '44051401359';
        req.timeString = timeStr;
        
        Test.startTest();
        List<BookByPeselAction.Result> results = BookByPeselAction.bookSlot(new List<BookByPeselAction.Request>{req});
        Test.stopTest();
        
        // Weryfikacja sukcesu
        System.assert(results[0].message.contains('Success'), 'Booking should succeed. Msg: ' + results[0].message);
        
        // Sprawdzenie czy Appointment został utworzony
        Appointment__c appt = [SELECT Id, Status__c, Patient__r.PESEL__c FROM Appointment__c LIMIT 1];
        System.assertEquals('Booked', appt.Status__c);
        System.assertEquals('44051401359', appt.Patient__r.PESEL__c);
    }
    
    @isTest
    static void testBookingPastDate() {
        // Pobieramy slot z przeszłości
        Slot__c pastSlot = [SELECT Start__c FROM Slot__c WHERE Start__c < :DateTime.now() LIMIT 1];
        String timeStr = pastSlot.Start__c.format('HH:mm');
        
        BookByPeselAction.Request req = new BookByPeselAction.Request();
        req.pesel = '44051401359';
        req.timeString = timeStr;
        
        Test.startTest();
        List<BookByPeselAction.Result> results = BookByPeselAction.bookSlot(new List<BookByPeselAction.Request>{req});
        Test.stopTest();
        
        // Oczekujemy błędu o czasie z przeszłości
        System.assert(results[0].message.contains('past'), 'Should return error about past time. Actual: ' + results[0].message);
    }
    
    @isTest
    static void testBookingNoSlotFound() {
        BookByPeselAction.Request req = new BookByPeselAction.Request();
        req.pesel = '44051401359';
        req.timeString = '00:00'; // Godzina, której nie ma
        
        Test.startTest();
        List<BookByPeselAction.Result> results = BookByPeselAction.bookSlot(new List<BookByPeselAction.Request>{req});
        Test.stopTest();
        
        // Oczekujemy błędu o braku slotu
        System.assert(results[0].message.contains('Could not find'), 'Should return error about missing slot');
    }

    @isTest
    static void testBookingException_PatientNotFound() {
        
        BookByPeselAction.Request req = new BookByPeselAction.Request();
        req.pesel = '00000000000'; 
        req.timeString = '12:00';

        Test.startTest();
        List<BookByPeselAction.Result> results = BookByPeselAction.bookSlot(new List<BookByPeselAction.Request>{req});
        Test.stopTest();
        
        System.assert(results != null && !results.isEmpty(), 'Result list should not be empty');
        System.assert(results[0].message.contains('Error'), 'Message should indicate an error. Actual: ' + results[0].message);
        

        Log__c errorLog = [SELECT Id, Action__c, Payload__c FROM Log__c WHERE Action__c = 'BookSlotError' LIMIT 1];
        System.assertNotEquals(null, errorLog, 'Error log should be created in catch block');

        String payload = errorLog.Payload__c;
        System.debug('Log Payload: ' + payload);
        
        System.assert(!payload.contains('00000000000'), 'Payload should NOT contain the raw sensitive PESEL');
    }
}