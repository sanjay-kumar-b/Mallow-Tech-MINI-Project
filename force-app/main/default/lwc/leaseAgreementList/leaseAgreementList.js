import { LightningElement, api, track } from 'lwc';
import getLeaseAgreements from '@salesforce/apex/LeaseAgreementController.getLeaseAgreements';

export default class LeaseAgreementList extends LightningElement {
    @api recordId;
    @track leases = [];
    isLoading = false;
    errorMessage;

    connectedCallback() {
        this.loadLeases();
    }

    @api
    refresh() {
        this.loadLeases();
    }

    loadLeases() {
        this.isLoading = true;
        this.errorMessage = undefined;

        getLeaseAgreements({ propertyId: this.recordId })
            .then((result) => {
                this.leases = result;
            })
            .catch((error) => {
                this.errorMessage = error?.body?.message || 'Failed to load lease agreements.';
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}