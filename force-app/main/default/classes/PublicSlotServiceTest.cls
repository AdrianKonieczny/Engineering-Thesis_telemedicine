@isTest
public class PublicSlotServiceTest {
    
    @testSetup
    static void setupData() {
        // Tworzymy slot na "za chwilę"
        Slot__c s = new Slot__c(
            Practitioner__c = UserInfo.getUserId(),
            Start__c = DateTime.now().addMinutes(30), // Przyszłość
            End__c = DateTime.now().addMinutes(60),
            IsBlocked__c = false
        );
        insert s;
    }

    @isTest
    static void testGetSlots() {
        // Przygotowujemy sztuczny request (Agent wymaga listy)
        PublicSlotService.Request req = new PublicSlotService.Request();
        req.dummyInput = 'test';
        List<PublicSlotService.Request> reqs = new List<PublicSlotService.Request>{req};
        
        Test.startTest();
        List<PublicSlotService.SlotOutput> results = PublicSlotService.getTodaySlots(reqs);
        Test.stopTest();
        
        // Weryfikacja
        System.assert(results.size() > 0);
        List<String> times = results[0].timeSlots;
        
        // Sprawdzamy czy lista nie jest pusta i czy zawiera godzinę
        System.assert(!times.isEmpty(), 'Should return at least one time slot');
        System.assert(!times[0].contains('No slots'), 'Should not return "No slots" message when slot exists');
    }
}