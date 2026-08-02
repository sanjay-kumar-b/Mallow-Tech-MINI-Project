import { LightningElement, api, wire } from 'lwc';
import getPropertyLocation from '@salesforce/apex/PropertyController.getPropertyLocation';

export default class PropertyMap extends LightningElement {
    @api recordId;
    property;
    error;

    connectedCallback() {
        this.loadPropertyLocation();
    }

    loadPropertyLocation() {
        getPropertyLocation({propertyId: this.recordId})
        .then(result => {
            console.log('Property Location:', JSON.stringify(result));

            this.property = result;
            this.error = undefined;
        })
        .catch(error => {
            console.error('Error:', error);

            this.error = error;
            this.property = undefined;
        });
    }

    get hasLocation() {
        return (
            this.property &&
            this.property.latitude != null &&
            this.property.longitude != null
        );
    }

    get mapMarkers() {
        if (!this.hasLocation) {
            return [];
        }
        
        return [
            {
                location: {
                    Latitude: this.property.latitude,
                    Longitude: this.property.longitude
                },
                title: this.property.name
            }
        ];
    }
}