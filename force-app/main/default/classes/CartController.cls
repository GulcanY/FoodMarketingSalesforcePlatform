public with sharing class CartController {
    @AuraEnabled(cacheable=true)
    public static List<CartItemWrapper> getCartItems() {
        List<Cart_Item__c> cartItems = [
            SELECT Id, Food__c, Food__r.Name, Food__r.Price__c, l_Quantity__c
            FROM Cart_Item__c
            WHERE Cart__r.Status__c = 'Open'
        ];

        Set<Id> foodIds = new Set<Id>();
        for (Cart_Item__c item : cartItems) {
            foodIds.add(item.Food__c);
        }

        Map<Id, String> foodImageUrls = getImageUrlsForFoods(foodIds);

        List<CartItemWrapper> wrappedItems = new List<CartItemWrapper>();
        for (Cart_Item__c item : cartItems) {
            CartItemWrapper wrapper = new CartItemWrapper();
            wrapper.cartItem = item;
            wrapper.foodImageUrl = foodImageUrls.get(item.Food__c);
            wrappedItems.add(wrapper);
        }

        return wrappedItems;
    }

    private static Map<Id, String> getImageUrlsForFoods(Set<Id> foodIds) {
        Map<Id, String> imageUrls = new Map<Id, String>();

        List<ContentDocumentLink> contentLinks = [
            SELECT ContentDocument.LatestPublishedVersionId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :foodIds
        ];

        for (ContentDocumentLink link : contentLinks) {
            String imageUrl = '/sfc/servlet.shepherd/version/download/' + link.ContentDocument.LatestPublishedVersionId;
            imageUrls.put(link.LinkedEntityId, imageUrl);
        }

        return imageUrls;
    }

    @AuraEnabled
    public static void updateCartItem(Id cartItemId, Integer quantity) {
        Cart_Item__c cartItem = [SELECT Id FROM Cart_Item__c WHERE Id = :cartItemId LIMIT 1];
        cartItem.l_Quantity__c = quantity;
        update cartItem;
    }

    @AuraEnabled
    public static void removeCartItem(Id cartItemId) {
        Cart_Item__c cartItem = [SELECT Id FROM Cart_Item__c WHERE Id = :cartItemId LIMIT 1];
        delete cartItem;
    }

    public class CartItemWrapper {
        @AuraEnabled public Cart_Item__c cartItem;
        @AuraEnabled public String foodImageUrl;
    }
}