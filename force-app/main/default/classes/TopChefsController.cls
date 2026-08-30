public with sharing class TopChefsController {
    @AuraEnabled(cacheable=true)
    public static List<ChefWrapper> getTopChefs() {
        // Query to fetch top 8 chefs based on average rating
        List<Chef__c> chefs = [
            SELECT Id, Name, AvgRate__c, Cuisine_Type__c,
                   (SELECT ContentDocument.LatestPublishedVersionId FROM ContentDocumentLinks)
            FROM Chef__c
            ORDER BY AvgRate__c DESC
            LIMIT 3
        ];

        // Prepare data to return
        List<ChefWrapper> wrappedChefs = new List<ChefWrapper>();
        Set<Id> chefIds = new Set<Id>();
        for (Chef__c chef : chefs) {
            ChefWrapper wrapper = new ChefWrapper();
            wrapper.chef = chef;

            // Get the chef image
            if (!chef.ContentDocumentLinks.isEmpty()) {
                wrapper.chefImageUrl = '/sfc/servlet.shepherd/version/download/' + chef.ContentDocumentLinks[0].ContentDocument.LatestPublishedVersionId;
            }

            wrappedChefs.add(wrapper);
            chefIds.add(chef.Id);
        }

        // Query to fetch the most popular food for each chef
        List<Food__c> foods = [
            SELECT Id, Name, Chef__c,
                   (SELECT ContentDocument.LatestPublishedVersionId FROM ContentDocumentLinks)
            FROM Food__c
            WHERE Chef__c IN :chefIds
            
        ];

        Map<Id, String> chefToFoodImageMap = new Map<Id, String>();
        for (Food__c food : foods) {
            if (!food.ContentDocumentLinks.isEmpty() && !chefToFoodImageMap.containsKey(food.Chef__c)) {
                chefToFoodImageMap.put(food.Chef__c, '/sfc/servlet.shepherd/version/download/' + food.ContentDocumentLinks[0].ContentDocument.LatestPublishedVersionId);
            }
        }

        // Attach food image URLs to the respective chef wrappers
        for (ChefWrapper wrapper : wrappedChefs) {
            if (chefToFoodImageMap.containsKey(wrapper.chef.Id)) {
                wrapper.foodImageUrl = chefToFoodImageMap.get(wrapper.chef.Id);
            }
        }

        return wrappedChefs;
    }

    public class ChefWrapper {
        @AuraEnabled public Chef__c chef;
        @AuraEnabled public String chefImageUrl;
        @AuraEnabled public String foodImageUrl;
    }
}