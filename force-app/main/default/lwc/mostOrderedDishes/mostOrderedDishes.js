import { LightningElement, wire } from 'lwc';
import getTopOrderedFoods from '@salesforce/apex/FoodCtrl.getTopOrderedFoods';

export default class MostOrderedDishes extends LightningElement {

    foods;
    error;

    @wire(getTopOrderedFoods)
    wiredFoods({ error, data }) {
        if (data) {
            console.log('Data received from Apex:', JSON.stringify(data));
            this.foods = data;
            this.error = undefined;
        } else if (error) {
            console.error('Error received from Apex:', error);
            this.error = error;
            this.foods = undefined;
        }
    }
    
}