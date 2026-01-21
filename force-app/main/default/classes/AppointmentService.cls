/**
 * @description Service class handling business logic for appointment bookings.
 * @author AK
 */
public with sharing class AppointmentService {

    public class AppointmentException extends Exception {}

    /**
     * @description Books an appointment for a patient identified by PESEL.
     * Uses row locking (FOR UPDATE) to ensure data integrity during concurrent requests.
     * @param pesel Patient's PESEL number
     * @param timeString Requested time in 'HH:mm' format
     */
    public static void bookSlotForPatient(String pesel, String timeString) {
        
        List<Patient__c> patients = [SELECT Id, Name FROM Patient__c WHERE PESEL__c = :pesel LIMIT 1];
        if (patients.isEmpty()) {
            throw new AppointmentException('Patient with PESEL ' + pesel + ' not found.');
        }
        Patient__c pat = patients[0];

        // Query open slots using FOR UPDATE to lock records and prevent race conditions (double booking)
        List<Slot__c> slots = [
            SELECT Id, Start__c, End__c, Practitioner__c 
            FROM Slot__c 
            WHERE IsBlocked__c = false 
            AND Start__c >= :Date.today() 
            AND Start__c < :Date.today().addDays(1)
            FOR UPDATE 
        ];

        Slot__c targetSlot = null;
        for(Slot__c s : slots) {
            if(s.Start__c.format('HH:mm') == timeString || s.Start__c.format('H:mm') == timeString) {
                targetSlot = s;
                break;
            }
        }

        if (targetSlot == null) {
            throw new AppointmentException('Could not find a free slot at ' + timeString);
        }
        
        if (targetSlot.Start__c < DateTime.now()) {
            throw new AppointmentException('Cannot book a time in the past (' + timeString + ').');
        }

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
    }
}