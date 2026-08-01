@isTest
private class LeaseAgreementControllerTest {

    @isTest
    static void testCreateAndListLeaseAgreements() {
        Property__c prop = TestDataFactory.buildProperty('Leased Property');
        insert prop;
        Tenant__c tenant = TestDataFactory.buildTenant('Jane Smith');
        insert tenant;

        Test.startTest();
        Lease_Agreement__c lease = TestDataFactory.buildLease(prop.Id, tenant.Id, Date.today(), Date.today().addMonths(12));
        Id leaseId = LeaseAgreementController.createLeaseAgreement(lease);
        List<Lease_Agreement__c> leasesForProperty = LeaseAgreementController.getLeaseAgreements(prop.Id);
        List<Lease_Agreement__c> allLeases = LeaseAgreementController.getLeaseAgreements(null);
        Test.stopTest();

        System.assertNotEquals(null, leaseId);
        System.assertEquals(1, leasesForProperty.size());
        System.assertEquals(1, allLeases.size());
    }

    @isTest
    static void testSendLeaseAgreementPdf() {
        Property__c prop = TestDataFactory.buildProperty('PDF Property');
        insert prop;
        Tenant__c tenant = TestDataFactory.buildTenant('Pdf Tenant');
        insert tenant;
        Lease_Agreement__c lease = TestDataFactory.buildLease(prop.Id, tenant.Id, Date.today(), Date.today().addMonths(12));
        insert lease;

        String base64Pdf = EncodingUtil.base64Encode(Blob.valueOf('fake-pdf-bytes'));

        Test.startTest();
        LeaseAgreementController.sendLeaseAgreementPdf(lease.Id, base64Pdf, 'lease.pdf');
        Test.stopTest();

        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :lease.Id];
        System.assertEquals(1, links.size());
    }
}