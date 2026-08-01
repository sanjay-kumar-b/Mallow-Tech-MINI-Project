public with sharing class PropertyGeocodeQueueable implements Queueable, Database.AllowsCallouts {

    private Id propertyId;

    public PropertyGeocodeQueueable(Id propertyId) {
        this.propertyId = propertyId;
    }

    public void execute(QueueableContext QC) {
		
        Property__c prop = [SELECT Id, Address__c, City__c, State__c, Postal_Code__c, Country__c FROM Property__c WHERE Id = :propertyId LIMIT 1];

        GeocodingService.GeocodeResult geo = GeocodingService.geocodeAddress(prop.Address__c, prop.City__c, prop.State__c, prop.Postal_Code__c, prop.Country__c);

        if (geo.success) {
            prop.Location__Latitude__s = geo.latitude;
            prop.Location__Longitude__s = geo.longitude;
            update prop;
        } else {
            System.debug(LoggingLevel.WARN, 'Geocode failed for Property ' + propertyId + ': ' + geo.errorMessage);
        }
    }
}