import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createTenant from '@salesforce/apex/TenantController.createTenant';
import { publish, MessageContext } from 'lightning/messageService';
import RECORD_REFRESH_CHANNEL from '@salesforce/messageChannel/RecordRefresh__c';

export default class TenantForm extends LightningElement {
    name;
    phone;
    email;
    isSaving = false;

    @wire(MessageContext)
    messageContext;

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

                publish(this.messageContext, RECORD_REFRESH_CHANNEL, {
                    resetLocator : true
                });
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