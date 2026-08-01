@isTest
public class GeocodeMockSuccess implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('[{"lat":"13.0827","lon":"80.2707"}]');
        return res;
    }
}