import { LightningElement,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMostRecentClosedCart from '@salesforce/apex/cartDetails.getMostRecentClosedCart';

export default class CustomerRecord extends NavigationMixin(LightningElement) {// This should be set by the flow when it finishes, passing the Cart ID
    @track cartDetails;
    @track isModalOpen = false;

    handleStatusChange(event) {
        if (event.detail.status === "FINISHED") {
            this.fetchMostRecentClosedCart();
        }
    }

    fetchMostRecentClosedCart() {
        getMostRecentClosedCart()
            .then(result => {
                this.cartDetails = result;
                this.isModalOpen = true;  // Open the modal only after fetching the cart details
            })
            .catch(error => {
                console.error('Error fetching the most recent closed cart details:', error);
            });
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
        return this.cartDetails && this.cartDetails.CustomerH__r ? `${this.cartDetails.CustomerH__r.Name} ${this.cartDetails.CustomerH__r.Last_Name__c}`: '';
    }

    get deliveryAddress() {
        return this.cartDetails && this.cartDetails.CustomerH__r ? `${this.cartDetails.CustomerH__r.Street_Address__c}, ${this.cartDetails.CustomerH__r.City__c}, ${this.cartDetails.CustomerH__r.State__c}, ${this.cartDetails.CustomerH__r.Country__c}, ${this.cartDetails.CustomerH__r.Zip_Code__c}` : '';
    }


    redirectToHomePage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'home'
            }
        });
    }
   
    closeModal() {
        this.isModalOpen = false;
        console.log('Closing modal and redirecting'); // Debug log
        this.redirectToHomePage();  // Ensure this line is called
    }
    
}