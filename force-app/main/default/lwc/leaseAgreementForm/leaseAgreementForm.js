import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createLeaseAgreement from '@salesforce/apex/LeaseAgreementController.createLeaseAgreement';

export default class LeaseAgreementForm extends LightningElement {
    @api recordId;

    propertyId;
    tenantId;
    terms;
    agreedMonthlyRent;
    startDate;
    endDate;
    isSaving = false;

    connectedCallback() {
        if (this.recordId) {
            this.propertyId = this.recordId;
        }
    }

    get isPropertyPreselected() {
        return !!this.recordId;
    }

    get isSaveDisabled() {
        return this.isSaving || !this.propertyId || !this.tenantId || !this.agreedMonthlyRent || !this.startDate || !this.endDate;
    }

    handlePropertyChange(event) {
        this.propertyId = event.detail.recordId;
    }

    handleTenantChange(event) {
        this.tenantId = event.detail.recordId;
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }

    handleSave() {
        this.isSaving = true;
        const agreement = {
            Property__c: this.propertyId,
            Tenant__c: this.tenantId,
            Terms__c: this.terms,
            Agreed_Monthly_Rent__c: this.agreedMonthlyRent,
            Start_Date__c: this.startDate,
            End_Date__c: this.endDate
        };

        createLeaseAgreement({ agreement })
            .then(() => {
                this.showToast('Success', 'Lease agreement created.', 'success');
                this.dispatchEvent(new CustomEvent('created'));
                this.resetForm();
            })
            .catch((error) => {
                this.showToast('Error', error?.body?.message || 'Failed to create lease agreement.', 'error');
            })
            .finally(() => {
                this.isSaving = false;
            });
    }

    resetForm() {
        if (!this.recordId) {
            this.propertyId = undefined;
        }
        this.tenantId = undefined;
        this.terms = undefined;
        this.agreedMonthlyRent = undefined;
        this.startDate = undefined;
        this.endDate = undefined;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}