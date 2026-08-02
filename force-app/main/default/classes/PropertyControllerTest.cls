@isTest
private class PropertyControllerTest {

    @TestSetup
    static void setup() {
        List<Property__c> props = new List<Property__c>();
        for (Integer i = 0; i < 30; i++) {
            Property__c p = TestDataFactory.buildProperty('Property ' + i);
            p.Rent__c = 10000 + (i * 1000);
            p.Status__c = Math.mod(i, 2) == 0 ? 'Available' : 'Occupied';
            p.Furnishing_Status__c = Math.mod(i, 3) == 0 ? 'Furnished' : 'Unfurnished';
            props.add(p);
        }
        insert props;
    }

    @isTest
    static void testGetPropertiesPagination() {
        Test.startTest();
        PropertyController.PagedResult page1 = PropertyController.getProperties('{}', 1, null);
        PropertyController.PagedResult page2 = PropertyController.getProperties('{}', 2, page1.locator);
        Test.stopTest();

        System.assertNotEquals(null, page1.locator);
        System.assertEquals(30, page1.totalRecords);
        System.assertEquals(25, page1.records.size());
        System.assertEquals(30, page2.totalRecords);
        System.assertEquals(5, page2.records.size());
    }

    @isTest
    static void testGetPropertiesWithFilters() {
        PropertyController.PropertyFilter filter = new PropertyController.PropertyFilter();
        filter.minPrice = 15000;
        filter.maxPrice = 20000;
        filter.availabilityStatus = 'Available';
        filter.furnishingStatus = 'Furnished';

        String filtersJson = JSON.serialize(filter);

        Test.startTest();
        PropertyController.PagedResult result = PropertyController.getProperties(filtersJson, 1, null);
        Test.stopTest();

        for (Property__c p : result.records) {
            System.assert(p.Rent__c >= 15000 && p.Rent__c <= 20000);
            System.assertEquals('Available', p.Status__c);
            System.assertEquals('Furnished', p.Furnishing_Status__c);
        }
    }

    @isTest
    static void testGetPropertiesEmptyPageBeyondLastRecord() {
        Test.startTest();
        PropertyController.PagedResult page1 = PropertyController.getProperties('{}', 1, null);
        PropertyController.PagedResult pageBeyond = PropertyController.getProperties('{}', 10, page1.locator);
        Test.stopTest();

        System.assertEquals(0, pageBeyond.records.size());
    }

    @isTest
    static void testCreatePropertyWithImagesSucceeds() {
        Property__c newProp = TestDataFactory.buildProperty('New Property With Images');
        PropertyController.PropertyImage img1 = new PropertyController.PropertyImage();
        img1.base64Data = EncodingUtil.base64Encode(Blob.valueOf('fake-image-bytes-1'));
        img1.fileName = 'photo1.png';
        PropertyController.PropertyImage img2 = new PropertyController.PropertyImage();
        img2.base64Data = EncodingUtil.base64Encode(Blob.valueOf('fake-image-bytes-2'));
        img2.fileName = 'photo2.png';

        Test.setMock(HttpCalloutMock.class, new GeocodeMockSuccess());

        List<PropertyController.PropertyImage> images = new List<PropertyController.PropertyImage>{ img1, img2 };

        String imagesJson = JSON.serialize(images);

        Test.startTest();
        Id newId = PropertyController.createProperty(newProp, imagesJson);
        Test.stopTest();

        Property__c inserted = [SELECT Id, Has_Image__c FROM Property__c WHERE Id = :newId];
        System.assertEquals(true, inserted.Has_Image__c);

        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :newId];
        System.assertEquals(2, links.size());
    }

    @isTest
    static void testCreatePropertyWithoutImagesThrows() {
        Property__c newProp = TestDataFactory.buildProperty('No Image Property');
        Boolean threw = false;

        Test.startTest();
        String imagesJson = JSON.serialize(new List<PropertyController.PropertyImage>());
        try {
            PropertyController.createProperty(newProp, imagesJson);
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw);
    }

    @isTest
    static void testGetPropertyLocation() {
        Property__c p = [SELECT Id, Name, Location__Latitude__s, Location__Longitude__s
                        FROM Property__c
                        LIMIT 1];

        Test.startTest();
        PropertyController.PropertyWrapper wrapper = PropertyController.getPropertyLocation(p.Id);
        Test.stopTest();

        System.assertEquals(p.Name, wrapper.name);
        System.assertEquals(p.Location__Latitude__s, wrapper.latitude);
        System.assertEquals(p.Location__Longitude__s, wrapper.longitude);
    }
}