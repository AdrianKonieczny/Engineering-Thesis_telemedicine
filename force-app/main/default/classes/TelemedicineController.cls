/**
 * @description Controller for Lightning Web Components (LWC) handling the telemedicine UI logic.
 * Exposes data to the frontend, allowing patients to view available slots.
 * @author AK
 */
public with sharing class TelemedicineController {
    
    /**
     * @description Retrieves a list of future, unblocked time slots for a specific practitioner.
     * Marked as cacheable=true for optimal performance in LWC.
     * @param practitionerId The ID of the doctor
     * @return List of available Slot__c records sorted by time
     */
    @AuraEnabled(cacheable=true)
    public static List<Slot__c> getAvailableSlots(Id practitionerId) {
        return [
            SELECT Id, Start__c, End__c, Practitioner__r.Name 
            FROM Slot__c 
            WHERE Practitioner__c = :practitionerId 
            AND IsBlocked__c = false
            AND Start__c >= :DateTime.now()
            ORDER BY Start__c ASC
        ];
    }
}