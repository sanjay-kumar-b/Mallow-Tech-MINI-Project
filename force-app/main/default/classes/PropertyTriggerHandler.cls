public with sharing class PropertyTriggerHandler {

    public static void handleAfterInsert(List<Property__c> newProperties) {
        for (Property__c prop : newProperties) {
            System.enqueueJob(new PropertyGeocodeQueueable(prop.Id));
        }
    }

    public static void handleAfterUpdate(List<Property__c> updatedProperties, Map<Id, Property__c> oldMap) {
        
        for (Property__c prop : updatedProperties) {
            Property__c old = oldMap.get(prop.Id);
            Boolean addressChanged =
                prop.Address__c != old.Address__c ||
                prop.City__c != old.City__c ||
                prop.State__c != old.State__c ||
                prop.Postal_Code__c != old.Postal_Code__c ||
                prop.Country__c != old.Country__c;

            if (addressChanged) {
                System.enqueueJob(new PropertyGeocodeQueueable(prop.Id));
            }
        }
    }
}