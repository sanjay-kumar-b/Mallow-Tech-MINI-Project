@isTest
private class GeocodingServiceTest {

    @isTest
    static void testGeocodeAddressSuccess() {
        Test.setMock(HttpCalloutMock.class, new GeocodeMockSuccess());

        Test.startTest();
        GeocodingService.GeocodeResult result = GeocodingService.geocodeAddress(
            '123 Main St', 'Chennai', 'Tamil Nadu', '600001', 'India'
        );
        Test.stopTest();

        System.assertEquals(true, result.success);
        System.assertEquals(13.0827, result.latitude);
        System.assertEquals(80.2707, result.longitude);
    }

    @isTest
    static void testGeocodeAddressNoResults() {
        Test.setMock(HttpCalloutMock.class, new GeocodeMockFailure());

        Test.startTest();
        GeocodingService.GeocodeResult result = GeocodingService.geocodeAddress(
            'Nowhere', 'Nowhere', 'Nowhere', '000000', 'Nowhere'
        );
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertNotEquals(null, result.errorMessage);
    }
}