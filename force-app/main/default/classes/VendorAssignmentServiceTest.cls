@isTest
private class VendorAssignmentServiceTest {

    @isTest
    static void testAssignsToLeastBusyVendor() {
        Property__c prop = TestDataFactory.buildProperty('Maintenance Property');
        insert prop;

        Vendor__c busyVendor = TestDataFactory.buildVendor('Busy Vendor');
        Vendor__c freeVendor = TestDataFactory.buildVendor('Free Vendor');
        insert new List<Vendor__c>{ busyVendor, freeVendor };

        // Give the busy vendor two open requests already.
        List<Maintenance_Request__c> existing = new List<Maintenance_Request__c>{
            new Maintenance_Request__c(Property__c = prop.Id, Vendor__c = busyVendor.Id, Status__c = 'Open', Description__c = 'Leak 1'),
            new Maintenance_Request__c(Property__c = prop.Id, Vendor__c = busyVendor.Id, Status__c = 'In Progress', Description__c = 'Leak 2')
        };
        insert existing;

        Test.startTest();
        Maintenance_Request__c newRequest = new Maintenance_Request__c(
            Property__c = prop.Id,
            Status__c = 'Open',
            Description__c = 'New issue'
        );
        insert newRequest; // Vendor__c intentionally left blank -> trigger should auto-assign
        Test.stopTest();

        Maintenance_Request__c inserted = [SELECT Vendor__c FROM Maintenance_Request__c WHERE Id = :newRequest.Id];
        System.assertEquals(freeVendor.Id, inserted.Vendor__c);
    }

    @isTest
    static void testDoesNotOverrideExplicitVendor() {
        Property__c prop = TestDataFactory.buildProperty('Maintenance Property 2');
        insert prop;
        Vendor__c vendor = TestDataFactory.buildVendor('Chosen Vendor');
        insert vendor;

        Test.startTest();
        Maintenance_Request__c mr = new Maintenance_Request__c(
            Property__c = prop.Id,
            Vendor__c = vendor.Id,
            Status__c = 'Open',
            Description__c = 'Pre-assigned'
        );
        insert mr;
        Test.stopTest();

        Maintenance_Request__c inserted = [SELECT Vendor__c FROM Maintenance_Request__c WHERE Id = :mr.Id];
        System.assertEquals(vendor.Id, inserted.Vendor__c);
    }

    @isTest
    static void testNoVendorsExistNoException() {
        Property__c prop = TestDataFactory.buildProperty('No Vendors Property');
        insert prop;

        Test.startTest();
        Maintenance_Request__c mr = new Maintenance_Request__c(
            Property__c = prop.Id,
            Status__c = 'Open',
            Description__c = 'No vendors available'
        );
        insert mr;
        Test.stopTest();

        Maintenance_Request__c inserted = [SELECT Vendor__c FROM Maintenance_Request__c WHERE Id = :mr.Id];
        System.assertEquals(null, inserted.Vendor__c);
    }
}