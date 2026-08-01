import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

import NAME_FIELD from '@salesforce/schema/Property__c.Name';
import LOCATION_FIELD from '@salesforce/schema/Property__c.Location__c';

const FIELDS = [NAME_FIELD, LOCATION_FIELD];

export default class PropertyMap extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    property;

    get hasLocation() {
        const loc = this.property?.data?.fields?.Location__c?.value;
        return !!(loc && loc.latitude != null && loc.longitude != null);
    }

    get mapMarkers() {
        const loc = this.property?.data?.fields?.Location__c?.value;
        const name = this.property?.data?.fields?.Name?.value || 'Property';

        if (!this.hasLocation) {
            return [];
        }
        
        return [
            {
                location: {
                    Latitude: loc.latitude,
                    Longitude: loc.longitude
                },
                title: name
            }
        ];
    }
}