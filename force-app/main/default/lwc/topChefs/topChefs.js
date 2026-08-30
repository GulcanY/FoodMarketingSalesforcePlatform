import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getTopChefs from '@salesforce/apex/TopChefsController.getTopChefs';

export default class TopChefs extends NavigationMixin(LightningElement) {// This should be set by the flow when it finishes, passing the Cart ID
    @track chefs = [];

    @wire(getTopChefs)
    wiredChefs({ error, data }) {
        if (data) {
            this.chefs = data;
        } else if (error) {
            console.error('Error fetching top chefs:', error);
        }
    }
    navigateToChef(event) {
        const chefId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'lightning__RecordPage',
            attributes: {
                recordId: chefId,
                objectApiName: 'Chef__c', // Replace with your actual object API name
                actionName: 'view'
            }
        });
    }
}