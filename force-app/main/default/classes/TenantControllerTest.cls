@isTest
private class TenantControllerTest {

    @TestSetup
    static void setup() {
        List<Tenant__c> tenants = new List<Tenant__c>();
        for (Integer i = 0; i < 30; i++) {
            tenants.add(TestDataFactory.buildTenant('Tenant ' + i));
        }
        insert tenants;
    }

    @isTest
    static void testGetTenantsPagination() {
        Test.startTest();
        TenantController.PagedResult page1 = TenantController.getTenants(1, null);
        TenantController.PagedResult page2 = TenantController.getTenants(2, page1.locator);
        Test.stopTest();

        System.assertNotEquals(null, page1.locator);
        System.assertEquals(30, page1.totalRecords);
        System.assertEquals(25, page1.records.size());
        System.assertEquals(30, page2.totalRecords);
        System.assertEquals(5, page2.records.size());
    }

    @isTest
    static void testGetTenantsEmptyPageBeyondLastRecord() {
        Test.startTest();
        TenantController.PagedResult page1 = TenantController.getTenants(1, null);
        TenantController.PagedResult pageBeyond = TenantController.getTenants(10, page1.locator);
        Test.stopTest();

        System.assertEquals(0, pageBeyond.records.size());
    }

    @isTest
    static void testCreateTenant() {
        Test.startTest();
        Tenant__c t = TestDataFactory.buildTenant('New Tenant');
        Id newId = TenantController.createTenant(t);
        Test.stopTest();

        System.assertNotEquals(null, newId);
    }
}