public with sharing class MedCuisineController {
    @AuraEnabled(cacheable=true)
    public static List<FoodWithChefWrapper> getMedCuisineFoods() {
        // Query to fetch required fields from Food__c and related Chef__c details
       List<Food__c> foods = [
            SELECT Id, Name, Description__c, Dietary__c, Price__c, Cuisine_Type__c, Chef__r.Name, Chef__r.Id,
                   Ingredients__c, Prep_Time__c, Servings__c, Spice_Level__c,
                   (SELECT ContentDocument.LatestPublishedVersionId FROM ContentDocumentLinks)
            FROM Food__c 
            WHERE Cuisine_Type__c = 'Mediterranean'
        ];
    
        // Prepare data to return
       List<FoodWithChefWrapper> wrappedFoods = new List<FoodWithChefWrapper>();
        for (Food__c food : foods) {
            FoodWithChefWrapper wrapper = new FoodWithChefWrapper();
            wrapper.food = food;
            if (!food.ContentDocumentLinks.isEmpty()) {
                wrapper.foodImageUrl = '/sfc/servlet.shepherd/version/download/' + food.ContentDocumentLinks[0].ContentDocument.LatestPublishedVersionId;
            }
            if (food.Chef__r != null) {
                List<ContentDocumentLink> chefLinks = [SELECT ContentDocument.LatestPublishedVersionId 
                                                       FROM ContentDocumentLink 
                                                       WHERE LinkedEntityId = :food.Chef__r.Id];
                System.debug('Chef ContentDocumentLinks Count: ' + chefLinks.size());
                if (!chefLinks.isEmpty()) {
                    wrapper.chefImageUrl = '/sfc/servlet.shepherd/version/download/' + chefLinks[0].ContentDocument.LatestPublishedVersionId;
                    System.debug('Chef Image URL for ' + food.Chef__r.Name + ': ' + wrapper.chefImageUrl);
                } else {
                    System.debug('No Chef Image URL for ' + food.Chef__r.Name);
                }
            } else {
                System.debug('No Chef associated with food: ' + food.Id);
            }
            wrappedFoods.add(wrapper);
        }
        System.debug('Total wrapped foods with chef images: ' + wrappedFoods.size());
        return wrappedFoods;
    }
    
    public class FoodWithChefWrapper {
        @AuraEnabled public Food__c food;
        @AuraEnabled public String foodImageUrl;
        @AuraEnabled public String chefImageUrl;
    }
}