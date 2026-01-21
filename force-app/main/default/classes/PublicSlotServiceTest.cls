/**
 * @description Unit tests for PublicSlotService.
 * Verifies that the service correctly returns available time slots for the current day.
 * @author AK
 */
@isTest
public class PublicSlotServiceTest {
    
    @testSetup
    static void setupData() {
        Slot__c s = new Slot__c(
            Practitioner__c = UserInfo.getUserId(),
            Start__c = DateTime.now().addMinutes(30),
            End__c = DateTime.now().addMinutes(60),
            IsBlocked__c = false
        );
        insert s;
    }

    /**
     * @description Tests the positive scenario where valid future slots exist and are returned.
     */
    @isTest
    static void testGetSlots() {
        PublicSlotService.Request req = new PublicSlotService.Request();
        req.dummyInput = 'test';
        List<PublicSlotService.Request> reqs = new List<PublicSlotService.Request>{req};
        
        Test.startTest();
        List<PublicSlotService.SlotOutput> results = PublicSlotService.getTodaySlots(reqs);
        Test.stopTest();
        
        System.assert(results.size() > 0);
        List<String> times = results[0].timeSlots;
        
        System.assert(!times.isEmpty(), 'Should return at least one time slot');
        System.assert(!times[0].contains('No slots'), 'Should not return "No slots" message when slot exists');
    }
}