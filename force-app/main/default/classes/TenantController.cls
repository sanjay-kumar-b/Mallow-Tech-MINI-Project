public with sharing class TenantController {

    public class PagedResult {
        @AuraEnabled public String locator;
        @AuraEnabled public List<Tenant__c> records;
        @AuraEnabled public Integer totalRecords;
        @AuraEnabled public Integer pageSize;
        @AuraEnabled public Integer pageNumber;
    }

    private static final Integer PAGE_SIZE = 25;

    @AuraEnabled(cacheable=true)
    public static PagedResult getTenants(Integer pageNumber, String locatorParam) {
        if (pageNumber == null || pageNumber < 1) {
            pageNumber = 1;
        }

        String query = 'SELECT Id, Name, Phone__c, Email__c FROM Tenant__c ORDER BY Name';

        Database.Cursor cursor;
        if (String.isBlank(locatorParam)) {
            cursor = Database.getCursorWithBinds(query, new Map<String, Object>(), AccessLevel.USER_MODE);
        } else {
            cursor = (Database.Cursor) JSON.deserialize(locatorParam, Database.Cursor.class);
        }

        Integer position = (pageNumber - 1) * PAGE_SIZE;
        Integer remaining = cursor.getNumRecords() - position;
        Integer fetchCount = Math.min(PAGE_SIZE, remaining);
        List<Tenant__c> records = fetchCount > 0 ? cursor.fetch(position, fetchCount) : new List<Tenant__c>();

        PagedResult result = new PagedResult();
        result.locator = JSON.serialize(cursor);
        result.records = records;
        result.totalRecords = cursor.getNumRecords();
        result.pageSize = PAGE_SIZE;
        result.pageNumber = pageNumber;
        return result;
    }

    @AuraEnabled
    public static Id createTenant(Tenant__c tenant) {
        try {
            insert as user tenant;
            return tenant.Id;
        } catch (DmlException e) {
            throw new AuraHandledException('Unable to create tenant: ' + e.getDmlMessage(0));
        }
    }
}