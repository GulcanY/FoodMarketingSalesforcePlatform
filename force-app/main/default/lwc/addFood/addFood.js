import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class AddFood extends NavigationMixin(LightningElement) {
    @track showFoodFlow = true;

    handleFoodFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.showFoodFlow = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Adding food completed successfully.',
                    variant: 'success'
                })
            );
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: {
                    pageName: 'home'
                }
            });
        }
    }
}