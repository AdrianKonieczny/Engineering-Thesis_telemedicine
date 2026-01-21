/**
 * @description Unit tests for TelemedicineController.
 * Verifies LWC data retrieval logic, ensuring strict filtering of blocked, past, or unrelated slots.
 * @author AK
 */
@isTest
public class TelemedicineControllerTest {

    @testSetup
    static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        String uniqueSeed = String.valueOf(System.currentTimeMillis());

        User doctor = new User(
            Alias = 'jkowal',
            Email = 'jan.kowalski@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Kowalski',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Europe/Warsaw',
            UserName = 'kowalski_' + uniqueSeed + '@testorg.com'
        );
        insert doctor;

        User otherDoctor = new User(
            Alias = 'anowak',
            Email = 'anna.nowak@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Nowak',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Europe/Warsaw',
            UserName = 'nowak_' + uniqueSeed + '@testorg.com'
        );
        insert otherDoctor;

        List<Slot__c> slotsToInsert = new List<Slot__c>();

        slotsToInsert.add(new Slot__c(
            Practitioner__c = doctor.Id,
            Start__c = DateTime.now().addHours(2), 
            End__c = DateTime.now().addHours(3),
            IsBlocked__c = false
        ));

        slotsToInsert.add(new Slot__c(
            Practitioner__c = doctor.Id,
            Start__c = DateTime.now().addHours(4),
            End__c = DateTime.now().addHours(5),
            IsBlocked__c = true 
        ));

        slotsToInsert.add(new Slot__c(
            Practitioner__c = doctor.Id,
            Start__c = DateTime.now().addHours(-5), 
            End__c = DateTime.now().addHours(-4),
            IsBlocked__c = false
        ));

        slotsToInsert.add(new Slot__c(
            Practitioner__c = otherDoctor.Id, 
            Start__c = DateTime.now().addHours(2),
            End__c = DateTime.now().addHours(3),
            IsBlocked__c = false
        ));

        insert slotsToInsert;
    }

    /**
     * @description Verifies that only valid slots (future, unblocked, belonging to the requested doctor) are returned.
     */
    @isTest
    static void testGetAvailableSlots() {
        User doctor = [SELECT Id FROM User WHERE LastName = 'Kowalski' LIMIT 1];

        Test.startTest();
        List<Slot__c> resultSlots = TelemedicineController.getAvailableSlots(doctor.Id);
        Test.stopTest();

        System.assert(resultSlots != null);
        System.assertEquals(1, resultSlots.size());
        
        Slot__c returnedSlot = resultSlots[0];
        
        Slot__c expectedSlot = [
            SELECT Id 
            FROM Slot__c 
            WHERE Practitioner__c = :doctor.Id 
            AND IsBlocked__c = false 
            AND Start__c > :DateTime.now() 
            LIMIT 1
        ];
        
        System.assertEquals(expectedSlot.Id, returnedSlot.Id);
        System.assert(returnedSlot.Start__c > DateTime.now());
    }
    
    /**
     * @description Verifies that the controller returns an empty list for a practitioner with no scheduled slots.
     */
    @isTest
    static void testGetAvailableSlotsNoResults() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        String uniqueSeed = String.valueOf(System.currentTimeMillis());
        
        User newDoc = new User(
            Alias = 'mwisn',
            Email = 'marek.wisniewski@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Wisniewski',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Europe/Warsaw',
            UserName = 'wisniewski_' + uniqueSeed + '@testorg.com'
        );
        insert newDoc;
        
        Test.startTest();
        List<Slot__c> resultSlots = TelemedicineController.getAvailableSlots(newDoc.Id);
        Test.stopTest();
        
        System.assertEquals(0, resultSlots.size());
    }
}