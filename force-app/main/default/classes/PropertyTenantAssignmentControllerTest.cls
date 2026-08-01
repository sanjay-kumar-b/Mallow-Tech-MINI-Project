@isTest
private class PropertyTenantAssignmentControllerTest {

    @isTest
    static void testAssignPropertyToTenantCreatesTaskViaTrigger() {
        Property__c prop = TestDataFactory.buildProperty('Assignable Property');
        insert prop;
        Tenant__c tenant = TestDataFactory.buildTenant('Assignable Tenant');
        insert tenant;

        Test.startTest();
        Id assignmentId = PropertyTenantAssignmentController.assignPropertyToTenant(prop.Id, tenant.Id, Date.today());
        Test.stopTest();

        System.assertNotEquals(null, assignmentId);

        Property_Tenant_Assignment__c assignment = [SELECT Id, Property__c, Tenant__c, Assigned_Date__c FROM Property_Tenant_Assignment__c WHERE Id = :assignmentId];
        System.assertEquals(prop.Id, assignment.Property__c);
        System.assertEquals(tenant.Id, assignment.Tenant__c);
        System.assertEquals(Date.today(), assignment.Assigned_Date__c);

        List<Task> tasks = [SELECT Id, Subject FROM Task WHERE WhatId = :prop.Id];
        System.assertEquals(1, tasks.size());
        System.assertEquals('Generate Lease Agreement', tasks[0].Subject);
    }

    @isTest
    static void testAssignPropertyToTenantDefaultsAssignedDate() {
        Property__c prop = TestDataFactory.buildProperty('Default Date Property');
        insert prop;
        Tenant__c tenant = TestDataFactory.buildTenant('Default Date Tenant');
        insert tenant;

        Test.startTest();
        Id assignmentId = PropertyTenantAssignmentController.assignPropertyToTenant(prop.Id, tenant.Id, null);
        Test.stopTest();

        Property_Tenant_Assignment__c assignment = [SELECT Assigned_Date__c FROM Property_Tenant_Assignment__c WHERE Id = :assignmentId];
        System.assertEquals(Date.today(), assignment.Assigned_Date__c);
    }

    @isTest
    static void testAssignPropertyToTenantMissingIdsThrows() {
        Boolean threw = false;
        Test.startTest();
        try {
            PropertyTenantAssignmentController.assignPropertyToTenant(null, null, Date.today());
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw);
    }
}