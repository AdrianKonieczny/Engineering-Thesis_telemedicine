/**
 * @description Unit tests for SecurityUtils class.
 * Verifies that PII (Personally Identifiable Information) like PESEL and Emails 
 * are correctly scrubbed from strings to ensure GDPR compliance.
 * @author AK
 */
@isTest
public class SecurityUtilsTest {
    
    /**
     * @description Verifies that 11-digit numbers (PESEL) are replaced with the hidden placeholder.
     */
    @isTest
    static void testMaskSensitiveData_Pesel() {
        String input = 'Patient PESEL is 90010112345 and needs help.';
        
        Test.startTest();
        String result = SecurityUtils.maskSensitiveData(input);
        Test.stopTest();
        
        System.assert(!result.contains('90010112345'), 'Sensitive PESEL should be removed from the string');
        System.assert(result.contains('[PESEL HIDDEN]'), 'PESEL placeholder should be present');
    }

    /**
     * @description Verifies that email patterns are replaced with the hidden placeholder.
     */
    @isTest
    static void testMaskSensitiveData_Email() {
        String input = 'Contact: jan.kowalski@test.pl immediately.';
        
        Test.startTest();
        String result = SecurityUtils.maskSensitiveData(input);
        Test.stopTest();
        
        System.assert(!result.contains('jan.kowalski@test.pl'), 'Sensitive Email should be removed from the string');
        System.assert(result.contains('[EMAIL HIDDEN]'), 'Email placeholder should be present');
    }

    /**
     * @description Verifies that null or empty inputs are handled gracefully without errors.
     */
    @isTest
    static void testMaskSensitiveData_NullOrEmpty() {
        System.assertEquals(null, SecurityUtils.maskSensitiveData(null), 'Null input should return null');
        System.assertEquals('', SecurityUtils.maskSensitiveData(''), 'Empty string should return empty string');
    }
}