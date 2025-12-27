public with sharing class ConsentGuard {
    
    public class ConsentException extends Exception {}

    public static void enforceConsent(Id patientId, String purpose) {
        if (!hasActiveConsent(patientId, purpose)) {
            throw new ConsentException('ACCESS DENIED: No active consent found for purpose: ' + purpose);
        }
    }

    public static Boolean hasActiveConsent(Id patientId, String purpose) {
        List<Consent__c> consents = [
            SELECT Id 
            FROM Consent__c 
            WHERE Patient__c = :patientId
            AND Purpose__c = :purpose
            AND Is_Active__c = true
            LIMIT 1
        ];
        return !consents.isEmpty();
    }
}