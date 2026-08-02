import { LightningElement, wire, track } from 'lwc';
import getProperties from '@salesforce/apex/PropertyController.getProperties';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import RECORD_REFRESH_CHANNEL from '@salesforce/messageChannel/RecordRefresh__c';

const STATUS_OPTIONS = [
    { label: 'All', value: '' },
    { label: 'Available', value: 'Available' },
    { label: 'Occupied', value: 'Occupied' }
];

const FURNISHING_OPTIONS = [
    { label: 'All', value: '' },
    { label: 'Furnished', value: 'Furnished' },
    { label: 'Semi-Furnished', value: 'Semi-Furnished' },
    { label: 'Unfurnished', value: 'Unfurnished' }
];

export default class PropertyList extends LightningElement {
    @track properties = [];
    statusOptions = STATUS_OPTIONS;
    furnishingOptions = FURNISHING_OPTIONS;

    minPrice;
    maxPrice;
    availabilityStatus = '';
    furnishingStatus = '';
    distanceKm;
    userLatitude;
    userLongitude;

    pageNumber = 1;
    pageSize = 25;
    totalRecords = 0;
    locator; // Database.Cursor locator from the last response. Reused across pages
    isLoading = false;
    errorMessage;
    geoError;

    subscription = null;

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.subscription = subscribe(
            this.messageContext,
            RECORD_REFRESH_CHANNEL,
            (message) => {
                console.log('Received Message from another component');
                this.handleMessage(message);
            }
        );

        this.loadProperties({ resetLocator: true });
    }

    disconnectedCallback() {
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
    }

    handleMessage(message) {
        this.loadProperties({ resetLocator: message.resetLocator });
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
            return 'No properties found';
        }
        const start = (this.pageNumber - 1) * this.pageSize + 1;
        const end = Math.min(this.pageNumber * this.pageSize, this.totalRecords);
        return `Showing ${start}-${end} of ${this.totalRecords}`;
    }

    handleMinPrice(event) {
        this.minPrice = event.target.value ? Number(event.target.value) : undefined;
    }

    handleMaxPrice(event) {
        this.maxPrice = event.target.value ? Number(event.target.value) : undefined;
    }

    handleStatusChange(event) {
        this.availabilityStatus = event.detail.value;
    }

    handleFurnishingChange(event) {
        this.furnishingStatus = event.detail.value;
    }

    handleDistanceChange(event) {
        this.distanceKm = event.target.value ? Number(event.target.value) : undefined;
    }

    handleUseMyLocation() {
        this.geoError = undefined;
        if (!navigator.geolocation) {
            this.geoError = 'Geolocation is not supported by this browser.';
            return;
        }
        navigator.geolocation.getCurrentPosition(
            (position) => {
                this.userLatitude = position.coords.latitude;
                this.userLongitude = position.coords.longitude;
            },
            () => {
                this.geoError = 'Unable to retrieve your location. Please allow location access.';
            }
        );
    }

    handleApplyFilters() {
        this.pageNumber = 1;
        this.loadProperties({ resetLocator: true });
    }

    handleClearFilters() {
        this.minPrice = undefined;
        this.maxPrice = undefined;
        this.availabilityStatus = '';
        this.furnishingStatus = '';
        this.distanceKm = undefined;
        this.userLatitude = undefined;
        this.userLongitude = undefined;
        this.pageNumber = 1;
        this.loadProperties({ resetLocator: true });
    }

    handlePrevious() {
        if (!this.isFirstPage) {
            this.pageNumber -= 1;
            this.loadProperties({ resetLocator: false });
        }
    }

    handleNext() {
        if (!this.isLastPage) {
            this.pageNumber += 1;
            this.loadProperties({ resetLocator: false });
        }
    }

    loadProperties({ resetLocator } = {}) {
        this.isLoading = true;
        this.errorMessage = undefined;

        const filters = {
            minPrice: this.minPrice,
            maxPrice: this.maxPrice,
            availabilityStatus: this.availabilityStatus,
            furnishingStatus: this.furnishingStatus,
            distanceKm: this.distanceKm,
            userLatitude: this.userLatitude,
            userLongitude: this.userLongitude
        };

        const locatorParam = resetLocator ? undefined : this.locator;

        console.log('Filter from LWC: ' + JSON.stringify(filters));

        getProperties({ filtersJson: JSON.stringify(filters), pageNumber: this.pageNumber, locatorParam: locatorParam })
            .then((result) => {
                this.properties = result.records;
                this.totalRecords = result.totalRecords;
                this.pageSize = result.pageSize;
                this.locator = result.locator;
            })
            .catch((error) => {
                this.errorMessage = error?.body?.message || 'Failed to load properties.';
                
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