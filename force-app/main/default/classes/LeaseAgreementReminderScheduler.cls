public with sharing class LeaseAgreementReminderScheduler implements Schedulable {

    public void execute(SchedulableContext ctx) {
        sendReminders();
    }

    public static void sendReminders() {
        Date in30Days = Date.today().addDays(30);
        Date in1Day = Date.today().addDays(1);

        List<Lease_Agreement__c> dueSoon = [SELECT Id, Name, Tenant__r.Name, Tenant__r.Email__c, End_Date__c, Reminder_30_Sent__c, Reminder_1_Sent__c
                                            FROM Lease_Agreement__c
                                            WHERE (End_Date__c = :in30Days AND Reminder_30_Sent__c = false)
                                            OR (End_Date__c = :in1Day AND Reminder_1_Sent__c = false)];

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<Lease_Agreement__c> toUpdate = new List<Lease_Agreement__c>();

        for (Lease_Agreement__c lease : dueSoon) {
            if (String.isBlank(lease.Tenant__r.Email__c)) {
                continue;
            }

            Boolean is30 = lease.End_Date__c == in30Days && !lease.Reminder_30_Sent__c;
            Boolean is1 = lease.End_Date__c == in1Day && !lease.Reminder_1_Sent__c;

            if (is30) {
                emails.add(buildEmail(lease, 'Your lease agreement ' + lease.Name + ' expires in 30 days on ' + lease.End_Date__c.format() + '.'));
                lease.Reminder_30_Sent__c = true;
            }
            if (is1) {
                emails.add(buildEmail(lease, 'Your lease agreement ' + lease.Name + ' expires tomorrow, ' + lease.End_Date__c.format() + '.'));
                lease.Reminder_1_Sent__c = true;
            }
            toUpdate.add(lease);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
        if (!toUpdate.isEmpty()) {
            update as user toUpdate;
        }
    }

    private static Messaging.SingleEmailMessage buildEmail(Lease_Agreement__c lease, String body) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ lease.Tenant__r.Email__c });
        email.setSubject('Lease Agreement Expiry Reminder');
        email.setPlainTextBody('Hello ' + lease.Tenant__r.Name + ',\n\n' + body + '\n\nThank you.');
        return email;
    }
}