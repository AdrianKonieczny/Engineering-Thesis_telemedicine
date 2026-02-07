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
    
    /**
     * @description Verifies generateSlotsFromAvailability creates slots using Availability context.
     */
    @isTest
    static void testGenerateSlotsFromAvailability_createsSlots() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        String uniqueSeed = String.valueOf(System.currentTimeMillis());
        User doctor = new User(
            Alias = 'doc1',
            Email = 'doc1_' + uniqueSeed + '@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'DoctorOne',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Europe/Warsaw',
            UserName = 'doc1_' + uniqueSeed + '@testorg.com'
        );
        insert doctor;

        Date futureDate = Date.today().addDays(7);

        Availability__c avail = new Availability__c(
            Practitioner__c = doctor.Id,
            Start__c = DateTime.newInstance(futureDate, Time.newInstance(9, 0, 0, 0)),
            End__c = DateTime.newInstance(futureDate, Time.newInstance(17, 0, 0, 0)),
            Timezone__c = 'Europe/Warsaw'
        );
        insert avail;

        Integer beforeCount = [
            SELECT COUNT()
            FROM Slot__c
            WHERE Practitioner__c = :doctor.Id
            AND CALENDAR_YEAR(Start__c) = :futureDate.year()
            AND CALENDAR_MONTH(Start__c) = :futureDate.month()
            AND DAY_IN_MONTH(Start__c) = :futureDate.day()
        ];

        Test.startTest();
        TelemedicineController.generateSlotsFromAvailability(avail.Id);
        Test.stopTest();

        List<Slot__c> generated = [
            SELECT Id, Start__c, End__c, Practitioner__c
            FROM Slot__c
            WHERE Practitioner__c = :doctor.Id
            AND CALENDAR_YEAR(Start__c) = :futureDate.year()
            AND CALENDAR_MONTH(Start__c) = :futureDate.month()
            AND DAY_IN_MONTH(Start__c) = :futureDate.day()
            ORDER BY Start__c ASC
        ];

        System.assertEquals(0, beforeCount, 'Precondition failed: there should be no slots before generation');
        System.assert(generated.size() > 0, 'Expected at least one slot to be generated for the availability date');
        for (Slot__c s : generated) {
            System.assertEquals(doctor.Id, s.Practitioner__c, 'Slot should belong to the availability practitioner');
            System.assertEquals(futureDate, s.Start__c.date(), 'Slot Start date should match the availability date');
        }
    }

    /**
     * @description Verifies generateSlotsFromAvailability throws AuraHandledException for an invalid Availability Id.
     */
    @isTest
    static void testGenerateSlotsFromAvailability_invalidId_throws() {
        Id fakeId = (Id) ('a00' + String.valueOf(Crypto.getRandomInteger()).left(12));
        Boolean thrown = false;
        try {
            Test.startTest();
            TelemedicineController.generateSlotsFromAvailability(fakeId);
            Test.stopTest();
        } catch (AuraHandledException e) {
            thrown = true;
            System.assert(e.getMessage().startsWith('Error generating slots:'), 'Should wrap errors in AuraHandledException');
        }
        System.assert(thrown, 'Expected AuraHandledException to be thrown for invalid availability Id');
    }
}
