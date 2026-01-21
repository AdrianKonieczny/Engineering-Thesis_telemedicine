/**
 * @description Unit tests for VideoService.
 * Checks the behavior of the video integration service under error conditions (e.g., HTTP 500).
 * @author AK
 */
@isTest
public class VideoServiceTest {

    /**
     * @description Verifies that the service handles Internal Server Errors (500) from the external provider gracefully.
     */
    @isTest
    static void testCreateMeeting_Negative_500() {
        Test.setMock(HttpCalloutMock.class, new VideoServiceMock(500, 'Internal Server Error', '{"error":"Server Down"}'));
        
        Boolean exceptionCaught = false;
        try {
            VideoService.createMeetingForAppointment('a01000000000000FAKE'); 
        } catch (Exception e) {
            exceptionCaught = true;
        }

        System.assert(exceptionCaught, 'Exception should be caught during failure scenario');
    }
}