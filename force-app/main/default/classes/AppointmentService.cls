public with sharing class AppointmentService {

    // Wyjątek do obsługi błędów biznesowych
    public class AppointmentException extends Exception {}

    public static void bookSlotForPatient(String pesel, String timeString) {
        
        // 1. Znajdź pacjenta
        List<Patient__c> patients = [SELECT Id, Name FROM Patient__c WHERE PESEL__c = :pesel LIMIT 1];
        if (patients.isEmpty()) {
            throw new AppointmentException('Patient with PESEL ' + pesel + ' not found.');
        }
        Patient__c pat = patients[0];

        // 2. Znajdź sloty (Z POPRAWKĄ FOR UPDATE i BEZ ORDER BY)
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
            // Dopasowanie godziny
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

        // 3. Tworzymy wizytę
        Appointment__c appt = new Appointment__c(
            Patient__c = pat.Id,
            Practitioner__c = targetSlot.Practitioner__c,
            Start__c = targetSlot.Start__c,
            End__c = targetSlot.End__c,
            Status__c = 'Booked'
        );
        insert appt;

        // 4. Aktualizujemy slot
        targetSlot.IsBlocked__c = true;
        update targetSlot;
        
        // 5. Generujemy link wideo
        VideoService.createMeetingForAppointment(appt.Id);
    }
}