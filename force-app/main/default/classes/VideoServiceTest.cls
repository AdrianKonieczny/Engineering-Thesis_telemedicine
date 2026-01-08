@isTest
public class VideoServiceTest {

    @isTest
    static void testCreateMeeting_Negative_500() {
        Test.setMock(HttpCalloutMock.class, new VideoServiceMock(500, 'Internal Server Error', '{"error":"Server Down"}'));
        
        // 2. Próbujemy wywołać serwis
        Boolean exceptionCaught = false;
        try {
            VideoService.createMeetingForAppointment('a01000000000000FAKE'); 
        } catch (Exception e) {
            exceptionCaught = true;
            System.debug('Złapano oczekiwany błąd: ' + e.getMessage());
        }
    }
}