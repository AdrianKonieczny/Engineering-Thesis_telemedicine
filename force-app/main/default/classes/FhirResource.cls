@RestResource(urlMapping='/fhir/*')
global with sharing class FhirResource {

    @HttpGet
    global static void doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        // Parsowanie URL, np. /services/apexrest/fhir/Patient/a01...
        String uri = req.requestURI;
        String servicePrefix = '/fhir/';
        
        if (!uri.contains(servicePrefix)) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('Invalid URI');
            return;
        }

        String path = uri.substring(uri.indexOf(servicePrefix) + servicePrefix.length());
        List<String> parts = path.split('/');
        
        if (parts.size() < 2) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('Bad Request: Missing Resource Type or ID');
            return;
        }

        String resourceType = parts[0]; // Patient lub Appointment
        String recordId = parts[1];     // ID rekordu

        try {
            if (resourceType == 'Patient') {
                handleGetPatient(recordId, res);
            } else if (resourceType == 'Appointment') {
                handleGetAppointment(recordId, res);
            } else {
                res.statusCode = 404;
                res.responseBody = Blob.valueOf('Resource Type Not Found');
            }
        } catch (ConsentGuard.ConsentException e) {
            // Zgodnie z pracą: Brak zgody = 403 Forbidden
            res.statusCode = 403;
            res.responseBody = Blob.valueOf('{"resourceType": "OperationOutcome", "issue": [{"severity": "error", "code": "forbidden", "diagnostics": "' + e.getMessage() + '"}]}');
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('Internal Server Error: ' + e.getMessage());
        }
    }

    private static void handleGetPatient(String patientId, RestResponse res) {
        // 1. Sprawdzenie Zgody (zgodnie z pracą dyplomową)
        // Zakładamy, że dostęp do danych API wymaga zgody 'Medical Access' lub podobnej
        ConsentGuard.enforceConsent(patientId, 'Document Access');

        // 2. Pobranie danych
        Patient__c pat = [SELECT Id, Name, PESEL__c, Date_of_Birth__c, Gender__c, Email__c 
                          FROM Patient__c 
                          WHERE Id = :patientId 
                          LIMIT 1];

        // 3. Budowanie JSON FHIR (uproszczony profil R4)
        Map<String, Object> fhirJson = new Map<String, Object>();
        fhirJson.put('resourceType', 'Patient');
        fhirJson.put('id', pat.Id);
        fhirJson.put('active', true);
        
        // Name
        Map<String, Object> nameMap = new Map<String, Object>();
        nameMap.put('text', pat.Name);
        nameMap.put('family', pat.Name); // Uproszczenie dla MVP
        fhirJson.put('name', new List<Object>{nameMap});

        // Identifier (PESEL)
        if (pat.PESEL__c != null) {
            Map<String, Object> identifier = new Map<String, Object>();
            identifier.put('system', 'urn:oid:2.16.840.1.113883.3.4424.1.1.616'); // OID dla PESEL
            identifier.put('value', pat.PESEL__c);
            fhirJson.put('identifier', new List<Object>{identifier});
        }

        // Demographics
        if (pat.Date_of_Birth__c != null) {
            fhirJson.put('birthDate', String.valueOf(pat.Date_of_Birth__c));
        }
        if (pat.Gender__c != null) {
            fhirJson.put('gender', pat.Gender__c.toLowerCase());
        }

        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/fhir+json');
        res.responseBody = Blob.valueOf(JSON.serialize(fhirJson));
    }

    private static void handleGetAppointment(String appointmentId, RestResponse res) {
        Appointment__c appt = [SELECT Id, Start__c, End__c, Status__c, Patient__c, Patient__r.Name, Practitioner__r.Name 
                               FROM Appointment__c 
                               WHERE Id = :appointmentId 
                               LIMIT 1];
        
        ConsentGuard.enforceConsent(appt.Patient__c, 'Medical Access');

        Map<String, Object> fhirJson = new Map<String, Object>();
        fhirJson.put('resourceType', 'Appointment');
        fhirJson.put('id', appt.Id);
        fhirJson.put('status', mapStatus(appt.Status__c));
        fhirJson.put('start', appt.Start__c);
        fhirJson.put('end', appt.End__c);
        fhirJson.put('description', 'Telemedicine Consultation');

        // Participants
        List<Object> participants = new List<Object>();
        
        // Patient
        Map<String, Object> p1 = new Map<String, Object>();
        Map<String, Object> actor1 = new Map<String, Object>();
        actor1.put('reference', 'Patient/' + appt.Patient__c);
        actor1.put('display', appt.Patient__r.Name);
        p1.put('actor', actor1);
        p1.put('status', 'accepted');
        participants.add(p1);

        fhirJson.put('participant', participants);

        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/fhir+json');
        res.responseBody = Blob.valueOf(JSON.serialize(fhirJson));
    }

    private static String mapStatus(String sfStatus) {
        if (sfStatus == 'Booked') return 'booked';
        if (sfStatus == 'Cancelled') return 'cancelled';
        if (sfStatus == 'Completed') return 'fulfilled';
        return 'proposed';
    }
}