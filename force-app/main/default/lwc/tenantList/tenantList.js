import { LightningElement, wire, track, api } from 'lwc';
import getTenants from '@salesforce/apex/TenantController.getTenants';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import RECORD_REFRESH_CHANNEL from '@salesforce/messageChannel/RecordRefresh__c';

export default class TenantList extends LightningElement {
    @track tenants = [];
    pageNumber = 1;
    pageSize = 25;
    totalRecords = 0;
    locator; // Database.Cursor locator from the last response; reused across pages
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
                this.handleMessage(message);
            }
        );

        this.loadTenants({ resetLocator: true });
    }

    disconnectedCallback() {
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
    }

    handleMessage(message) {
        this.loadTenants({ resetLocator: message.resetLocator });
    }

    get totalPages() {
        return this.totalRecords ? Math.ceil(this.totalRecords / this.pageSize) : 1;
    }

    get isFirstPage() {
        return this.pageNumber <= 1;
    }

    get isLastPage() {
        return this.pageNumber >= this.totalPages;
    }

    get pageSummary() {
        if (!this.totalRecords) {
            return 'No tenants found';
        }
        const start = (this.pageNumber - 1) * this.pageSize + 1;
        const end = Math.min(this.pageNumber * this.pageSize, this.totalRecords);
        return `Showing ${start}-${end} of ${this.totalRecords}`;
    }

    handlePrevious() {
        if (!this.isFirstPage) {
            this.pageNumber -= 1;
            this.loadTenants({ resetLocator: false });
        }
    }

    handleNext() {
        if (!this.isLastPage) {
            this.pageNumber += 1;
            this.loadTenants({ resetLocator: false });
        }
    }

    // Exposed, so a sibling "tenantForm" or "assignTenant" on the same page can
    // trigger a refresh after creating/assigning a tenant.
    @api
    refresh() {
        this.pageNumber = 1;
        this.loadTenants({ resetLocator: true });
    }

    loadTenants({ resetLocator } = {}) {
        this.isLoading = true;
        this.errorMessage = undefined;

        const locatorParam = resetLocator ? undefined : this.locator;

        getTenants({ pageNumber: this.pageNumber, locatorParam })
            .then((result) => {
                this.tenants = result.records;
                this.totalRecords = result.totalRecords;
                this.pageSize = result.pageSize;
                this.locator = result.locator;
            })
            .catch((error) => {
                this.errorMessage = error?.body?.message || 'Failed to load tenants.';
                if (this.locator) {
                    this.locator = undefined;
                    this.pageNumber = 1;
                }
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}