import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createTenant from '@salesforce/apex/TenantController.createTenant';

export default class TenantForm extends LightningElement {
    name;
    phone;
    email;
    isSaving = false;

    get isSaveDisabled() {
        return this.isSaving || !this.name;
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }

    handleSave() {
        this.isSaving = true;
        const tenant = { Name: this.name, Phone_Number__c: this.phone, Email__c: this.email };

        createTenant({ tenant })
            .then(() => {
                this.showToast('Success', 'Tenant created successfully.', 'success');
                this.name = undefined;
                this.phone = undefined;
                this.email = undefined;

                this.dispatchEvent(new CustomEvent('created'));
            })
            .catch((error) => {
                this.showToast('Error', error?.body?.message || 'Failed to create tenant.', 'error');
            })
            .finally(() => {
                this.isSaving = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}