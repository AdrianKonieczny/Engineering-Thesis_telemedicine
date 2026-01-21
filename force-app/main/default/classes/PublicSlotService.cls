/**
 * @description Service class exposing available time slots to low-code tools like Flow or Agentforce.
 * Allows the bot to retrieve upcoming slots for the current day without complex logic in the flow.
 * @author AK
 */
public with sharing class PublicSlotService {
    
    /**
     * @description Input DTO. Even if empty, it's required structure for Invocable Methods.
     */
    public class Request {
        @InvocableVariable(label='Dummy Input' description='Not used, strictly for Flow invocation context' required=false)
        public String dummyInput;
    }

    /**
     * @description Output DTO containing list of time strings.
     */
    public class SlotOutput {
        @InvocableVariable(label='Available Times' description='Collection of formatted time strings (HH:mm)')
        public List<String> timeSlots;
    }

    /**
     * @description Retrieves the next 5 available slots starting from the current moment.
     * Filters out past slots to ensure the user sees only valid booking options.
     */
    @InvocableMethod(label='Get Available Slots' description='Retrieves upcoming available slots for the rest of the day')
    public static List<SlotOutput> getTodaySlots(List<Request> requests) {
        List<SlotOutput> results = new List<SlotOutput>();
        SlotOutput out = new SlotOutput();
        out.timeSlots = new List<String>();
        
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