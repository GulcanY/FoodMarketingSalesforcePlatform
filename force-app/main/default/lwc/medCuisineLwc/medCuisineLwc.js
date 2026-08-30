import { LightningElement, wire, track } from 'lwc';
import getMedCuisineFoods from '@salesforce/apex/MedCuisineController.getMedCuisineFoods';
import addToCart from '@salesforce/apex/ShoppingCartController.addToCart';


export default class MedCuisineLwc extends LightningElement {
    
    @track foods = [];
    @track isModalOpen = false; // Track whether the modal is open
    @track selectedFood = null; // Store the selected food data
    quantity = 1; // Default quantity for a combined component scenario

    @wire(getMedCuisineFoods)
    wiredFoods({ error, data }) {
        if (data) {
            this.foods = data.map(item => {
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

    handleViewDetail(event) {
        const foodId = event.currentTarget.dataset.foodId;
        console.log(`Looking for food with ID: ${foodId}`);
    
        // Find the specific food item in the 'foods' array
        this.selectedFood = this.foods.find(food => food.food.Id === foodId);
        console.log('Selected Food:', this.selectedFood);
    
        // Open the modal if the food item was found
        if (this.selectedFood) {
            this.isModalOpen = true;
        } else {
            console.error('Selected food is undefined.');
        }
    }
    
    
    

    closeModal() {
        this.isModalOpen = false; // Close the modal
    }

    handleIncreaseQuantity() {
        this.quantity += 1;
        console.log('Increased Quantity:', this.quantity);
    }

    handleDecreaseQuantity() {
        if (this.quantity > 1) {
            this.quantity -= 1;
            console.log('Decreased Quantity:', this.quantity);
        }
    }

    handleQuantityChange(event) {
        this.quantity = parseInt(event.target.value, 10);
    }

    handleAddToCart() {
        if (!this.selectedFood) {
            console.error('No food selected');
            return;
        }

        const foodId = this.selectedFood.food.Id;
        const price = this.selectedFood.food.Price__c;
        const quantity = this.quantity;

        addToCart({ foodId, quantity, price })
            .then(result => {
                console.log('Cart Item Created:', result);
                this.closeModal(); // Optionally close the modal after adding to cart
            })
            .catch(error => {
                console.error('Error adding to cart:', error);
                console.log('Error details:', JSON.stringify(error.body)); // Log the detailed error
            });
    }
}