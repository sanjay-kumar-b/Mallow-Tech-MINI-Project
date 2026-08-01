import { LightningElement, api, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import jsPDFResource from '@salesforce/resourceUrl/jsPDF';
import sendLeaseAgreementPdf from '@salesforce/apex/LeaseAgreementController.sendLeaseAgreementPdf';

import NAME_FIELD from '@salesforce/schema/Lease_Agreement__c.Name';
import TENANT_NAME_FIELD from '@salesforce/schema/Lease_Agreement__c.Tenant__r.Name';
import TERMS_FIELD from '@salesforce/schema/Lease_Agreement__c.Terms__c';
import RENT_FIELD from '@salesforce/schema/Lease_Agreement__c.Agreed_Monthly_Rent__c';
import START_DATE_FIELD from '@salesforce/schema/Lease_Agreement__c.Start_Date__c';
import END_DATE_FIELD from '@salesforce/schema/Lease_Agreement__c.End_Date__c';

const FIELDS = [NAME_FIELD, TENANT_NAME_FIELD, TERMS_FIELD, RENT_FIELD, START_DATE_FIELD, END_DATE_FIELD];

export default class LeaseAgreementActions extends LightningElement {
    @api recordId;

    jsPdfLoaded = false;
    isBusy = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    lease;

    renderedCallback() {
        if (this.jsPdfLoaded) {
            return;
        }
        loadScript(this, jsPDFResource)
            .then(() => {
                this.jsPdfLoaded = true;
            })
            .catch((error) => {
                this.showToast('Error', 'Failed to load PDF library: ' + error.message, 'error');
            });
    }

    get leaseName() {
        return this.lease?.data?.fields?.Name?.value;
    }

    get tenantName() {
        return this.lease?.data?.fields?.Tenant__r?.value?.fields?.Name?.value ?? 'N/A';
    }

    get terms() {
        return this.lease?.data?.fields?.Terms__c?.value ?? '';
    }

    get rent() {
        return this.lease?.data?.fields?.Agreed_Monthly_Rent__c?.value;
    }

    get startDate() {
        return this.lease?.data?.fields?.Start_Date__c?.value;
    }

    get endDate() {
        return this.lease?.data?.fields?.End_Date__c?.value;
    }

    /*
     * Builds the PDF client-side with jsPDF and returns
     * both a jsPDF doc instance and the plain base64 payload for the Apex call.
    */
    buildPdf() {
        const { jsPDF } = window.jspdf;
        const doc = new jsPDF();

        doc.setFontSize(16);
        doc.text('Lease Agreement', 14, 20);
        doc.setFontSize(11);

        const lines = [
            `Agreement: ${this.leaseName || ''}`,
            `Tenant: ${this.tenantName || ''}`,
            `Agreed Monthly Rent: ${this.rent || ''}`,
            `Start Date: ${this.startDate || ''}`,
            `End Date: ${this.endDate || ''}`,
            '',
            'Terms:'
        ];
        let y = 32;
        lines.forEach((line) => {
            doc.text(line, 14, y);
            y += 8;
        });

        const termsText = doc.splitTextToSize(this.terms || 'N/A', 180);
        doc.text(termsText, 14, y);

        return doc;
    }

    handleDownloadPdf() {
        if (!this.jsPdfLoaded) {
            this.showToast('Error', 'PDF library is still loading, please try again shortly.', 'error');
            return;
        }
        const doc = this.buildPdf();
        doc.save(`${this.leaseName || 'lease-agreement'}.pdf`);
    }

    handleSendPdf() {
        if (!this.jsPdfLoaded) {
            this.showToast('Error', 'PDF library is still loading, please try again shortly.', 'error');
            return;
        }
        this.isBusy = true;
        const doc = this.buildPdf();
        // jsPDF datauristring output: "data:application/pdf;filename=...;base64,<data>"
        const dataUri = doc.output('datauristring');
        const base64Pdf = dataUri.split(',')[1];
        const fileName = `${this.leaseName || 'lease-agreement'}.pdf`;

        sendLeaseAgreementPdf({ leaseAgreementId: this.recordId, base64Pdf, fileName })
            .then(() => {
                this.showToast('Success', 'Lease agreement PDF sent to tenant.', 'success');
            })
            .catch((error) => {
                this.showToast('Error', error?.body?.message || 'Failed to send PDF.', 'error');
            })
            .finally(() => {
                this.isBusy = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}