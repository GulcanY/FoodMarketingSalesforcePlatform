import { LightningElement, api, wire, track } from 'lwc';
import getCartDetails from '@salesforce/apex/cartDetails.getCartDetails';

export default class OrderCompletion extends LightningElement {
    @api recordId;  // This should be set by the flow when it finishes, passing the Cart ID
    @track cartDetails;
    @track isModalOpen = false;

    @wire(getCartDetails, { cartId: '$recordId' })
    wiredCartDetails({ error, data }) {
        if (data) {
            console.log('Data received:', data);
            this.cartDetails = data;
            this.openModal();
        } else if (error) {
            console.error('Error fetching cart details:', error);
        }
    }

    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }

    get cartNumber() {
        return this.cartDetails ? this.cartDetails.Name : '';
    }

    get totalQuantity() {
        return this.cartDetails ? this.cartDetails.Total_Quantity__c : '';
    }

    get totalAmount() {
        return this.cartDetails ? this.cartDetails.Total_Amount__c : '';
    }

    get customerName() {
        return this.cartDetails && this.cartDetails.CustomerH__r ? this.cartDetails.CustomerH__r.Name : '';
    }

    get deliveryAddress() {
        return this.cartDetails && this.cartDetails.CustomerH__r ? `${this.cartDetails.CustomerH__r.Street_Address__c}, ${this.cartDetails.CustomerH__r.City__c}, ${this.cartDetails.CustomerH__r.Zip_code__c}` : '';
    }
}