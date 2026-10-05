/**
 * Adds foods to the current user's open cart. Login is required.
 * Customers only have read access to Cart__c/Cart_Item__c, so the DML runs in
 * system mode after explicit checks: the food must be visible to the user and
 * available, the price is read from the Food__c record (never from the client),
 * and the cart must be owned by the current user.
 */
public with sharing class ShoppingCartController {

    public static final String LOGIN_REQUIRED = 'LOGIN_REQUIRED';
    private static final Integer MAX_QUANTITY = 99;

    @AuraEnabled
    public static Cart_Item__c addToCart(String foodId, Integer quantity, Decimal price) {
        // price is kept in the signature for existing LWCs but intentionally ignored
        requireLogin();
        if (quantity == null || quantity < 1 || quantity > MAX_QUANTITY) {
            throw error('Quantity must be between 1 and ' + MAX_QUANTITY + '.');
        }

        List<Food__c> foods = [
            SELECT Id, Price__c
            FROM Food__c
            WHERE Id = :foodId AND Available__c = true AND Chef__r.Available__c = true
            WITH USER_MODE
            LIMIT 1
        ];
        if (foods.isEmpty()) {
            throw error('This food is not available.');
        }
        Food__c food = foods[0];

        Cart__c cart = getOrCreateOpenCart();
        List<Cart_Item__c> existingItems = [
            SELECT Id, l_Quantity__c
            FROM Cart_Item__c
            WHERE Cart__c = :cart.Id AND Food__c = :food.Id
            LIMIT 1
        ];

        Cart_Item__c cartItem;
        if (existingItems.isEmpty()) {
            cartItem = new Cart_Item__c(Cart__c = cart.Id, Food__c = food.Id, l_Quantity__c = quantity, Price__c = food.Price__c);
            Database.insert(cartItem, AccessLevel.SYSTEM_MODE);
        } else {
            cartItem = existingItems[0];
            cartItem.l_Quantity__c = Math.min(MAX_QUANTITY, cartItem.l_Quantity__c + quantity);
            cartItem.Price__c = food.Price__c;
            Database.update(cartItem, AccessLevel.SYSTEM_MODE);
        }
        return cartItem;
    }

    public static void requireLogin() {
        if (Auth.CommunitiesUtil.isGuestUser()) {
            throw error(LOGIN_REQUIRED);
        }
    }

    // AuraHandledException only exposes its message to Apex when setMessage is called
    public static AuraHandledException error(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        return ex;
    }

    private static Cart__c getOrCreateOpenCart() {
        Id currentUserId = UserInfo.getUserId();
        List<Cart__c> carts = [
            SELECT Id FROM Cart__c
            WHERE Status__c = 'Open' AND OwnerId = :currentUserId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (!carts.isEmpty()) {
            return carts[0];
        }
        Cart__c cart = new Cart__c(Status__c = 'Open', OwnerId = currentUserId);
        Database.insert(cart, AccessLevel.SYSTEM_MODE);
        return cart;
    }
}
