import { LightningElement, wire, track } from 'lwc';
import getCartItems from '@salesforce/apex/CartController.getCartItems';
import updateCartItem from '@salesforce/apex/CartController.updateCartItem';
import removeCartItem from '@salesforce/apex/CartController.removeCartItem';
import placeDemoOrder from '@salesforce/apex/CheckoutController.placeDemoOrder';
import isGuest from '@salesforce/user/isGuest';
import { NavigationMixin } from 'lightning/navigation';
import { publish, subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import CART_CHANNEL from '@salesforce/messageChannel/CartChannel__c';

// Full-page view of the current user's open cart (the Cart page requires login).
export default class CartView extends NavigationMixin(LightningElement) {
    @track items = [];
    isLoading = true;
    errorMessage;
    subscription;
    isPlacingOrder = false;
    order;
    delivery = { name: '', phone: '', street: '', city: '', state: '', zip: '', notes: '' };

    @wire(MessageContext)
    messageContext;

    get isGuestUser() {
        return isGuest;
    }

    get hasItems() {
        return this.items.length > 0;
    }

    get totalPrice() {
        return this.items.reduce((sum, item) => sum + item.lineTotal, 0);
    }

    get totalQuantity() {
        return this.items.reduce((sum, item) => sum + item.quantity, 0);
    }

    connectedCallback() {
        if (isGuest) {
            this.isLoading = false;
            return;
        }
        this.loadCart();
        this.subscription = subscribe(this.messageContext, CART_CHANNEL, () => this.loadCart());
    }

    disconnectedCallback() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    loadCart() {
        this.isLoading = true;
        return getCartItems()
            .then(data => {
                this.items = data.map(wrapper => ({
                    id: wrapper.cartItem.Id,
                    name: wrapper.cartItem.Food__r ? wrapper.cartItem.Food__r.Name : '',
                    price: wrapper.cartItem.Price__c,
                    quantity: wrapper.cartItem.l_Quantity__c,
                    lineTotal: wrapper.cartItem.Price__c * wrapper.cartItem.l_Quantity__c,
                    imageUrl: wrapper.foodImageUrl
                }));
                this.errorMessage = undefined;
            })
            .catch(error => {
                this.errorMessage = error && error.body ? error.body.message : 'Unable to load your cart.';
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    changeQuantity(cartItemId, quantity) {
        updateCartItem({ cartItemId, quantity })
            .then(() => this.loadCart())
            .catch(error => {
                this.errorMessage = error && error.body ? error.body.message : 'Unable to update your cart.';
            });
    }

    handleIncrease(event) {
        const item = this.items.find(i => i.id === event.currentTarget.dataset.id);
        this.changeQuantity(item.id, item.quantity + 1);
    }

    handleDecrease(event) {
        const item = this.items.find(i => i.id === event.currentTarget.dataset.id);
        this.changeQuantity(item.id, item.quantity - 1);
    }

    handleRemove(event) {
        removeCartItem({ cartItemId: event.currentTarget.dataset.id })
            .then(() => this.loadCart())
            .catch(error => {
                this.errorMessage = error && error.body ? error.body.message : 'Unable to update your cart.';
            });
    }

    handleDeliveryChange(event) {
        this.delivery = { ...this.delivery, [event.target.name]: event.target.value };
    }

    handlePlaceOrder() {
        const inputs = [...this.template.querySelectorAll('.delivery-input')];
        const valid = inputs.reduce((ok, input) => input.reportValidity() && ok, true);
        if (!valid) {
            return;
        }
        this.isPlacingOrder = true;
        this.errorMessage = undefined;
        placeDemoOrder({ delivery: this.delivery })
            .then(result => {
                this.order = result;
                this.items = [];
                publish(this.messageContext, CART_CHANNEL, { cartItemId: null });
            })
            .catch(error => {
                this.errorMessage = error && error.body ? error.body.message : 'Your order could not be placed.';
            })
            .finally(() => {
                this.isPlacingOrder = false;
            });
    }

    handleLogin() {
        this[NavigationMixin.Navigate]({
            type: 'comm__loginPage',
            attributes: { actionName: 'login' }
        });
    }

    handleContinueShopping() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Home' }
        });
    }
}
