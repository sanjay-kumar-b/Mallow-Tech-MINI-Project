import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import assignPropertyToTenant from '@salesforce/apex/PropertyTenantController.assignPropertyToTenant';

export default class AssignTenant extends LightningElement {
    @api recordId;
    @api objectApiName;

    propertyId;
    tenantId;
    assignedDate;
    isSaving = false;

    connectedCallback() {
        this.assignedDate = new Date().toISOString().slice(0, 10);

        if (this.objectApiName === 'Property__c') {
            this.propertyId = this.recordId;
        } else if (this.objectApiName === 'Tenant__c') {
            this.tenantId = this.recordId;
        }
    }

    get isPropertyPreselected() {
        return this.objectApiName === 'Property__c';
    }

    get isTenantPreselected() {
        return this.objectApiName === 'Tenant__c';
    }

    get isSaveDisabled() {
        return this.isSaving || !this.propertyId || !this.tenantId;
    }

    handlePropertyChange(event) {
        this.propertyId = event.detail.recordId;
    }

    handleTenantChange(event) {
        this.tenantId = event.detail.recordId;
    }

    handleDateChange(event) {
        this.assignedDate = event.target.value;
    }

    handleAssign() {
        this.isSaving = true;

        assignPropertyToTenant({
            propertyId: this.propertyId,
            tenantId: this.tenantId,
            assignedDate: this.assignedDate
        })
            .then(() => {
                this.showToast('Success', 'Property assigned to tenant. A task to generate the lease agreement has been created.', 'success');
                this.dispatchEvent(new CustomEvent('assigned'));
                this.resetForm();
            })
            .catch((error) => {
                this.showToast('Error', error?.body?.message || 'Failed to assign property to tenant.', 'error');
            })
            .finally(() => {
                this.isSaving = false;
            });
    }

    resetForm() {
        if (!this.isPropertyPreselected) {
            this.propertyId = undefined;
        }
        if (!this.isTenantPreselected) {
            this.tenantId = undefined;
        }
        this.assignedDate = new Date().toISOString().slice(0, 10);

        const pickers = this.template.querySelectorAll('lightning-record-picker');
        pickers.forEach((picker) => {
            picker.clearSelection?.();
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}