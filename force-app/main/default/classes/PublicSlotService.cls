public with sharing class PublicSlotService {
    
    public class Request {
        @InvocableVariable(label='Dummy Input' required=false)
        public String dummyInput;
    }

    public class SlotOutput {
        @InvocableVariable(label='Available Times')
        public List<String> timeSlots;
    }

    @InvocableMethod(label='Get Available Slots')
    public static List<SlotOutput> getTodaySlots(List<Request> requests) {
        List<SlotOutput> results = new List<SlotOutput>();
        SlotOutput out = new SlotOutput();
        out.timeSlots = new List<String>();
        
        // --- ZMIANA: Start__c >= DateTime.now() (Teraz), a nie Date.today() (Początek dnia) ---
        List<Slot__c> slots = [
            SELECT Start__c 
            FROM Slot__c 
            WHERE Start__c >= :DateTime.now() 
            AND Start__c < :DateTime.now().addDays(1)
            AND IsBlocked__c = false
            ORDER BY Start__c ASC
            LIMIT 5
        ];

        for (Slot__c s : slots) {
            out.timeSlots.add(s.Start__c.format('HH:mm'));
        }
        
        if (out.timeSlots.isEmpty()) {
            out.timeSlots.add('No slots available for the rest of the day.');
        }

        results.add(out);
        return results;
    }
}