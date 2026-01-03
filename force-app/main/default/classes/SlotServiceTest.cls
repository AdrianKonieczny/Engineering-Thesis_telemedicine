@isTest
public class SlotServiceTest {
    
    @isTest
    static void testSlotGeneration() {
        // 1. Przygotowanie danych: Lekarz i Dostępność
        Id docId = UserInfo.getUserId();
        Date today = Date.today();
        
        // Dostępność od 8:00 do 10:00 (powinno dać 4 sloty: 08:00, 08:30, 09:00, 09:30)
        Availability__c av = new Availability__c(
            Practitioner__c = docId,
            Start__c = DateTime.newInstance(today.year(), today.month(), today.day(), 8, 0, 0),
            End__c = DateTime.newInstance(today.year(), today.month(), today.day(), 10, 0, 0),
            Timezone__c = 'Europe/Warsaw'
        );
        insert av;
        
        // 2. Uruchomienie metody (To co robiliśmy w Anonymous Apex)
        Test.startTest();
        SlotService.generateSlotsForPractitioner(docId, today);
        Test.stopTest();
        
        // 3. Weryfikacja
        List<Slot__c> slots = [SELECT Id, Start__c FROM Slot__c];
        
        // Powinny być 4 sloty (2 godziny co 30 min)
        System.assertEquals(4, slots.size(), 'Should generate 4 slots for 2 hours availability');
    }
}