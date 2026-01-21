/**
 * @description Unit tests for AppointmentAgentAction.
 * Covers success scenarios (booking creation, slot blocking) and error handling.
 * @author AK
 */
@isTest
private class AppointmentAgentActionTest {

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

        Slot__c slot = new Slot__c(
            Start__c = DateTime.now().addHours(1),
            End__c = DateTime.now().addHours(2),
            IsBlocked__c = false
        );
        insert slot;
    }

    /**
     * @description Verifies that a valid request creates an appointment, blocks the slot, and returns success status.
     */
    @isTest
    static void testBookAppointmentSuccess() {
        Patient__c pat = [SELECT Id FROM Patient__c LIMIT 1];
        Slot__c slot = [SELECT Id, Start__c FROM Slot__c LIMIT 1];

        AppointmentAgentAction.Request req = new AppointmentAgentAction.Request();
        req.patientId = pat.Id; 
        req.slotId = slot.Id;

        List<AppointmentAgentAction.Request> requestList = new List<AppointmentAgentAction.Request>{req};

        Test.setMock(HttpCalloutMock.class, new VideoServiceMock());

        Test.startTest();
        List<AppointmentAgentAction.Result> results = AppointmentAgentAction.bookAppointment(requestList);
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Result list should not be empty');
        System.assertEquals('Success. Appointment booked.', results[0].status);
        System.assert(results[0].appointmentId != null, 'Appointment ID should be returned');
        
        Appointment__c createdAppt = [SELECT Id, Patient__c, Status__c FROM Appointment__c WHERE Id = :results[0].appointmentId];
        System.assertEquals(pat.Id, createdAppt.Patient__c);
        
        Slot__c updatedSlot = [SELECT IsBlocked__c FROM Slot__c WHERE Id = :slot.Id];
        System.assertEquals(true, updatedSlot.IsBlocked__c, 'Slot should be blocked after booking');
    }

    /**
     * @description Verifies that the method handles exceptions gracefully and returns an error message.
     */
    @isTest
    static void testBookAppointmentFailure() {
        AppointmentAgentAction.Request req = new AppointmentAgentAction.Request();
        req.patientId = null; 
        req.slotId = null; 
        
        List<AppointmentAgentAction.Request> requestList = new List<AppointmentAgentAction.Request>{req};

        Test.startTest();
        List<AppointmentAgentAction.Result> results = AppointmentAgentAction.bookAppointment(requestList);
        Test.stopTest();
        
        System.assert(!results.isEmpty());
        System.assert(results[0].status.startsWith('Error'), 'Status should indicate an error occurred');
    }
}