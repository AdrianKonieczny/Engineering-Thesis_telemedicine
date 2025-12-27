public with sharing class VideoService {
    
    public static void createMeetingForAppointment(Id appointmentId) {
        // 1. Get Appointment
        Appointment__c appt = [SELECT Id, Patient__c, Start__c FROM Appointment__c WHERE Id = :appointmentId LIMIT 1];
        
        // 2. Mock Logic
        String meetingId = 'ZOOM-SIM-' + String.valueOf(Math.abs(Crypto.getRandomInteger()));
        String joinUrl = 'https://zoom.us/j/' + meetingId + '?pwd=simulation_mode';

        // 3. Update Appointment
        appt.ExternalMeetingId__c = meetingId;
        appt.VideoJoinUrl__c = joinUrl;
        
        update appt;
        
        // 4. Log Action (IN ENGLISH NOW)
        logAction(appt.Id, 'MeetingCreated', 'Simulated video meeting created. ID: ' + meetingId);
    }

    private static void logAction(Id recordId, String action, String details) {
        Log__c log = new Log__c(
            Action__c = action,
            EntityId__c = recordId,
            EntityType__c = 'Appointment__c',
            Payload__c = details,
            When__c = System.now(),
            Actor__c = UserInfo.getUserId()
        );
        insert log;
    }
}