/**
 * @description Unit tests for the BookByPeselAction class.
 * Covers positive booking flow, business validation logic (past dates, missing slots), 
 * and error logging with security checks.
 * @author AK
 */
@isTest
public class BookByPeselActionTest {

    @testSetup
    static void setupData() {
        Patient__c pat = new Patient__c(
            Name = 'Test Patient',
            PESEL__c = '44051401359',
            Email__c = 'test@example.com',
            Date_of_Birth__c = Date.newInstance(1944, 5, 14),
            Gender__c = 'Male' 
        );
        insert pat;
        
        Id docId = UserInfo.getUserId();
        
        Availability__c av = new Availability__c(
            Practitioner__c = docId,
            Start__c = DateTime.now(),
            End__c = DateTime.now().addHours(8)
        );
        insert av;

        List<Slot__c> slots = new List<Slot__c>();
        
        DateTime futureTime = DateTime.now().addHours(1); 
        slots.add(new Slot__c(
            Practitioner__c = docId,
            Availability__c = av.Id,
            Start__c = futureTime,
            End__c = futureTime.addMinutes(30),
            IsBlocked__c = false
        ));
        
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

    /**
     * @description Verifies that a valid request creates an appointment and returns success.
     */
    @isTest
    static void testBookingSuccess() {
        Test.setMock(HttpCalloutMock.class, new VideoServiceMock());
        
        Slot__c futureSlot = [SELECT Start__c FROM Slot__c WHERE Start__c > :DateTime.now() LIMIT 1];
        String timeStr = futureSlot.Start__c.format('HH:mm');
        
        BookByPeselAction.Request req = new BookByPeselAction.Request();
        req.pesel = '44051401359';
        req.timeString = timeStr;
        
        Test.startTest();
        List<BookByPeselAction.Result> results = BookByPeselAction.bookSlot(new List<BookByPeselAction.Request>{req});
        Test.stopTest();
        
        System.assert(results[0].message.contains('Success'), 'Booking should succeed. Msg: ' + results[0].message);
        
        Appointment__c appt = [SELECT Id, Status__c, Patient__r.PESEL__c FROM Appointment__c LIMIT 1];
        System.assertEquals('Booked', appt.Status__c);
        System.assertEquals('44051401359', appt.Patient__r.PESEL__c);
    }
    
    /**
     * @description Ensures that attempting to book a slot in the past throws a validation error.
     */
    @isTest
    static void testBookingPastDate() {
        Slot__c pastSlot = [SELECT Start__c FROM Slot__c WHERE Start__c < :DateTime.now() LIMIT 1];
        String timeStr = pastSlot.Start__c.format('HH:mm');
        
        BookByPeselAction.Request req = new BookByPeselAction.Request();
        req.pesel = '44051401359';
        req.timeString = timeStr;
        
        Test.startTest();
        List<BookByPeselAction.Result> results = BookByPeselAction.bookSlot(new List<BookByPeselAction.Request>{req});
        Test.stopTest();
        
        System.assert(results[0].message.contains('past'), 'Should return error about past time. Actual: ' + results[0].message);
    }
    
    /**
     * @description Verifies error handling when no slot matches the requested time.
     */
    @isTest
    static void testBookingNoSlotFound() {
        BookByPeselAction.Request req = new BookByPeselAction.Request();
        req.pesel = '44051401359';
        req.timeString = '00:00';
        
        Test.startTest();
        List<BookByPeselAction.Result> results = BookByPeselAction.bookSlot(new List<BookByPeselAction.Request>{req});
        Test.stopTest();
        
        System.assert(results[0].message.contains('Could not find'), 'Should return error about missing slot');
    }

    /**
     * @description Tests exception handling (Patient not found) and verifies SECURITY requirement:
     * Sensitive data (PESEL) must be masked in the error logs.
     */
    @isTest
    static void testBookingException_PatientNotFound() {
        String sensitivePesel = '00000000000';
        BookByPeselAction.Request req = new BookByPeselAction.Request();
        req.pesel = sensitivePesel; 
        req.timeString = '12:00';

        Test.startTest();
        List<BookByPeselAction.Result> results = BookByPeselAction.bookSlot(new List<BookByPeselAction.Request>{req});
        Test.stopTest();
        
        System.assert(results[0].message.contains('Error'), 'Message should indicate an error.');
        
        Log__c errorLog = [SELECT Id, Payload__c FROM Log__c WHERE Action__c = 'BookSlotError' LIMIT 1];
        System.assertNotEquals(null, errorLog, 'Error log should be created in catch block');
        System.assert(!errorLog.Payload__c.contains(sensitivePesel), 'Security Breach: Payload should NOT contain raw sensitive PESEL');
    }
}