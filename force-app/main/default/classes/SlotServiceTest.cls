@isTest
public class SlotServiceTest {
    
    @testSetup
    static void setupCommonData() {
        // FIX: Added Date_of_Birth__c because it is a required field
        Patient__c pat = new Patient__c(
            Name = 'Test Patient',
            PESEL__c = '44051401359',
            Email__c = 'test@example.com',
            Gender__c = 'Male',
            Date_of_Birth__c = Date.newInstance(1944, 5, 14) // Added required field
        );
        insert pat;
    }

    @isTest
    static void testSlotGeneration() {
        // 1. Prepare Data: Practitioner and Availability
        Id docId = UserInfo.getUserId();
        Date today = Date.today();
        
        // Availability 08:00 - 10:00 (Should generate 4 slots: 08:00, 08:30, 09:00, 09:30)
        Availability__c av = new Availability__c(
            Practitioner__c = docId,
            Start__c = DateTime.newInstance(today.year(), today.month(), today.day(), 8, 0, 0),
            End__c = DateTime.newInstance(today.year(), today.month(), today.day(), 10, 0, 0),
            Timezone__c = 'Europe/Warsaw'
        );
        insert av;
        
        // 2. Run the method
        Test.startTest();
        SlotService.generateSlotsForPractitioner(docId, today);
        Test.stopTest();
        
        // 3. Verify
        List<Slot__c> slots = [SELECT Id, Start__c FROM Slot__c];
        
        // Should be 4 slots
        System.assertEquals(4, slots.size(), 'Should generate 4 slots for 2 hours availability');
    }

    @isTest
    static void testSlotGenerationWithCollision() {
        // SCENARIO: Availability 8:00-9:00 (2 slots potential),
        // But there is an Appointment 8:00-8:30.
        // System should generate ONLY the 8:30-9:00 slot.

        Id docId = UserInfo.getUserId();
        Date today = Date.today();
        DateTime startDt = DateTime.newInstance(today.year(), today.month(), today.day(), 8, 0, 0); // 08:00
        
        // 1. Availability 08:00 - 09:00
        Availability__c av = new Availability__c(
            Practitioner__c = docId,
            Start__c = startDt,
            End__c = startDt.addHours(1),
            Timezone__c = 'Europe/Warsaw'
        );
        insert av;

        // 2. Existing Appointment 08:00 - 08:30 (Collision with first slot)
        Patient__c pat = [SELECT Id FROM Patient__c LIMIT 1];
        Appointment__c appt = new Appointment__c(
            Patient__c = pat.Id,
            Practitioner__c = docId,
            Start__c = startDt,              // 08:00
            End__c = startDt.addMinutes(30), // 08:30
            Status__c = 'Booked'             // Active status
        );
        insert appt;

        // 3. Run generation
        Test.startTest();
        SlotService.generateSlotsForPractitioner(docId, today);
        Test.stopTest();

        // 4. Verify
        List<Slot__c> slots = [SELECT Id, Start__c FROM Slot__c ORDER BY Start__c ASC];
        
        // Expecting only 1 slot (the second one, starting at 08:30)
        System.assertEquals(1, slots.size(), 'Should generate only 1 slot because the first one is taken');
        
        // Check exact start time
        DateTime expectedSlotStart = startDt.addMinutes(30);
        System.assertEquals(expectedSlotStart, slots[0].Start__c, 'The generated slot should start at 08:30');
    }

    @isTest
    static void testRegenerationClearsOldSlots() {
        // SCENARIO: Verify that re-running generation deletes old slots for that day
        Id docId = UserInfo.getUserId();
        Date today = Date.today();
        
        // Manually create an "old" slot
        Slot__c oldSlot = new Slot__c(
            Practitioner__c = docId,
            Start__c = DateTime.now(),
            End__c = DateTime.now().addMinutes(30),
            IsBlocked__c = false
        );
        insert oldSlot;

        // Create availability that generates completely different slots
        Availability__c av = new Availability__c(
            Practitioner__c = docId,
            Start__c = DateTime.newInstance(today.year(), today.month(), today.day(), 12, 0, 0),
            End__c = DateTime.newInstance(today.year(), today.month(), today.day(), 12, 30, 0),
            Timezone__c = 'Europe/Warsaw'
        );
        insert av;

        Test.startTest();
        SlotService.generateSlotsForPractitioner(docId, today);
        Test.stopTest();

        // Check results
        List<Slot__c> slots = [SELECT Id, Start__c FROM Slot__c];
        System.assertEquals(1, slots.size(), 'Old slots should be deleted, only new one remains');
        System.assertEquals(av.Start__c, slots[0].Start__c);
    }
}