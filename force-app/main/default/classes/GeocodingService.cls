public with sharing class GeocodingService {

    public class GeocodeResult {
        public Double latitude;
        public Double longitude;
        public Boolean success;
        public String errorMessage;
    }

    public static GeocodeResult geocodeAddress(String address, String city, String state, String postalCode, String country) {

        GeocodeResult result = new GeocodeResult();
        String query = String.join(new List<String>{ address, city, state, postalCode, country }, ', ');

        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://nominatim.openstreetmap.org/search?q=' + EncodingUtil.urlEncode(query, 'UTF-8') + '&format=json&limit=1');
            req.setMethod('GET');
            req.setHeader('User-Agent', 'Salesforce-REPM-DevOrg/1.0');
            req.setTimeout(10000);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                
                List<Object> parsed = (List<Object>) JSON.deserializeUntyped(res.getBody());

                if (!parsed.isEmpty()) {
                    Map<String, Object> first = (Map<String, Object>) parsed[0];
                    result.latitude = Double.valueOf((String) first.get('lat'));
                    result.longitude = Double.valueOf((String) first.get('lon'));
                    result.success = true;
                } else {
                    result.success = false;
                    result.errorMessage = 'No geocoding results found for address.';
                }
            } else {
                result.success = false;
                result.errorMessage = 'Geocoding callout failed with status ' + res.getStatusCode();
            }
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
        }
        return result;
    }
}