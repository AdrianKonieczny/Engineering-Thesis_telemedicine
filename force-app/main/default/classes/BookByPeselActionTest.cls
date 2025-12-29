@isTest
public class BookByPeselActionTest {

    // Krok 1: Przygotowanie danych testowych (uruchamia się przed każdym testem)
    @testSetup
    static void setupData() {
        // Tworzymy pacjenta
        Patient__c pat = new Patient__c(
            Name = 'Test Patient',
            PESEL__c = '90010112345',
            Email__c = 'test@example.com'
        );
        insert pat;
        
        // Tworzymy lekarza (używamy bieżącego usera)
        Id docId = UserInfo.getUserId();
        
        // Tworzymy dostępność (żeby sloty miały rodzica, choć nie jest to krytyczne dla tego testu)
        Availability__c av = new Availability__c(
            Practitioner__c = docId,
            Start__c = DateTime.now(),
            End__c = DateTime.now().addHours(8)
        );
        insert av;

        // TWORZYMY SLOTY
        List<Slot__c> slots = new List<Slot__c>();
        
        // Slot A: Przyszłość (prawidłowy) - np. za godzinę
        DateTime futureTime = DateTime.now().addHours(1); 
        // Zaokrąglamy do pełnej godziny lub połówki dla łatwego formatowania
        // (W uproszczeniu testowym zakładamy, że format HH:mm zadziała)
        
        slots.add(new Slot__c(
            Practitioner__c = docId,
            Availability__c = av.Id,
            Start__c = futureTime,
            End__c = futureTime.addMinutes(30),
            IsBlocked__c = false
        ));
        
        // Slot B: Przeszłość (do testowania błędu) - np. godzina temu
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
        // Ustawiamy Mocka (udajemy Zooma), bo akcja bookowania wywoła VideoService
        Test.setMock(HttpCalloutMock.class, new VideoServiceMock());
        
        // Pobieramy slot z przyszłości, który stworzyliśmy w setupie
        Slot__c futureSlot = [SELECT Start__c FROM Slot__c WHERE Start__c > :DateTime.now() LIMIT 1];
        String timeStr = futureSlot.Start__c.format('HH:mm'); // np. "14:30"
        
        // Przygotowujemy żądanie od Agenta
        BookByPeselAction.Request req = new BookByPeselAction.Request();
        req.pesel = '90010112345';
        req.timeString = timeStr;
        
        // Uruchamiamy test
        Test.startTest();
        List<BookByPeselAction.Request> reqList = new List<BookByPeselAction.Request>{req};
        List<BookByPeselAction.Result> results = BookByPeselAction.bookSlot(reqList);
        Test.stopTest();
        
        // Weryfikacja
        System.assert(results[0].message.contains('Success'), 'Booking should succeed. Msg: ' + results[0].message);
        
        // Sprawdzamy czy wizyta powstała w bazie
        Appointment__c appt = [SELECT Id, Status__c, Patient__r.PESEL__c FROM Appointment__c LIMIT 1];
        System.assertEquals('Booked', appt.Status__c);
        System.assertEquals('90010112345', appt.Patient__r.PESEL__c);
    }
    
    @isTest
    static void testBookingPastDate() {
        // Pobieramy slot z przeszłości
        Slot__c pastSlot = [SELECT Start__c FROM Slot__c WHERE Start__c < :DateTime.now() LIMIT 1];
        String timeStr = pastSlot.Start__c.format('HH:mm');
        
        BookByPeselAction.Request req = new BookByPeselAction.Request();
        req.pesel = '90010112345';
        req.timeString = timeStr;
        
        Test.startTest();
        List<BookByPeselAction.Result> results = BookByPeselAction.bookSlot(new List<BookByPeselAction.Request>{req});
        Test.stopTest();
        
        // Oczekujemy błędu o dacie wstecz
        System.assert(results[0].message.contains('past'), 'Should return error about past time. Actual: ' + results[0].message);
    }
    
    @isTest
    static void testBookingNoSlotFound() {
        BookByPeselAction.Request req = new BookByPeselAction.Request();
        req.pesel = '90010112345';
        req.timeString = '00:00'; // Godzina, której na pewno nie ma
        
        Test.startTest();
        List<BookByPeselAction.Result> results = BookByPeselAction.bookSlot(new List<BookByPeselAction.Request>{req});
        Test.stopTest();
        
        System.assert(results[0].message.contains('Could not find'), 'Should return error about missing slot');
    }
}