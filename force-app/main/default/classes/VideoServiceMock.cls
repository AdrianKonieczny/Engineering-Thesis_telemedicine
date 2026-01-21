/**
 * @description Mock implementation of the HttpCalloutMock interface.
 * Allows unit tests to simulate external HTTP responses (success and error scenarios) 
 * without making actual network calls.
 * @author AK
 */
@isTest
public class VideoServiceMock implements HttpCalloutMock {
    
    protected Integer code;
    protected String status;
    protected String body;

    /**
     * @description Default constructor.
     * Sets up a standard 201 Created success response with a dummy JSON payload.
     */
    public VideoServiceMock() {
        this.code = 201;
        this.status = 'Created';
        this.body = '{"id": 123456789, "join_url": "https://daily.co/test_meeting"}';
    }

    /**
     * @description Custom constructor for specific test scenarios.
     * Allows defining custom status codes and bodies to simulate errors (e.g., 500, 401).
     * @param code HTTP Status Code
     * @param status HTTP Status Message
     * @param body JSON Response Body
     */
    public VideoServiceMock(Integer code, String status, String body) {
        this.code = code;
        this.status = status;
        this.body = body;
    }

    /**
     * @description Implementation of the respond method required by HttpCalloutMock.
     * Returns an HttpResponse object configured with the instance variables.
     */
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(this.body);
        res.setStatusCode(this.code);
        res.setStatus(this.status);
        return res;
    }
}