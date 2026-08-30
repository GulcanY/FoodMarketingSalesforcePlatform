import { LightningElement, wire, track } from 'lwc';
import getCartItems from '@salesforce/apex/CartController.getCartItems';
import updateCartItem from '@salesforce/apex/CartController.updateCartItem';
import removeCartItem from '@salesforce/apex/CartController.removeCartItem';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

export default class CartButton extends NavigationMixin(LightningElement) {
    @track cartItems = [];
    @track isCartOpen = false;
    @track totalItems = 0;
    @track totalPrice = 0;
    wiredCartResult;

    @wire(getCartItems)
    wiredCartItems(result) {
        this.wiredCartResult = result;
        if (result.data) {
            this.cartItems = result.data;
            this.updateCartSummary();
        } else if (result.error) {
            console.error('Error fetching cart items:', result.error);
        }
    }
    handleCartButtonClick() {
        this.isCartOpen = !this.isCartOpen;
    }

    handleCartClose() {
        this.isCartOpen = false;
    }
    toggleCart() {
        this.isCartOpen = !this.isCartOpen;
    }
    handleIncreaseQuantity(event) {
        const cartItemId = event.target.dataset.id;
        const cartItem = this.cartItems.find(item => item.cartItem.Id === cartItemId);
        const newQuantity = cartItem.cartItem.l_Quantity__c + 1;
        this.updateQuantity(cartItemId, newQuantity);
    }
    
    handleDecreaseQuantity(event) {
        const cartItemId = event.target.dataset.id;
        const cartItem = this.cartItems.find(item => item.cartItem.Id === cartItemId);
        const newQuantity = Math.max(cartItem.cartItem.l_Quantity__c - 1, 0); // Prevent negative quantities
        this.updateQuantity(cartItemId, newQuantity);
    }
    
    updateQuantity(cartItemId, newQuantity) {
        updateCartItem({ cartItemId, quantity: newQuantity })
            .then(() => {
                return refreshApex(this.wiredCartResult);
            })
            .catch(error => {
                console.error('Error updating cart item:', error);
            });
    }
    
    handleQuantityChange(event) {
        const cartItemId = event.target.dataset.id;
        const newQuantity = event.target.value;

        updateCartItem({ cartItemId, quantity: newQuantity })
            .then(() => {
                return refreshApex(this.wiredCartResult);
            })
            .catch(error => {
                console.error('Error updating cart item:', error);
            });
    }

    handleRemoveItem(event) {
        const cartItemId = event.target.dataset.id;

        removeCartItem({ cartItemId })
            .then(() => {
                return refreshApex(this.wiredCartResult);
            })
            .catch(error => {
                console.error('Error removing cart item:', error);
            });
    }

    handleCheckout() {
        // Navigate to the checkout page
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/customer-login-page'
            }
        });
    }

    updateCartSummary() {
        this.totalItems = this.cartItems.length;
        this.totalPrice = this.cartItems.reduce((acc, item) => acc + item.cartItem.Food__r.Price__c * item.cartItem.l_Quantity__c, 0);
    }

    get cartItemCount() {
        return this.cartItems.length;
    }
}