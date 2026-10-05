import { LightningElement, wire, track } from 'lwc';
import getCartItems from '@salesforce/apex/CartController.getCartItems';
import updateCartItem from '@salesforce/apex/CartController.updateCartItem';
import removeCartItem from '@salesforce/apex/CartController.removeCartItem';
import isGuest from '@salesforce/user/isGuest';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import CART_CHANNEL from '@salesforce/messageChannel/CartChannel__c';

export default class CartButton extends NavigationMixin(LightningElement) {
    @track cartItems = [];
    @track isCartOpen = false;
    @track totalItems = 0;
    @track totalPrice = 0;
    subscription;

    @wire(MessageContext)
    messageContext;

    loadCart() {
        return getCartItems()
            .then(data => {
                this.cartItems = data;
                this.updateCartSummary();
            })
            .catch(error => {
                console.error('Error fetching cart items:', error);
            });
    }

    connectedCallback() {
        if (!isGuest) {
            this.loadCart();
            this.subscription = subscribe(this.messageContext, CART_CHANNEL, () => this.loadCart());
        }
    }

    disconnectedCallback() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleCartButtonClick() {
        if (isGuest) {
            this.navigateToLogin();
            return;
        }
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
        const newQuantity = Math.max(cartItem.cartItem.l_Quantity__c - 1, 0); // 0 removes the item
        this.updateQuantity(cartItemId, newQuantity);
    }

    updateQuantity(cartItemId, newQuantity) {
        updateCartItem({ cartItemId, quantity: newQuantity })
            .then(() => this.loadCart())
            .catch(error => {
                console.error('Error updating cart item:', error);
            });
    }

    handleQuantityChange(event) {
        const cartItemId = event.target.dataset.id;
        const newQuantity = parseInt(event.target.value, 10) || 0;
        this.updateQuantity(cartItemId, newQuantity);
    }

    handleRemoveItem(event) {
        const cartItemId = event.target.dataset.id;

        removeCartItem({ cartItemId })
            .then(() => this.loadCart())
            .catch(error => {
                console.error('Error removing cart item:', error);
            });
    }

    handleCheckout() {
        this.isCartOpen = false;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Cart__c' }
        });
    }

    navigateToLogin() {
        this[NavigationMixin.Navigate]({
            type: 'comm__loginPage',
            attributes: { actionName: 'login' }
        });
    }

    updateCartSummary() {
        this.totalItems = this.cartItems.length;
        this.totalPrice = this.cartItems.reduce((acc, item) => acc + item.cartItem.Price__c * item.cartItem.l_Quantity__c, 0);
    }

    get cartItemCount() {
        return this.cartItems.length;
    }
}
