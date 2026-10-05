import { LightningElement, api, track, wire } from 'lwc';

import getChefDetails from '@salesforce/apex/ChefDetailsController.getChefDetails';
import relatedFiles from '@salesforce/apex/ChefCtrl.relatedFiles';
import getRelatedFiles from '@salesforce/apex/ChefCtrl.getRelatedFiles';

import CHEF_CHANNEL from '@salesforce/messageChannel/ChefChannel__c';
import { APPLICATION_SCOPE, MessageContext, subscribe, unsubscribe } from 'lightning/messageService';

// Public chef profile. Data comes only from Apex methods that return
// public fields (no email, phone or address).
export default class ChefCard extends LightningElement {

    chefId;
    chef;
    error;
    chefImage;
    @track foodDetails;
    subscription;

    // Set by a parent component or by the message channel
    @api
    get chefRecorId() {
        return this.chefId;
    }
    set chefRecorId(value) {
        this.chefId = value;
    }

    // Set by the Experience Cloud object page ({!recordId})
    @api
    get recordId() {
        return this.chefId;
    }
    set recordId(value) {
        if (value) {
            this.chefId = value;
        }
    }

    @wire(getChefDetails, { recordId: '$chefId' })
    wiredChef({ data, error }) {
        if (data) {
            this.chef = data;
            this.error = undefined;
        } else if (error) {
            this.chef = undefined;
            this.error = error;
        }
    }

    @wire(relatedFiles, { chefImageId: '$chefId' })
    photoDetails({ data, error }) {
        if (data) {
            this.chefImage = data;
        } else if (error) {
            console.log('ERROR -----', JSON.stringify(error));
        }
    }

    @wire(getRelatedFiles, { chefId: '$chefId' })
    wiredFoodDetails({ error, data }) {
        if (data) {
            this.foodDetails = data;
        } else if (error) {
            this.error = error;
        }
    }

    @wire(MessageContext)
    context;

    connectedCallback() {
        this.subscription = subscribe(
            this.context,
            CHEF_CHANNEL,
            (message) => { this.handleMessage(message); },
            { scope: APPLICATION_SCOPE }
        );
    }

    disconnectedCallback() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleMessage(message) {
        this.chefId = message.chefId;
    }

    get hasFoods() {
        return this.foodDetails && this.foodDetails.length > 0;
    }

    get notFound() {
        return this.error && !this.chef;
    }
}
