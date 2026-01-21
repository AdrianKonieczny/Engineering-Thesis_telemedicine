/**
 * @description Service class responsible for calculating and generating time slots based on Practitioner availability.
 * Handles the logic of slicing time windows into fixed duration slots while avoiding conflicts with existing appointments.
 * @author AK
 */
public with sharing class SlotService {
    
    private static final Integer SLOT_DURATION_MINUTES = 30;

    /**
     * @description Generates slots for a practitioner on a specific date.
     * Operates on a re-generation basis: existing slots for the target day are deleted 
     * and recreated to reflect the current state of Availability and Appointments.
     * @param practitionerId ID of the medical professional
     * @param dayToProcess The specific date to generate slots for
     */
    public static void generateSlotsForPractitioner(Id practitionerId, Date dayToProcess) {
        List<Availability__c> availabilities = [
            SELECT Id, Start__c, End__c, Timezone__c 
            FROM Availability__c 
            WHERE Practitioner__c = :practitionerId
            AND DAY_ONLY(Start__c) = :dayToProcess
        ];

        List<Appointment__c> existingAppointments = [
            SELECT Start__c, End__c 
            FROM Appointment__c 
            WHERE Practitioner__c = :practitionerId 
            AND DAY_ONLY(Start__c) = :dayToProcess
            AND Status__c != 'Cancelled'
        ];

        List<Slot__c> newSlots = new List<Slot__c>();

        for (Availability__c av : availabilities) {
            DateTime cursor = av.Start__c;
            DateTime endTime = av.End__c;

            while (cursor.addMinutes(SLOT_DURATION_MINUTES) <= endTime) {
                DateTime slotEnd = cursor.addMinutes(SLOT_DURATION_MINUTES);
                
                if (!isColliding(cursor, slotEnd, existingAppointments)) {
                    newSlots.add(new Slot__c(
                        Practitioner__c = practitionerId,
                        Availability__c = av.Id,
                        Start__c = cursor,
                        End__c = slotEnd,
                        IsBlocked__c = false,
                        Timezone__c = av.Timezone__c
                    ));
                }
                cursor = cursor.addMinutes(SLOT_DURATION_MINUTES);
            }
        }

        delete [SELECT Id FROM Slot__c WHERE Practitioner__c = :practitionerId AND DAY_ONLY(Start__c) = :dayToProcess];
        
        if (!newSlots.isEmpty()) {
            insert newSlots;
        }
    }

    /**
     * @description Checks if a proposed time window overlaps with any existing appointment.
     * @param startT Proposed start time
     * @param endT Proposed end time
     * @param appointments List of existing appointments to check against
     * @return True if an overlap exists, False otherwise
     */
    private static Boolean isColliding(DateTime startT, DateTime endT, List<Appointment__c> appointments) {
        for (Appointment__c appt : appointments) {
            if ((startT < appt.End__c) && (endT > appt.Start__c)) {
                return true;
            }
        }
        return false;
    }
}