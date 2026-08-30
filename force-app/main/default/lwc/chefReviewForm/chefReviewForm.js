// chefReviewForm.js
import { LightningElement, wire, track, api } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getChefs from '@salesforce/apex/ChefController.getChefs'; // Apex method to fetch chefs

export default class ChefReviewForm extends LightningElement {
    @track customerName = '';
    @track chefName = '';
    @track rating = '';
    @track comments = '';
    @track chefOptions = [];
    @track error;


    fileTypes = ['.jpg', '.png', '.mp4', '.mov']; // File types for upload
    recordId; // For file uploads if needed to associate with a record

    @wire(getChefs)
    wiredChefs({ error, data }) {
        if (data) {
            this.chefOptions = data.map(chef => ({ label: chef.Name__c, value: chef.Name__c }));
            this.error = null;
            console.log('Retrieved Chef Names:'+ this.chefNames);
            
        } else if (error) {
            console.error('Error fetching chefs:', error);
            this.error = 'Failed to fetch chefs';
            this.showToast('Error', 'Failed to fetch chefs', 'error');
        }
    }



    handleInputChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }

    submitReview() {
        const fields = { 
            'Customer_Name__c': this.customerName, 
            'Chef__c': this.chefName,
            'Rating__c': this.rating, 
            'Comments__c': this.comments 
        };

        const recordInput = { apiName: 'ChefReview__c', fields };

       createRecord(recordInput)
            .then(() => {
                this.showToast('Success', 'Review submitted successfully', 'success');
                // Clear the form
                this.customerName = '';
                this.chefName = '';
                this.rating = '';
                this.comments = '';
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    handleUploadFinished(event) {
        // Handles the file upload finished event
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}