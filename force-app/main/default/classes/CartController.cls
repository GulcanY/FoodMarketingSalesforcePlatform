/**
 * Reads and changes items in the current user's open cart only.
 * Login is required; ownership is checked on every call (see ShoppingCartController).
 */
public with sharing class CartController {

    @AuraEnabled
    public static List<CartItemWrapper> getCartItems() {
        ShoppingCartController.requireLogin();
        Id currentUserId = UserInfo.getUserId();
        List<Cart_Item__c> cartItems = [
            SELECT Id, Food__c, Food__r.Name, Food__r.Price__c, Food__r.Image_URL__c, l_Quantity__c, Price__c
            FROM Cart_Item__c
            WHERE Cart__r.Status__c = 'Open' AND Cart__r.OwnerId = :currentUserId
            WITH USER_MODE
            ORDER BY CreatedDate
        ];

        List<CartItemWrapper> wrappedItems = new List<CartItemWrapper>();
        for (Cart_Item__c item : cartItems) {
            CartItemWrapper wrapper = new CartItemWrapper();
            wrapper.cartItem = item;
            wrapper.foodImageUrl = item.Food__r == null ? null : item.Food__r.Image_URL__c;
            wrappedItems.add(wrapper);
        }
        return wrappedItems;
    }

    @AuraEnabled
    public static void updateCartItem(Id cartItemId, Integer quantity) {
        Cart_Item__c cartItem = getOwnedOpenCartItem(cartItemId);
        if (quantity == null || quantity < 1) {
            Database.delete(cartItem, AccessLevel.SYSTEM_MODE);
            return;
        }
        cartItem.l_Quantity__c = Math.min(quantity, 99);
        Database.update(cartItem, AccessLevel.SYSTEM_MODE);
    }

    @AuraEnabled
    public static void removeCartItem(Id cartItemId) {
        Database.delete(getOwnedOpenCartItem(cartItemId), AccessLevel.SYSTEM_MODE);
    }

    private static Cart_Item__c getOwnedOpenCartItem(Id cartItemId) {
        ShoppingCartController.requireLogin();
        Id currentUserId = UserInfo.getUserId();
        List<Cart_Item__c> items = [
            SELECT Id FROM Cart_Item__c
            WHERE Id = :cartItemId AND Cart__r.Status__c = 'Open' AND Cart__r.OwnerId = :currentUserId
            WITH USER_MODE
            LIMIT 1
        ];
        if (items.isEmpty()) {
            throw ShoppingCartController.error('Cart item not found.');
        }
        return items[0];
    }

    public class CartItemWrapper {
        @AuraEnabled public Cart_Item__c cartItem;
        @AuraEnabled public String foodImageUrl;
    }
}
