public with sharing class PropertyTenantAssignmentTriggerHandler {

    public static void handleAfterInsert(List<Property_Tenant_Assignment__c> newAssignments) {
	
        List<Task> tasksToInsert = new List<Task>();

        for (Property_Tenant_Assignment__c assignment : newAssignments) {
            Task t = new Task();
            t.Subject = 'Generate Lease Agreement';
            t.WhatId = assignment.Property__c;
            t.Description = 'Property has been assigned to a tenant (Assignment: ' + assignment.Id + '). Please generate and finalize the lease agreement.';
            t.ActivityDate = Date.today().addDays(2);
            t.Status = 'Not Started';
            t.Priority = 'Normal';
            tasksToInsert.add(t);
        }

        if (!tasksToInsert.isEmpty()) {
            insert as user tasksToInsert;
        }
    }
}