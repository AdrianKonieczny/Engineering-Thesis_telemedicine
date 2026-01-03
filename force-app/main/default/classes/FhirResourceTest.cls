@isTest
public class FhirResourceTest {

    @testSetup
    static void setupData() {
        // 1. Pacjent
        Patient__c pat = new Patient__c(
            Name = 'FHIR Patient',
            PESEL__c = '44051401359',
            Email__c = 'fhir@example.com',
            Date_of_Birth__c = Date.newInstance(1944, 5, 14),
            Gender__c = 'Male'
        );
        insert pat;

        // 2. Zgoda (Wymagana przez ConsentGuard i API)
        Consent__c consent = new Consent__c(
            Patient__c = pat.Id,
            Purpose__c = 'Medical Access',
            EffectiveFrom__c = Date.today().addDays(-1),
            EffectiveTo__c = Date.today().addDays(365),
            Version__c = 1.0
        );
        insert consent;

        // 3. Wizyta
        Appointment__c appt = new Appointment__c(
            Patient__c = pat.Id,
            Start__c = DateTime.now().addHours(24),
            End__c = DateTime.now().addHours(25),
            Status__c = 'Booked'
        );
        insert appt;
    }

    @isTest
    static void testGetPatientValid() {
        Patient__c pat = [SELECT Id FROM Patient__c LIMIT 1];
        
        setRestContext('/services/apexrest/fhir/Patient/' + pat.Id);

        Test.startTest();
        FhirResource.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, 'Should return 200 OK');
        System.assert(RestContext.response.responseBody.toString().contains('resourceType'), 'Should contain resourceType');
    }

    @isTest
    static void testGetAppointmentValid() {
        Appointment__c appt = [SELECT Id FROM Appointment__c LIMIT 1];
        
        setRestContext('/services/apexrest/fhir/Appointment/' + appt.Id);

        Test.startTest();
        FhirResource.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('Appointment'), 'JSON should identify as Appointment');
    }

    @isTest
    static void testGetWithoutConsent_ShouldFail() {
        // Usuwamy zgodę, aby wymusić błąd ConsentException
        delete [SELECT Id FROM Consent__c];
        
        Patient__c pat = [SELECT Id FROM Patient__c LIMIT 1];
        
        setRestContext('/services/apexrest/fhir/Patient/' + pat.Id);

        Test.startTest();
        FhirResource.doGet();
        Test.stopTest();

        // Spodziewamy się 403 Forbidden
        System.assertEquals(403, RestContext.response.statusCode, 'Should be Forbidden without consent');
    }

    @isTest
    static void testInvalidResource() {
        // Testuje branch "else" dla nieznanego typu zasobu
        setRestContext('/services/apexrest/fhir/UnknownResource/123');

        Test.startTest();
        FhirResource.doGet();
        Test.stopTest();

        System.assertEquals(404, RestContext.response.statusCode);
    }

    @isTest
    static void testInternalServerError_RecordNotFound() {
        // Testuje catch(Exception e) -> 500
        // Podajemy poprawne ID formatem, ale takie, którego nie ma w bazie.
        // To spowoduje QueryException w linii [SELECT ...]
        
        // Generujemy fake ID dla Patient__c
        String fakeId = String.valueOf(Patient__c.sobjectType.getDescribe().getKeyPrefix()) + '000000000000FAKE';
        
        setRestContext('/services/apexrest/fhir/Patient/' + fakeId);

        Test.startTest();
        FhirResource.doGet();
        Test.stopTest();

        // Spodziewamy się 500, bo kod nie obsłużył braku rekordu ręcznie, tylko wpadł w catch(Exception)
        System.assertEquals(500, RestContext.response.statusCode, 'Should return 500 on QueryException');
    }

    @isTest
    static void testBadRequest_MissingId() {
        // Testuje warunek: parts.size() < 2
        setRestContext('/services/apexrest/fhir/Patient'); // Brak ID po slashu

        Test.startTest();
        FhirResource.doGet();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode, 'Should return 400 Bad Request when ID is missing');
    }

    @isTest
    static void testInvalidUri_WrongPrefix() {
        // Testuje warunek: !uri.contains(servicePrefix)
        setRestContext('/services/apexrest/otherapi/Patient/123'); 

        Test.startTest();
        FhirResource.doGet();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode, 'Should return 400 for invalid URI prefix');
    }

    // Pomocnicza metoda do ustawiania kontekstu
    private static void setRestContext(String uri) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = uri;
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
    }
}