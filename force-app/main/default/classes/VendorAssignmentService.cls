public with sharing class VendorAssignmentService {

    public static void assignVendors(List<Maintenance_Request__c> newRequests) {
        
        List<Maintenance_Request__c> needsVendor = new List<Maintenance_Request__c>();
        
        for (Maintenance_Request__c mr : newRequests) {
            if (mr.Vendor__c == null) {
                needsVendor.add(mr);
            }
        }
        
        if (needsVendor.isEmpty()) {
            return;
        }

        List<Vendor__c> vendors = [SELECT Id FROM Vendor__c];
        
        if (vendors.isEmpty()) {
            return;
        }

        Map<Id, Integer> workloadByVendor = new Map<Id, Integer>();
        
        for (Vendor__c vendor : vendors) {
            workloadByVendor.put(vendor.Id, 0);
        }
        
        for (AggregateResult ar : [SELECT Vendor__c vendorId, COUNT(Id) cnt FROM Maintenance_Request__c WHERE Vendor__c != null AND Status__c IN ('Open', 'In Progress') GROUP BY Vendor__c]) {
            workloadByVendor.put((Id) ar.get('vendorId'), (Integer) ar.get('cnt'));
        }

        for (Maintenance_Request__c mr : needsVendor) {
            Id bestVendorId = null;
            Integer bestCount = null;
            for (Id vendorId : workloadByVendor.keySet()) {
                Integer count = workloadByVendor.get(vendorId);
                if (bestCount == null || count < bestCount) {
                    bestCount = count;
                    bestVendorId = vendorId;
                }
            }
            mr.Vendor__c = bestVendorId;
            workloadByVendor.put(bestVendorId, bestCount + 1);
        }
    }
}