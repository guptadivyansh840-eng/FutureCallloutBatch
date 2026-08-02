@isTest
global class PostalApiMockSuccess implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"zip":"110050","city":"Saket","state":"Delhi"}');
        return res;
    }
}