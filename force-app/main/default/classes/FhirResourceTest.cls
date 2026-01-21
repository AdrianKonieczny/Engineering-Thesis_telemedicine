/**
 * @description Unit tests for FhirResource.
 * Covers GET requests for Patient and Appointment resources, verifying 
 * response status codes (200, 400, 403, 404, 500) and JSON structure.
 * @author AK
 */
@isTest
public class FhirResourceTest {

    @testSetup
    static void setupData() {
        Patient__c pat = new Patient__c(
            Name = 'FHIR Patient',
            PESEL__c = '44051401359',
            Email__c = 'fhir@example.com',
            Date_of_Birth__c = Date.newInstance(1944, 5, 14),
            Gender__c = 'Male'
        );
        insert pat;

        Consent__c consentMed = new Consent__c(
            Patient__c = pat.Id,
            Purpose__c = 'Medical Access',
            EffectiveFrom__c = Date.today().addDays(-1),
            EffectiveTo__c = Date.today().addDays(365),
            Version__c = 1.0
        );
        insert consentMed;
        
        Consent__c consentDoc = new Consent__c(
            Patient__c = pat.Id,
            Purpose__c = 'Document Access',
            EffectiveFrom__c = Date.today().addDays(-1),
            EffectiveTo__c = Date.today().addDays(365),
            Version__c = 1.0
        );
        insert consentDoc;

        Appointment__c appt = new Appointment__c(
            Patient__c = pat.Id,
            Start__c = DateTime.now().addHours(24),
            End__c = DateTime.now().addHours(25),
            Status__c = 'Booked'
        );
        insert appt;
    }

    /**
     * @description Verifies retrieval of a valid Patient resource (HTTP 200).
     */
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

    /**
     * @description Verifies retrieval of a valid Appointment resource (HTTP 200).
     */
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

    /**
     * @description Ensures HTTP 403 Forbidden is returned when Consent is missing.
     */
    @isTest
    static void testGetWithoutConsent_ShouldFail() {
        delete [SELECT Id FROM Consent__c];
        
        Patient__c pat = [SELECT Id FROM Patient__c LIMIT 1];
        
        setRestContext('/services/apexrest/fhir/Patient/' + pat.Id);

        Test.startTest();
        FhirResource.doGet();
        Test.stopTest();

        System.assertEquals(403, RestContext.response.statusCode, 'Should be Forbidden without consent');
    }

    /**
     * @description Test scenario for unknown resource type (HTTP 404).
     */
    @isTest
    static void testInvalidResource() {
        setRestContext('/services/apexrest/fhir/UnknownResource/123');

        Test.startTest();
        FhirResource.doGet();
        Test.stopTest();

        System.assertEquals(404, RestContext.response.statusCode);
    }

    /**
     * @description Simulate Internal Server Error (HTTP 500) using non-existent ID.
     */
    @isTest
    static void testInternalServerError_RecordNotFound() {
        String fakeId = String.valueOf(Patient__c.sobjectType.getDescribe().getKeyPrefix()) + '000000000000FAKE';
        
        setRestContext('/services/apexrest/fhir/Patient/' + fakeId);

        Test.startTest();
        FhirResource.doGet();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode, 'Should return 500 on QueryException');
    }

    /**
     * @description Test missing ID parameter (HTTP 400).
     */
    @isTest
    static void testBadRequest_MissingId() {
        setRestContext('/services/apexrest/fhir/Patient'); // Missing ID after slash

        Test.startTest();
        FhirResource.doGet();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode, 'Should return 400 Bad Request when ID is missing');
    }

    /**
     * @description Test invalid URI prefix (HTTP 400).
     */
    @isTest
    static void testInvalidUri_WrongPrefix() {
        setRestContext('/services/apexrest/otherapi/Patient/123'); 

        Test.startTest();
        FhirResource.doGet();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode, 'Should return 400 for invalid URI prefix');
    }

    private static void setRestContext(String uri) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = uri;
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
    }
}