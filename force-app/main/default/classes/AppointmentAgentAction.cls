public with sharing class AppointmentAgentAction {

    // Klasa wejściowa (co Agent podaje do metody)
    public class Request {
        @InvocableVariable(label='Patient ID' description='ID of the patient booking the visit' required=true)
        public Id patientId;
        
        @InvocableVariable(label='Slot ID' description='ID of the slot to book' required=true)
        public Id slotId;
    }

    // Klasa wyjściowa (co Agent zwraca użytkownikowi)
    public class Result {
        @InvocableVariable(label='Booking Status' description='Result of the operation')
        public String status;
        
        @InvocableVariable(label='Appointment ID' description='ID of the created appointment')
        public Id appointmentId;
    }

    /**
     * Metoda widoczna dla Agentforce / Flow.
     * Pozwala AI wykonać akcję rezerwacji w systemie.
     */
    @InvocableMethod(label='Book Appointment' description='Books a telemedicine appointment for a given patient and slot')
    public static List<Result> bookAppointment(List<Request> requests) {
        List<Result> results = new List<Result>();
        
        for (Request req : requests) {
            Result res = new Result();
            try {
                // Pobierz dane slotu
                Slot__c slot = [SELECT Practitioner__c, Start__c, End__c FROM Slot__c WHERE Id = :req.slotId LIMIT 1];
                
                // Utwórz wizytę
                Appointment__c appt = new Appointment__c(
                    Patient__c = req.patientId,
                    Practitioner__c = slot.Practitioner__c,
                    Start__c = slot.Start__c,
                    End__c = slot.End__c,
                    Status__c = 'Booked'
                );
                insert appt;
                
                // Oznacz slot jako zajęty (opcjonalnie, jeśli masz pole IsBlocked)
                slot.IsBlocked__c = true;
                update slot;

                // Wywołaj wideo (nasz Mock)
                VideoService.createMeetingForAppointment(appt.Id);

                res.status = 'Success. Appointment booked.';
                res.appointmentId = appt.Id;
                
            } catch (Exception e) {
                res.status = 'Error: ' + e.getMessage();
            }
            results.add(res);
        }
        return results;
    }
}