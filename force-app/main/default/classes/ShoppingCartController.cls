public with sharing class ShoppingCartController {
    
    @AuraEnabled
    public static Cart_Item__c addToCart(String foodId, Integer quantity, Decimal price) {
        // Get the current user ID
        Id currentUserId = UserInfo.getUserId();
        System.debug('Current User ID: ' + currentUserId);
        System.debug('Received Food ID: ' + foodId);
        System.debug('Received Quantity: ' + quantity);
        System.debug('Received Price: ' + price);

        // Check if an open cart exists for the current user
        List<Cart__c> carts = [SELECT Id FROM Cart__c WHERE Status__c = 'Open' AND OwnerId = :currentUserId LIMIT 1];

        Cart__c cart;
        if (carts.isEmpty()) {
            // Create a new cart if no open cart exists for the user
            cart = new Cart__c(Status__c = 'Open', OwnerId = currentUserId);
            insert cart;
        } else {
            // Use the existing open cart
            cart = carts[0];
        }

        // Create new Cart Item
        Cart_Item__c cartItem = new Cart_Item__c();
        cartItem.Food__c = foodId;
        cartItem.l_Quantity__c = quantity;
        cartItem.Price__c = price;
        cartItem.Cart__c = cart.Id;
        insert cartItem;
      
        return cartItem;
    }
}