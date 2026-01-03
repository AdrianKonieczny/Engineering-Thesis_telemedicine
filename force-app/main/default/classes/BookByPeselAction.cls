public with sharing class BookByPeselAction {

    public class Request {
        @InvocableVariable(label='PESEL' description='Patient PESEL number' required=true)
        public String pesel;
        
        @InvocableVariable(label='Selected Time' description='Time selected by user (e.g. 10:00)' required=true)
        public String timeString;
    }

    public class Result {
        @InvocableVariable(label='Message' description='Result message')
        public String message;
    }

    @InvocableMethod(label='Book by PESEL' description='Books appointment using PESEL and Time string')
    public static List<Result> bookSlot(List<Request> requests) {
        List<Result> results = new List<Result>();
        Request req = requests[0];
        Result res = new Result();

        try {
            // 1. Znajdź pacjenta
            Patient__c pat = [SELECT Id, Name FROM Patient__c WHERE PESEL__c = :req.pesel LIMIT 1];
            
            // 2. Znajdź sloty na dzisiaj
            List<Slot__c> slots = [
                SELECT Id, Start__c, End__c, Practitioner__c 
                FROM Slot__c 
                WHERE IsBlocked__c = false 
                AND Start__c >= :Date.today() 
                AND Start__c < :Date.today().addDays(1)
                ORDER BY Start__c ASC
            ];

            Slot__c targetSlot = null;
            for(Slot__c s : slots) {
                // Dopasowanie godziny (np. 12:00)
                if(s.Start__c.format('HH:mm') == req.timeString || s.Start__c.format('H:mm') == req.timeString) {
                    targetSlot = s;
                    break;
                }
            }

            if (targetSlot == null) {
                res.message = 'Error: Could not find a free slot at ' + req.timeString;
            } 
            // Walidacja czasu wstecz
            else if (targetSlot.Start__c < DateTime.now()) {
                res.message = 'Error: Cannot book a time in the past (' + req.timeString + '). Please choose a future time.';
            } 
            else {
                // 3. Tworzymy wizytę
                Appointment__c appt = new Appointment__c(
                    Patient__c = pat.Id,
                    Practitioner__c = targetSlot.Practitioner__c,
                    Start__c = targetSlot.Start__c,
                    End__c = targetSlot.End__c,
                    Status__c = 'Booked'
                );
                insert appt;

                targetSlot.IsBlocked__c = true;
                update targetSlot;
                
                VideoService.createMeetingForAppointment(appt.Id);

                res.message = 'Success! Appointment booked for ' + pat.Name + ' at ' + req.timeString;
            }

        } catch (Exception e) {
            // Obsługa błędu
            res.message = 'Error: ' + e.getMessage();
            
            // --- START: LOGOWANIE Z MASKOWANIEM DANYCH ---
            // Tworzymy tekst, który normalnie zawierałby PESEL (dane wrażliwe)
            String riskyPayload = 'Failed booking for PESEL: ' + req.pesel + '. Error: ' + e.getMessage();
            
            Log__c errorLog = new Log__c(
                Action__c = 'BookSlotError',
                Actor__c = UserInfo.getUserId(),
                When__c = DateTime.now(),
                EntityType__c = 'Patient__c',
                // TUTAJ UŻYWAMY TWOJEJ METODY DO MASKOWANIA:
                Payload__c = SecurityUtils.maskSensitiveData(riskyPayload) 
            );
            insert errorLog;
            // --- KONIEC LOGOWANIA ---
        }

        results.add(res);
        return results;
    }
}