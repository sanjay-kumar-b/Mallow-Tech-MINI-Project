public with sharing class MaintenanceRequestTriggerHandler {
    public static void handleBeforeInsert(List<Maintenance_Request__c> newRequests) {
        VendorAssignmentService.assignVendors(newRequests);
    }
}