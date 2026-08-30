import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ChefRegistration extends LightningElement {
    @track showFlow = false;
    @track showFoodFlow = false;

    handleButtonClick() {
        this.showFlow = true;
    }

    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.showFlow = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Chef registration completed successfully.',
                    variant: 'success'
                })
            );
        }
    }
    handleFoodFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.showFoodFlow = false;
        }
    }
}