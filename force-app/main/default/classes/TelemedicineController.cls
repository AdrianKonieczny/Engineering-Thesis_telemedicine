public with sharing class TelemedicineController {
    
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