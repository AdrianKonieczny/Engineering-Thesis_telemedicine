/**
 * @description Service class handling external video conferencing integrations.
 * Responsible for provisioning meeting rooms and updating appointment records with join details.
 * @author AK
 */
public with sharing class VideoService {
    
    /**
     * @description Provisions a video meeting room for a specific appointment.
     * Currently implements a simulation/mock logic for demonstration purposes.
     * @param appointmentId The ID of the appointment to attach the meeting to
     */
    public static void createMeetingForAppointment(Id appointmentId) {
        Appointment__c appt = [SELECT Id, Patient__c, Start__c FROM Appointment__c WHERE Id = :appointmentId LIMIT 1];
        
        String meetingId = 'ZOOM-SIM-' + String.valueOf(Math.abs(Crypto.getRandomInteger()));
        String joinUrl = 'https://zoom.us/j/' + meetingId + '?pwd=simulation_mode';

        appt.ExternalMeetingId__c = meetingId;
        appt.VideoJoinUrl__c = joinUrl;
        
        update appt;
        
        logAction(appt.Id, 'MeetingCreated', 'Simulated video meeting created. ID: ' + meetingId);
    }

    /**
     * @description Helper method to persist audit logs securely.
     * Uses SecurityUtils to mask any potential sensitive data in the payload.
     * @param recordId ID of the related record
     * @param action Name of the action being logged
     * @param details Additional context or payload
     */
    private static void logAction(Id recordId, String action, String details) {
        Log__c log = new Log__c(
            Action__c = action,
            EntityId__c = recordId,
            EntityType__c = 'Appointment__c',
            Payload__c = SecurityUtils.maskSensitiveData(details), 
            When__c = System.now(),
            Actor__c = UserInfo.getUserId()
        );
        insert log;
    }
}