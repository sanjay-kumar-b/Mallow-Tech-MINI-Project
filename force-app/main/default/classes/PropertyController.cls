public with sharing class PropertyController {
    public class PropertyFilter {
        @AuraEnabled public Decimal minPrice;
        @AuraEnabled public Decimal maxPrice;
        @AuraEnabled public String availabilityStatus;
        @AuraEnabled public String furnishingStatus;
        @AuraEnabled public Decimal distanceKm;
        @AuraEnabled public Decimal userLatitude;
        @AuraEnabled public Decimal userLongitude;
    }

    public class PagedResult {
        @AuraEnabled public String locator;
        @AuraEnabled public List<Property__c> records;
        @AuraEnabled public Integer totalRecords;
        @AuraEnabled public Integer pageSize;
        @AuraEnabled public Integer pageNumber;
    }

    public class PropertyImage {
        @AuraEnabled public String base64Data;
        @AuraEnabled public String fileName;
    }

    public class PropertyWrapper {
        @AuraEnabled public String name;
        @AuraEnabled public Decimal latitude;
        @AuraEnabled public Decimal longitude;
    }

    private static final Integer PAGE_SIZE = 25;

    @AuraEnabled
    public static PagedResult getProperties(String filtersJson, Integer pageNumber, String locatorParam) {

        PropertyFilter filters = (PropertyFilter)JSON.deserialize(filtersJson, PropertyFilter.class);

        if (pageNumber == null || pageNumber < 1) {
            pageNumber = 1;
        }

        List<String> conditions = new List<String>();
    	Map<String,Object> binds = new Map<String,Object>();

        System.debug('Filters: ' + filters);

        if (filters != null) {

            if (filters.minPrice != null) {
                conditions.add('Rent__c >= :minPrice');
                binds.put('minPrice', filters.minPrice);
            }

            if (filters.maxPrice != null) {
                conditions.add('Rent__c <= :maxPrice');
                binds.put('maxPrice', filters.maxPrice);
            }

            if (String.isNotBlank(filters.availabilityStatus)) {
                conditions.add('Status__c = :availabilityStatus');
                binds.put('availabilityStatus', filters.availabilityStatus);
            }

            if (String.isNotBlank(filters.furnishingStatus)) {
                conditions.add('Furnishing_Status__c = :furnishingStatus');
                binds.put('furnishingStatus', filters.furnishingStatus);
            }

            if (filters.distanceKm != null && filters.userLatitude != null && filters.userLongitude != null) {
                
                conditions.add('DISTANCE(Location__c, GEOLOCATION(:userLatitude, :userLongitude), \'km\') < :distanceKm');
                
                binds.put('userLatitude', filters.userLatitude);
                binds.put('userLongitude', filters.userLongitude);
                binds.put('distanceKm', filters.distanceKm);
            }
        }

        String whereClause = conditions.isEmpty() ? '' : ' WHERE ' + String.join(conditions, ' AND ');

        String query = 'SELECT Id, Name, Address__c, City__c, State__c, Postal_Code__c, Country__c, Type__c, Furnishing_Status__c, Status__c, Rent__c, Description__c, Location__c FROM Property__c' + whereClause + ' ORDER BY CreatedDate DESC';

        Database.Cursor cursor;

        if (String.isBlank(locatorParam)) {
            cursor = Database.getCursorWithBinds(query, binds, AccessLevel.USER_MODE);
        } else {
            cursor = (Database.Cursor)JSON.deserialize(locatorParam, Database.Cursor.class);
        }

        Integer position = (pageNumber - 1) * PAGE_SIZE;
        Integer remaining = cursor.getNumRecords() - position;
        Integer fetchCount = Math.min(PAGE_SIZE, remaining);
        List<Property__c> properties = fetchCount > 0 ? cursor.fetch(position, fetchCount) : new List<Property__c>();

        PagedResult result = new PagedResult();
        result.locator = JSON.serialize(cursor);
        result.records = properties;
        result.totalRecords = cursor.getNumRecords();
        result.pageSize = PAGE_SIZE;
        result.pageNumber = pageNumber;
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static PropertyWrapper getPropertyLocation(Id propertyId) {
        Property__c property = [SELECT Id, Name, Location__Latitude__s, Location__Longitude__s
                                FROM Property__c
                                WHERE Id = :propertyId
                                LIMIT 1];

        PropertyWrapper wrapper = new PropertyWrapper();
        wrapper.name = property.Name;
        wrapper.latitude = property.Location__Latitude__s;
        wrapper.longitude = property.Location__Longitude__s;

        return wrapper;
    }

    @AuraEnabled
    public static Id createProperty(Property__c property, String imagesJson) {

        List<PropertyImage> images = (List<PropertyImage>)JSON.deserialize(imagesJson, List<PropertyImage>.class);
        
        if (images == null || images.isEmpty()) {
            throw new AuraHandledException('At least one property image is required to create a property.');
        }

        for (PropertyImage img : images) {
            System.debug('fileName=' + img.fileName);
            System.debug('base64 length=' + (img.base64Data == null ? 'null' : String.valueOf(img.base64Data.length())));
        }

        for (PropertyImage img : images) {
            if (String.isBlank(img.base64Data) || String.isBlank(img.fileName)) {
                throw new AuraHandledException('Each image must include file data and a file name.');
            }
        }

        try {
            insert as user property;

            List<ContentVersion> versions = new List<ContentVersion>();

            for (PropertyImage img : images) {
                ContentVersion cv = new ContentVersion();
                cv.Title = img.fileName;
                cv.PathOnClient = img.fileName;
                cv.VersionData = EncodingUtil.base64Decode(img.base64Data);
                cv.FirstPublishLocationId = property.Id; // Linked to the property record
                versions.add(cv);
            }
            insert as user versions;

            property.Has_Image__c = true;
            update as user property;

            return property.Id;
        } catch (DmlException e) {
            throw new AuraHandledException('Unable to create property: ' + e.getDmlMessage(0));
        }
    }
}