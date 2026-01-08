public with sharing class BookByPeselAction {

    public class Request {
        @InvocableVariable(label='PESEL' required=true)
        public String pesel;
        @InvocableVariable(label='Selected Time' required=true)
        public String timeString;
    }

    public class Result {
        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(label='Book by PESEL')
    public static List<Result> bookSlot(List<Request> requests) {
        List<Result> results = new List<Result>();
        Request req = requests[0];
        Result res = new Result();

        try {
            // WYWOŁANIE NOWEJ KLASY SERWISOWEJ
            AppointmentService.bookSlotForPatient(req.pesel, req.timeString);
            
            res.message = 'Success! Appointment booked for PESEL ' + req.pesel + ' at ' + req.timeString;

        } catch (Exception e) {
            res.message = 'Error: ' + e.getMessage();
            
            // Logowanie błędu (zostawiamy, bo to warstwa styku z użytkownikiem)
            String riskyPayload = 'Failed booking for PESEL: ' + req.pesel + '. Error: ' + e.getMessage();
            Log__c errorLog = new Log__c(
                Action__c = 'BookSlotError',
                Actor__c = UserInfo.getUserId(),
                When__c = DateTime.now(),
                EntityType__c = 'Patient__c',
                Payload__c = SecurityUtils.maskSensitiveData(riskyPayload) 
            );
            insert errorLog;
        }

        results.add(res);
        return results;
    }
}