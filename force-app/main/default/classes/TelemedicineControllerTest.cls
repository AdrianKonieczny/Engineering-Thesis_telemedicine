@isTest
public class TelemedicineControllerTest {

    @testSetup
    static void setupData() {
        // 1. Get a Profile
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        String uniqueSeed = String.valueOf(System.currentTimeMillis());

        // 2. Create "Doctor" (User)
        User doctor = new User(
            Alias = 'house',
            Email = 'house@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'House',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Europe/Warsaw',
            UserName = 'house_' + uniqueSeed + '@testorg.com'
        );
        insert doctor;

        // 3. Create "Other Doctor" (User for negative test)
        User otherDoctor = new User(
            Alias = 'wilson',
            Email = 'wilson@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Wilson',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Europe/Warsaw',
            UserName = 'wilson_' + uniqueSeed + '@testorg.com'
        );
        insert otherDoctor;

        // 4. Create Slots
        List<Slot__c> slotsToInsert = new List<Slot__c>();

        // Scenario A: VALID SLOT -> This is the only one we expect to get back
        slotsToInsert.add(new Slot__c(
            Practitioner__c = doctor.Id,
            Start__c = DateTime.now().addHours(2), 
            End__c = DateTime.now().addHours(3),
            IsBlocked__c = false
        ));

        // Scenario B: BLOCKED SLOT
        slotsToInsert.add(new Slot__c(
            Practitioner__c = doctor.Id,
            Start__c = DateTime.now().addHours(4),
            End__c = DateTime.now().addHours(5),
            IsBlocked__c = true 
        ));

        // Scenario C: PAST SLOT
        slotsToInsert.add(new Slot__c(
            Practitioner__c = doctor.Id,
            Start__c = DateTime.now().addHours(-5), 
            End__c = DateTime.now().addHours(-4),
            IsBlocked__c = false
        ));

        // Scenario D: WRONG DOCTOR
        slotsToInsert.add(new Slot__c(
            Practitioner__c = otherDoctor.Id, 
            Start__c = DateTime.now().addHours(2),
            End__c = DateTime.now().addHours(3),
            IsBlocked__c = false
        ));

        insert slotsToInsert;
    }

    @isTest
    static void testGetAvailableSlots() {
        // Fetch the doctor User
        User doctor = [SELECT Id FROM User WHERE LastName = 'House' LIMIT 1];

        Test.startTest();
        // Call the method
        List<Slot__c> resultSlots = TelemedicineController.getAvailableSlots(doctor.Id);
        Test.stopTest();

        // Assertions
        System.assert(resultSlots != null, 'Result should not be null');
        
        // We expect EXACTLY 1 slot (Scenario A only)
        System.assertEquals(1, resultSlots.size(), 'Only 1 valid slot should be returned');
        
        Slot__c returnedSlot = resultSlots[0];
        
        // --- FIX IS HERE ---
        // We cannot check returnedSlot.IsBlocked__c because the Controller does not SELECT it.
        // Instead, we verify that the returned slot ID matches the one valid slot we created.
        
        // Query the expected slot from DB (the one created in Scenario A)
        Slot__c expectedSlot = [
            SELECT Id 
            FROM Slot__c 
            WHERE Practitioner__c = :doctor.Id 
            AND IsBlocked__c = false 
            AND Start__c > :DateTime.now() 
            LIMIT 1
        ];
        
        System.assertEquals(expectedSlot.Id, returnedSlot.Id, 'The returned slot should be the Valid Scenario A slot');
        System.assert(returnedSlot.Start__c > DateTime.now(), 'Returned slot must be in the future');
    }
    
    @isTest
    static void testGetAvailableSlotsNoResults() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        String uniqueSeed = String.valueOf(System.currentTimeMillis());
        
        User newDoc = new User(
            Alias = 'who',
            Email = 'who@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Who',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Europe/Warsaw',
            UserName = 'who_' + uniqueSeed + '@testorg.com'
        );
        insert newDoc;
        
        Test.startTest();
        List<Slot__c> resultSlots = TelemedicineController.getAvailableSlots(newDoc.Id);
        Test.stopTest();
        
        System.assertEquals(0, resultSlots.size(), 'Should return 0 slots for a doctor with no schedule');
    }
}