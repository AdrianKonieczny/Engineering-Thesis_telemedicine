@isTest
public class AppointmentAgentActionTest {

    @testSetup
    static void setupData() {
        // 1. Create Patient
        Patient__c pat = new Patient__c(
            Name = 'Test Patient',
            PESEL__c = '44051401359',
            Email__c = 'test@example.com',
            Date_of_Birth__c = Date.newInstance(1944, 5, 14),
            Gender__c = 'Male'
        );
        insert pat;

        // 2. Create Slot
        Slot__c slot = new Slot__c(
            Start__c = DateTime.now().addHours(1),
            End__c = DateTime.now().addHours(2),
            IsBlocked__c = false
        );
        insert slot;
    }

    @isTest
    static void testBookAppointmentSuccess() {
        // Fetch Data
        Patient__c pat = [SELECT Id FROM Patient__c LIMIT 1];
        Slot__c slot = [SELECT Id, Start__c FROM Slot__c LIMIT 1];

        // PREPARE REQUEST
        AppointmentAgentAction.Request req = new AppointmentAgentAction.Request();
        
        // CORRECTED: The main class expects 'patientId' (Id), not PESEL string
        req.patientId = pat.Id; 
        req.slotId = slot.Id;

        List<AppointmentAgentAction.Request> requestList = new List<AppointmentAgentAction.Request>();
        requestList.add(req);

        // MOCK CALLOUT
        // We need this because AppointmentAgentAction calls VideoService, which likely makes an HTTP callout.
        Test.setMock(HttpCalloutMock.class, new VideoServiceMock());

        // EXECUTE ACTION
        Test.startTest();
        List<AppointmentAgentAction.Result> results = AppointmentAgentAction.bookAppointment(requestList);
        Test.stopTest();

        // ASSERTIONS
        System.assert(results != null, 'Result list should not be null');
        System.assert(!results.isEmpty(), 'Result list should not be empty');
        
        // Check the Result object fields based on your main class logic
        AppointmentAgentAction.Result singleResult = results[0];
        System.assertEquals('Success. Appointment booked.', singleResult.status, 'Status should verify success');
        System.assert(singleResult.appointmentId != null, 'Appointment ID should be returned');
        
        // Verify Database Changes
        Appointment__c createdAppt = [
            SELECT Id, Patient__c, Start__c, Status__c 
            FROM Appointment__c 
            WHERE Id = :singleResult.appointmentId 
            LIMIT 1
        ];
        
        System.assertEquals(pat.Id, createdAppt.Patient__c, 'Patient should be assigned correctly');
        System.assertEquals('Booked', createdAppt.Status__c, 'Appointment status should be Booked');
        
        // Verify Slot update (IsBlocked__c = true)
        Slot__c updatedSlot = [SELECT IsBlocked__c FROM Slot__c WHERE Id = :slot.Id];
        System.assertEquals(true, updatedSlot.IsBlocked__c, 'Slot should be blocked after booking');
    }

    @isTest
    static void testBookAppointmentFailure() {
        // Prepare Invalid Request (Missing IDs)
        AppointmentAgentAction.Request req = new AppointmentAgentAction.Request();
        req.patientId = null; 
        req.slotId = null; // This will cause query exception or similar error
        
        List<AppointmentAgentAction.Request> requestList = new List<AppointmentAgentAction.Request>();
        requestList.add(req);

        Test.startTest();
        List<AppointmentAgentAction.Result> results = AppointmentAgentAction.bookAppointment(requestList);
        Test.stopTest();
        
        // Verify Error Handling
        System.assert(results != null, 'Results should not be null');
        System.assert(results[0].status.startsWith('Error'), 'Status should indicate an error: ' + results[0].status);
    }
}