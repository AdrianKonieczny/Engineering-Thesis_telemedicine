@isTest
public class VideoServiceMock implements HttpCalloutMock {
    // Ta metoda udaje odpowiedź serwera Zoom
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        
        // Symulujemy sukces (201 Created)
        res.setBody('{"id": 123456789, "join_url": "https://zoom.us/j/123456789"}');
        res.setStatusCode(201);
        return res;
    }
}