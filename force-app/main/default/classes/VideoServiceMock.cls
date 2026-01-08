@isTest
public class VideoServiceMock implements HttpCalloutMock {
    protected Integer code;
    protected String status;
    protected String body;

    // Konstruktor domyślny - symuluje sukces (dla starych testów)
    public VideoServiceMock() {
        this.code = 201;
        this.status = 'Created';
        this.body = '{"id": 123456789, "join_url": "https://daily.co/test_meeting"}';
    }

    // NOWY Konstruktor - pozwala symulować błędy (np. 500, 401)
    public VideoServiceMock(Integer code, String status, String body) {
        this.code = code;
        this.status = status;
        this.body = body;
    }

    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(this.body);
        res.setStatusCode(this.code);
        res.setStatus(this.status);
        return res;
    }
}