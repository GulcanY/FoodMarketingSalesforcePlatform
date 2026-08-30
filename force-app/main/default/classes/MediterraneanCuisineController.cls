public with sharing class MediterraneanCuisineController {
    @AuraEnabled(cacheable=true)
    public static List<FoodWithChefWrapper> getMediterraneanCuisineFoods() {
        // Query to fetch required fields from Food__c and related Chef__c details
        List<Food__c> foods = [
            SELECT Id, Name, Description__c, Dietary__c, Price__c, Cuisine_Type__c, Chef__r.Name, Chef__r.Id,
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
            if (!food.Chef__r.ContentDocumentLinks.isEmpty()) {
                wrapper.chefImageUrl = '/sfc/servlet.shepherd/version/download/' + food.Chef__r.ContentDocumentLinks[0].ContentDocument.LatestPublishedVersionId;
            }
            wrappedFoods.add(wrapper);
        }
        return wrappedFoods;
    }
    
    public class FoodWithChefWrapper {
        @AuraEnabled public Food__c food;
        @AuraEnabled public String foodImageUrl;
        @AuraEnabled public String chefImageUrl;
    }
}