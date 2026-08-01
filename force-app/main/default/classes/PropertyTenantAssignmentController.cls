public with sharing class PropertyTenantAssignmentController {

    @AuraEnabled
    public static Id assignPropertyToTenant(Id propertyId, Id tenantId, Date assignedDate) {

        if (propertyId == null || tenantId == null) {
            throw new AuraHandledException('Both a property and a tenant are required.');
        }

        try {
            Property_Tenant_Assignment__c assignment = new Property_Tenant_Assignment__c(
                Property__c = propertyId,
                Tenant__c = tenantId,
                Assigned_Date__c = assignedDate != null ? assignedDate : Date.today()
            );
            insert as user assignment;
            return assignment.Id;
        } catch (DmlException e) {
            throw new AuraHandledException('Unable to assign property to tenant: ' + e.getDmlMessage(0));
        }
    }
}