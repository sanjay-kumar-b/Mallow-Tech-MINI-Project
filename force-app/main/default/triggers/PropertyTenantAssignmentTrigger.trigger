trigger PropertyTenantAssignmentTrigger on Property_Tenant_Assignment__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        PropertyTenantAssignmentTriggerHandler.handleAfterInsert(Trigger.new);
    }
}