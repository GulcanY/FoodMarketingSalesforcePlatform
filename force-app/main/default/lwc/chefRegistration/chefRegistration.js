import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class ChefRegistration extends NavigationMixin(LightningElement) {
    @track showFoodFlow = false;

    handleButtonClick() {
        this.showFoodFlow = true;
    }

    handleFoodFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.showFoodFlow = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Adding chef completed successfully.',
                    variant: 'success'
                })
            );
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: '/add-food'
                }
            });
        }
    }
}