@isTest
public class SecurityUtilsTest {
    
    @isTest
    static void testMasking() {
        // Scenariusz 1: Tekst z PESELem
        String inputPesel = 'Patient PESEL is 90010112345 and needs help.';
        String maskedPesel = SecurityUtils.maskSensitiveData(inputPesel);
        
        // Sprawdzamy, czy PESEL zniknął
        System.assert(!maskedPesel.contains('90010112345'), 'PESEL should be hidden');
        System.assert(maskedPesel.contains('[PESEL HIDDEN]'), 'Placeholder should be present');
        
        // Scenariusz 2: Tekst z E-mailem
        String inputEmail = 'Contact: jan.kowalski@test.pl immediately.';
        String maskedEmail = SecurityUtils.maskSensitiveData(inputEmail);
        
        System.assert(!maskedEmail.contains('jan.kowalski@test.pl'), 'Email should be hidden');
        System.assert(maskedEmail.contains('[EMAIL HIDDEN]'), 'Placeholder should be present');
        
        // Scenariusz 3: Pusty tekst
        System.assertEquals(null, SecurityUtils.maskSensitiveData(null));
    }
}