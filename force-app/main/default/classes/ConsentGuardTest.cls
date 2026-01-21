/**
 * @description Unit tests for ConsentGuard security utility.
 * Verifies that the Protection Proxy correctly blocks or allows access based on active RODO/GDPR consents.
 * @author AK
 */
@isTest
public class ConsentGuardTest {

    @testSetup
    static void setupData() {
        Patient__c pat = new Patient__c(
            Name = 'Test Patient',
            PESEL__c = '44051401359',
            Email__c = 'test@example.com',
            Date_of_Birth__c = Date.newInstance(1944, 5, 14),
            Gender__c = 'Male'
        );
        insert pat; 
    }

    /**
     * @description Negative Scenario: No consent exists for the requested purpose.
     * Expected: System throws ConsentException (Access Denied).
     */
    @isTest
    static void testGuard_AccessDenied() {
        Patient__c pat = [SELECT Id FROM Patient__c LIMIT 1];
        Boolean exceptionThrown = false;

        try {
            ConsentGuard.enforceConsent(pat.Id, 'Document Access');
        } catch (ConsentGuard.ConsentException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('DENIED'), 'Exception message should clearly indicate access denial');
        }

        System.assert(exceptionThrown, 'Security Breach: Method MUST throw exception when NO consent exists');
    }

    /**
     * @description Positive Scenario: Active consent exists.
     * Expected: System allows execution without throwing any exceptions.
     */
    @isTest
    static void testGuard_AccessGranted() {
        Patient__c pat = [SELECT Id FROM Patient__c LIMIT 1];

        Consent__c consent = new Consent__c(
            Patient__c = pat.Id,
            Purpose__c = 'Document Access',
            EffectiveFrom__c = Date.today().addDays(-1),
            EffectiveTo__c = Date.today().addDays(30),
            Version__c = 1.0
        );
        insert consent;
        
        try {
            ConsentGuard.enforceConsent(pat.Id, 'Document Access');
        } catch (Exception e) {
            System.assert(false, 'Should NOT throw exception when consent IS valid. Error: ' + e.getMessage());
        }
    }
}