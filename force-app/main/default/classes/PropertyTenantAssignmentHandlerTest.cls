@isTest
private class PropertyTenantAssignmentHandlerTest {

    @isTest
    static void testTaskCreatedOnAssignment() {
        Property__c prop = TestDataFactory.buildProperty('Assigned Property');
        insert prop;
        Tenant__c tenant = TestDataFactory.buildTenant('John Doe');
        insert tenant;

        Test.startTest();
        Property_Tenant_Assignment__c assignment = new Property_Tenant_Assignment__c(
            Property__c = prop.Id,
            Tenant__c = tenant.Id,
            Assigned_Date__c = Date.today()
        );
        insert assignment;
        Test.stopTest();

        List<Task> tasks = [SELECT Id, Subject, WhatId FROM Task WHERE WhatId = :prop.Id];
        System.assertEquals(1, tasks.size());
        System.assertEquals('Generate Lease Agreement', tasks[0].Subject);
    }
}