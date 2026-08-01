@isTest
public class TestDataFactory {

    public static Property__c buildProperty(String name) {
        return new Property__c(
            Name = name,
            Address__c = '123 Main St',
            City__c = 'Chennai',
            State__c = 'Tamil Nadu',
            Postal_Code__c = '600001',
            Country__c = 'India',
            Type__c = 'Residential',
            Furnishing_Status__c = 'Furnished',
            Status__c = 'Available',
            Rent__c = 25000,
            Description__c = 'A lovely test property.'
        );
    }

    public static Tenant__c buildTenant(String name) {
        return new Tenant__c(
            Name = name,
            Phone__c = '9876543210',
            Email__c = name.deleteWhitespace().toLowerCase() + '@example.com'
        );
    }

    public static Vendor__c buildVendor(String name) {
        return new Vendor__c(
            Name = name,
            Phone__c = '9123456780',
            Email__c = name.deleteWhitespace().toLowerCase() + '@example.com'
        );
    }

    public static Lease_Agreement__c buildLease(Id propertyId, Id tenantId, Date startDate, Date endDate) {
        return new Lease_Agreement__c(
            Property__c = propertyId,
            Tenant__c = tenantId,
            Terms__c = 'Standard 12 month lease.',
            Agreed_Monthly_Rent__c = 25000,
            Start_Date__c = startDate,
            End_Date__c = endDate
        );
    }
}