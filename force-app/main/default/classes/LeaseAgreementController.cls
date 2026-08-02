public with sharing class LeaseAgreementController {

    @AuraEnabled
    public static List<Lease_Agreement__c> getLeaseAgreements(Id propertyId) {
        if (propertyId != null) {
            return [SELECT Id, Name, Property__c, Tenant__c, Tenant__r.Name, Tenant__r.Email__c, Terms__c, Agreed_Monthly_Rent__c, Start_Date__c, End_Date__c
                    FROM Lease_Agreement__c
                    WHERE Property__c = :propertyId
                    WITH USER_MODE
                    ORDER BY CreatedDate DESC];
        }
        return [SELECT Id, Name, Property__c, Tenant__c, Tenant__r.Name, Tenant__r.Email__c, Terms__c, Agreed_Monthly_Rent__c, Start_Date__c, End_Date__c
                FROM Lease_Agreement__c
                WITH USER_MODE
                ORDER BY CreatedDate DESC
                LIMIT 200];
    }

    @AuraEnabled
    public static Id createLeaseAgreement(Lease_Agreement__c agreement) {
        try {
            insert as user agreement;
            return agreement.Id;
        } catch (DmlException e) {
            throw new AuraHandledException('Unable to create lease agreement: ' + e.getDmlMessage(0));
        }
    }

    @AuraEnabled
    public static void sendLeaseAgreementPdf(Id leaseAgreementId, String base64Pdf, String fileName) {
        Lease_Agreement__c lease = [SELECT Id, Name, Tenant__c, Tenant__r.Name, Tenant__r.Email__c
                                    FROM Lease_Agreement__c
                                    WHERE Id = :leaseAgreementId
                                    WITH USER_MODE
                                    LIMIT 1];

        if (String.isBlank(lease.Tenant__r.Email__c)) {
            throw new AuraHandledException('Tenant does not have an email address on file.');
        }

        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        cv.VersionData = EncodingUtil.base64Decode(base64Pdf);
        cv.FirstPublishLocationId = lease.Id;
        insert as user cv;

        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName(fileName);
        attachment.setBody(EncodingUtil.base64Decode(base64Pdf));
        attachment.setContentType('application/pdf');

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ lease.Tenant__r.Email__c });
        email.setSubject('Your Lease Agreement: ' + lease.Name);
        email.setPlainTextBody('Hello ' + lease.Tenant__r.Name + ',\n\nPlease find your lease agreement attached.\n\nThank you.');
        email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
    }
}