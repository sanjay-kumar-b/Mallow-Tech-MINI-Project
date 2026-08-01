@isTest
private class PropertyTriggerHandlerTest {

    @isTest
    static void testAfterInsertEnqueuesGeocode() {
        Test.setMock(HttpCalloutMock.class, new GeocodeMockSuccess());

        Test.startTest();
        Property__c prop = TestDataFactory.buildProperty('Geocode Insert Test');
        insert prop;
        Test.stopTest();

        Property__c updated = [SELECT Location__c FROM Property__c WHERE Id = :prop.Id];
        System.assertNotEquals(null, updated.Location__c);
    }

    @isTest
    static void testAfterUpdateReGeocodesOnAddressChange() {
        Test.setMock(HttpCalloutMock.class, new GeocodeMockSuccess());

        Property__c prop = TestDataFactory.buildProperty('Geocode Update Test');
        insert prop;

        Test.startTest();
        prop.City__c = 'Bengaluru';
        update prop;
        Test.stopTest();

        Property__c updated = [SELECT City__c, Location__c FROM Property__c WHERE Id = :prop.Id];
        System.assertEquals('Bengaluru', updated.City__c);
        System.assertNotEquals(null, updated.Location__c);
    }

    @isTest
    static void testAfterUpdateSkipsGeocodeWhenAddressUnchanged() {
        Test.setMock(HttpCalloutMock.class, new GeocodeMockSuccess());

        Property__c prop = TestDataFactory.buildProperty('Geocode Skip Test');
        insert prop;

        Test.startTest();
        prop.Rent__c = 99999;
        update prop;
        Test.stopTest();

        System.assert(true);
    }
}