@isTest
public class ConsentGuardTest {
    
    @isTest
    static void testGuardLogic() {
        // KROK 1: Tworzenie Pacjenta (Dane poprawne, spójne z PESELem)
        Patient__c pat = new Patient__c(
            Name = 'Test Patient',
            PESEL__c = '44051401359',          // Poprawna suma kontrolna
            Email__c = 'test@example.com',
            Date_of_Birth__c = Date.newInstance(1944, 5, 14), // Zgodne z PESEL
            Gender__c = 'Male'                 // Zgodne z PESEL (cyfra przedostatnia nieparzysta)
        );
        insert pat; 
        
        // KROK 2: Test negatywny (Brak zgody)
        Boolean exceptionThrown = false;
        try {
            ConsentGuard.enforceConsent(pat.Id, 'Document Access');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Should throw exception when NO consent exists');
        
        // KROK 3: Tworzenie Zgody
        Consent__c consent = new Consent__c(
            Patient__c = pat.Id,
            Purpose__c = 'Document Access',
            EffectiveFrom__c = Date.today().addDays(-1),
            EffectiveTo__c = Date.today().addDays(30),
            Version__c = 1.0
        );
        insert consent;
        
        // KROK 4: Test pozytywny (Zgoda istnieje)
        try {
            ConsentGuard.enforceConsent(pat.Id, 'Document Access');
            // Jeśli tu dotrze, to znaczy, że sukces - brak błędu
        } catch (Exception e) {
            System.assert(false, 'Should NOT throw exception when consent IS valid. Error: ' + e.getMessage());
        }
    }
}