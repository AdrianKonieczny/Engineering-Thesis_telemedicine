/**
 * @description Unit tests for SlotService.
 * Validates slot generation logic, including collision detection with existing appointments
 * and the mechanism for refreshing/regenerating daily slots.
 * @author AK
 */
@isTest
public class SlotServiceTest {
    
    @testSetup
    static void setupCommonData() {
        Patient__c pat = new Patient__c(
            Name = 'Test Patient',
            PESEL__c = '44051401359',
            Email__c = 'test@example.com',
            Gender__c = 'Male',
            Date_of_Birth__c = Date.newInstance(1944, 5, 14)
        );
        insert pat;
    }

    /**
     * @description Happy Path: Verifies that slots are correctly generated for a given availability window.
     * Expects 4 slots for a 2-hour window (30-min duration).
     */
    @isTest
    static void testSlotGeneration() {
        Id docId = UserInfo.getUserId();
        Date today = Date.today();
        
        // Availability 08:00 - 10:00
        Availability__c av = new Availability__c(
            Practitioner__c = docId,
            Start__c = DateTime.newInstance(today.year(), today.month(), today.day(), 8, 0, 0),
            End__c = DateTime.newInstance(today.year(), today.month(), today.day(), 10, 0, 0),
            Timezone__c = 'Europe/Warsaw'
        );
        insert av;
        
        Test.startTest();
        SlotService.generateSlotsForPractitioner(docId, today);
        Test.stopTest();
        
        List<Slot__c> slots = [SELECT Id, Start__c FROM Slot__c];
        
        System.assertEquals(4, slots.size(), 'Should generate 4 slots for 2 hours availability');
    }

    /**
     * @description Collision Test: Ensures that if an appointment already exists, 
     * the overlapping slot is NOT generated.
     */
    @isTest
    static void testSlotGenerationWithCollision() {
        Id docId = UserInfo.getUserId();
        Date today = Date.today();
        DateTime startDt = DateTime.newInstance(today.year(), today.month(), today.day(), 8, 0, 0); // 08:00
        
        // Availability 08:00 - 09:00 (Potential: 2 slots)
        Availability__c av = new Availability__c(
            Practitioner__c = docId,
            Start__c = startDt,
            End__c = startDt.addHours(1),
            Timezone__c = 'Europe/Warsaw'
        );
        insert av;

        // Existing Appointment 08:00 - 08:30 (Occupies the first slot)
        Patient__c pat = [SELECT Id FROM Patient__c LIMIT 1];
        Appointment__c appt = new Appointment__c(
            Patient__c = pat.Id,
            Practitioner__c = docId,
            Start__c = startDt,              
            End__c = startDt.addMinutes(30), 
            Status__c = 'Booked'             
        );
        insert appt;

        Test.startTest();
        SlotService.generateSlotsForPractitioner(docId, today);
        Test.stopTest();

        // Verify: Should generate only the second slot (08:30 - 09:00)
        List<Slot__c> slots = [SELECT Id, Start__c FROM Slot__c ORDER BY Start__c ASC];
        
        System.assertEquals(1, slots.size(), 'Should generate only 1 slot because the first one is taken');
        
        DateTime expectedSlotStart = startDt.addMinutes(30);
        System.assertEquals(expectedSlotStart, slots[0].Start__c, 'The generated slot should start at 08:30');
    }

    /**
     * @description Re-generation Logic: Verifies that running the service again clears old slots
     * and replaces them with fresh ones, preventing duplication.
     */
    @isTest
    static void testRegenerationClearsOldSlots() {
        Id docId = UserInfo.getUserId();
        Date today = Date.today();
        
        // Manually create an stale/old slot
        Slot__c oldSlot = new Slot__c(
            Practitioner__c = docId,
            Start__c = DateTime.now(),
            End__c = DateTime.now().addMinutes(30),
            IsBlocked__c = false
        );
        insert oldSlot;

        // Create new availability for a different time (12:00 - 12:30)
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

        List<Slot__c> slots = [SELECT Id, Start__c FROM Slot__c];
        System.assertEquals(1, slots.size(), 'Old slots should be deleted, only new one remains');
        System.assertEquals(av.Start__c, slots[0].Start__c);
    }
}