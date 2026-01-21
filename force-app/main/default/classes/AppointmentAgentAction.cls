/**
 * @description Handles appointment booking logic for Agentforce integration.
 * @author AK
 */
public with sharing class AppointmentAgentAction {

    public class Request {
        @InvocableVariable(label='Patient ID' required=true)
        public Id patientId;
        
        @InvocableVariable(label='Slot ID' required=true)
        public Id slotId;
    }

    public class Result {
        @InvocableVariable(label='Booking Status')
        public String status;
        
        @InvocableVariable(label='Appointment ID')
        public Id appointmentId;
    }

    /**
     * @description Transactional method to book a slot and create an appointment.
     */
    @InvocableMethod(label='Book Appointment' description='Books a telemedicine appointment for a given patient and slot')
    public static List<Result> bookAppointment(List<Request> requests) {
        List<Result> results = new List<Result>();
        
        for (Request req : requests) {
            Result res = new Result();
            try {
                Slot__c slot = [SELECT Practitioner__c, Start__c, End__c FROM Slot__c WHERE Id = :req.slotId LIMIT 1];      
                
                Appointment__c appt = new Appointment__c(
                    Patient__c = req.patientId,
                    Practitioner__c = slot.Practitioner__c,
                    Start__c = slot.Start__c,
                    End__c = slot.End__c,
                    Status__c = 'Booked'
                );
                insert appt;
                
                slot.IsBlocked__c = true;
                update slot;
          
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