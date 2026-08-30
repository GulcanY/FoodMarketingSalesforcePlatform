import { LightningElement, api, wire } from 'lwc';
import getChefDetails from '@salesforce/apex/ChefDetailsController.getChefDetails';

export default class ChefRecordPage extends LightningElement {
    @api recordId;
    chef;
    error;

    
    @wire(getChefDetails, { recordId: '$recordId' })
    wiredChef({ error, data }) {
        if (data) {
            this.chef = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.chef = undefined;
        }
    }

    connectedCallback() {
        console.log('Record ID:', this.recordId);
    }

}