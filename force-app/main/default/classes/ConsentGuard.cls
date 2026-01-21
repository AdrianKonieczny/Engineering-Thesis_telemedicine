/**
 * @description Security utility class acting as a Protection Proxy.
 * Enforces RODO/GDPR compliance by verifying active consents before allowing data access.
 * @author AK
 */
public with sharing class ConsentGuard {
    
    public class ConsentException extends Exception {}

    /**
     * @description Throws an exception if the required consent is missing or inactive.
     * Used to block execution flow in critical operations (e.g., viewing medical records).
     * @param patientId The ID of the patient record
     * @param purpose The specific processing purpose
     * @throws ConsentException if access is denied
     */
    public static void enforceConsent(Id patientId, String purpose) {
        if (!hasActiveConsent(patientId, purpose)) {
            throw new ConsentException('ACCESS DENIED: No active consent found for purpose: ' + purpose);
        }
    }

    /**
     * @description Checks database for an active consent record matching the criteria.
     * @return Boolean True if active consent exists, False otherwise
     */
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