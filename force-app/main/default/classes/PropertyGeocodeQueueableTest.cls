@isTest
private class PropertyGeocodeQueueableTest {

    @isTest
    static void testGeocodeUpdatesLocation() {
        Property__c prop = TestDataFactory.buildProperty('Test Property');
        insert prop;

        Test.setMock(HttpCalloutMock.class, new GeocodeMockSuccess());

        Test.startTest();
        System.enqueueJob(new PropertyGeocodeQueueable(prop.Id));
        Test.stopTest();

        Property__c updated = [SELECT Id, Location__c FROM Property__c WHERE Id = :prop.Id];
        System.assertNotEquals(null, updated.Location__c);
    }
}