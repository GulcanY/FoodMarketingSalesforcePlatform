import { LightningElement,api, wire, track } from 'lwc';
import getMediterraneanCuisineFoods from '@salesforce/apex/MediterraneanCuisineController.getMediterraneanCuisineFoods';
import addToCart from '@salesforce/apex/ShoppingCartController.addToCart';


export default class MediterraneanCuisineLWC extends LightningElement {
    
    @track foods = [];
    @api foodId;
     quantity = 1; // Default quantity for a combined component scenario
   

    @wire(getMediterraneanCuisineFoods)
    wiredFoods({ error, data }) {
        if (data) {
            this.foods = data.map(item => {
                // Assuming 'Dietary__c' is a comma-separated list
                const dietaryOptions = item.food.Dietary__c ? item.food.Dietary__c.split(',').map(opt => opt.trim()).join('<br>') : '';
                return {
                    ...item,
                    food: item.food,
                    dietaryOptions // Updated property with line breaks
                };
            });
        } else if (error) {
            console.error('Error fetching foods:', error);
            this.foods = []; 
        }
    }
   

    // Method to handle increasing the quantity
    handleIncreaseQuantity() {
        this.quantity += 1; // Increment quantity
        console.log('Increased Quantity:', this.quantity); // Log to console for debugging
    }

    // Method to handle decreasing the quantity
    handleDecreaseQuantity() {
        if (this.quantity > 1) {
            this.quantity -= 1; // Decrement quantity
            console.log('Decreased Quantity:', this.quantity); // Log for debugging
        }
    }
    handleQuantityChange(event) {
        this.quantity = parseInt(event.target.value, 10); // Update quantity from user input
    }
    

    handleAddToCart(event) {
        const foodId = event.target.dataset.foodId; // Make sure this is correctly set in the HTML as `data-food-id`
    
        if (!foodId) {
            console.error('Food ID is null or undefined');
            return; // Exit if no foodId is found
        }
    
        addToCart({ foodId: foodId, quantity: this.quantity })
            .then(result => {
                console.log('Cart Item Created:', result);
            })
            .catch(error => {
                console.error('Error adding to cart:', error);
            });
    }
    
}