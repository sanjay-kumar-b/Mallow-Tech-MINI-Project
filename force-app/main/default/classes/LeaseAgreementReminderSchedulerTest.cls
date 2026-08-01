@isTest
private class LeaseAgreementReminderSchedulerTest {

    @TestSetup
    static void setup() {
        Property__c prop = TestDataFactory.buildProperty('Reminder Property');
        insert prop;
        Tenant__c tenant = TestDataFactory.buildTenant('Reminder Tenant');
        insert tenant;

        List<Lease_Agreement__c> leases = new List<Lease_Agreement__c>{
            TestDataFactory.buildLease(prop.Id, tenant.Id, Date.today().addMonths(-11), Date.today().addDays(30)),
            TestDataFactory.buildLease(prop.Id, tenant.Id, Date.today().addMonths(-12), Date.today().addDays(1)),
            TestDataFactory.buildLease(prop.Id, tenant.Id, Date.today().addMonths(-1), Date.today().addMonths(11)) // not due
        };
        insert leases;
    }

    @isTest
    static void testSendRemindersUpdatesFlags() {
        Test.startTest();
        LeaseAgreementReminderScheduler.sendReminders();
        Test.stopTest();

        List<Lease_Agreement__c> dueThirty = [
            SELECT Reminder_30_Sent__c FROM Lease_Agreement__c WHERE End_Date__c = :Date.today().addDays(30)
        ];
        List<Lease_Agreement__c> dueOne = [
            SELECT Reminder_1_Sent__c FROM Lease_Agreement__c WHERE End_Date__c = :Date.today().addDays(1)
        ];
        System.assertEquals(1, dueThirty.size());
        System.assertEquals(true, dueThirty[0].Reminder_30_Sent__c);
        System.assertEquals(1, dueOne.size());
        System.assertEquals(true, dueOne[0].Reminder_1_Sent__c);
    }

    @isTest
    static void testSchedulableExecutes() {
        Test.startTest();
        String jobId = System.schedule(
            'Test Lease Reminder Job',
            '0 0 6 * * ?',
            new LeaseAgreementReminderScheduler()
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId);
    }
}