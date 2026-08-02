import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createProperty from '@salesforce/apex/PropertyController.createProperty';

const TYPE_OPTIONS = [
    { label: 'Residential', value: 'Residential' },
    { label: 'Commercial', value: 'Commercial' }
];

const FURNISHING_OPTIONS = [
    { label: 'Furnished', value: 'Furnished' },
    { label: 'Semi-Furnished', value: 'Semi-Furnished' },
    { label: 'Unfurnished', value: 'Unfurnished' }
];

const STATUS_OPTIONS = [
    { label: 'Available', value: 'Available' },
    { label: 'Occupied', value: 'Occupied' }
];

export default class PropertyForm extends LightningElement {
    typeOptions = TYPE_OPTIONS;
    furnishingOptions = FURNISHING_OPTIONS;
    statusOptions = STATUS_OPTIONS;

    name;
    address;
    city;
    state;
    postalCode;
    country;
    type;
    furnishingStatus;
    status = 'Available';
    rent;
    description;

    images = [];
    isSaving = false;

    get hasImages() {
        return this.images.length > 0;
    }

    get isSaveDisabled() {
        return this.isSaving || this.images.length === 0;
    }
	
	get fileNames() {
        return this.images.map((i) => i.fileName).join(', ');
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }

    handlePicklistChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.detail.value;
    }

    handleFileChange(event) {
        const fileInput = event.target;
        const files = Array.from(event.target.files || []);

        if (!files.length) {
            return;
        }

        const readers = files.map(
            (file) =>
                new Promise((resolve, reject) => {
                    const reader = new FileReader();
                    reader.onload = () => resolve({ id: Date.now() + Math.random(), fileName: file.name, base64Data: reader.result.split(',')[1], previewUrl: reader.result });
                    reader.onerror = reject;
                    reader.readAsDataURL(file);
                })
        );

        Promise.all(readers).then((results) => {
            this.images = [...this.images, ...results];
            if (fileInput) {
                fileInput.value = '';
            }
        })
        .catch(error => {
            console.log('Error:', JSON.stringify(error));
            console.log('Error object:', error);
            console.log('Message:', error?.message);
            console.log('Stack:', error?.stack);
            this.showToast('Error', 'Failed to read selected image(s).', 'error');
        });
    }

    removeImage(event) {
        const index = Number(event.currentTarget.dataset.index);

        this.images = this.images.filter((img, i) => i !== index);

        if (this.images.length === 0) {
            const fileInput = this.template.querySelector('.hidden-file-input');
            if (fileInput) {
                fileInput.value = '';
            }
        }
    }

    openFilePicker() {
        this.template.querySelector('.hidden-file-input').click();
    }

    handleSave() {
        if (!this.images.length) {
            this.showToast('Error', 'Please attach at least one property image before saving.', 'error');
            return;
        }
        this.isSaving = true;

        const property = {
            Name: this.name,
            Address__c: this.address,
            City__c: this.city,
            State__c: this.state,
            Postal_Code__c: this.postalCode,
            Country__c: this.country,
            Type__c: this.type,
            Furnishing_Status__c: this.furnishingStatus,
            Status__c: this.status,
            Rent__c: this.rent,
            Description__c: this.description
        };

        createProperty({ property, images: this.images })
            .then(() => {
                this.showToast('Success', 'Property created successfully.', 'success');
                this.resetForm();
            })
            .catch((error) => {
                this.showToast('Error', error?.body?.message || 'Failed to create property.', 'error');
            })
            .finally(() => {
                this.isSaving = false;
            });
    }

    resetForm() {
        this.name = undefined;
        this.address = undefined;
        this.city = undefined;
        this.state = undefined;
        this.postalCode = undefined;
        this.country = undefined;
        this.type = undefined;
        this.furnishingStatus = undefined;
        this.status = 'Available';
        this.rent = undefined;
        this.description = undefined;
        this.images = [];

        const fileInput = this.template.querySelector('input[type="file"]');
        if (fileInput) {
            fileInput.value = '';
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}