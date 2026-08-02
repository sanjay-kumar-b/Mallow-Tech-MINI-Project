import { LightningElement, wire, api, track } from 'lwc';
import getLeaseAgreements from '@salesforce/apex/LeaseAgreementController.getLeaseAgreements';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import RECORD_REFRESH_CHANNEL from '@salesforce/messageChannel/RecordRefresh__c';

export default class LeaseAgreementList extends LightningElement {
    @api recordId;
    @track leases = [];
    isLoading = false;
    errorMessage;

    subscription = null;

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.subscription = subscribe(
            this.messageContext,
            RECORD_REFRESH_CHANNEL,
            (message) => {
                console.log('Received Message from another component' + message);
                this.handleMessage();
            }
        );

        this.loadLeases();
    }

    disconnectedCallback() {
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
    }

    handleMessage() {
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