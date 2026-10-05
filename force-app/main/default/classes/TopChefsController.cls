public with sharing class TopChefsController {
    @AuraEnabled(cacheable=true)
    public static List<ChefWrapper> getTopChefs() {
        // Top 3 available chefs by average rating
        List<Chef__c> chefs = [
            SELECT Id, Name, AvgRate__c, Cuisine_Type__c, Image_URL__c
            FROM Chef__c
            WHERE Available__c = true
            WITH USER_MODE
            ORDER BY AvgRate__c DESC NULLS LAST
            LIMIT 3
        ];
        Map<Id, Chef__c> chefsById = new Map<Id, Chef__c>(chefs);

        // One available food per chef, used as the card's food image
        Map<Id, String> foodImageByChef = new Map<Id, String>();
        for (Food__c food : [
            SELECT Id, Chef__c, Image_URL__c
            FROM Food__c
            WHERE Chef__c IN :chefsById.keySet() AND Available__c = true AND Image_URL__c != null
            WITH USER_MODE
            ORDER BY Name
        ]) {
            if (!foodImageByChef.containsKey(food.Chef__c)) {
                foodImageByChef.put(food.Chef__c, food.Image_URL__c);
            }
        }

        List<ChefWrapper> wrappedChefs = new List<ChefWrapper>();
        for (Chef__c chef : chefs) {
            ChefWrapper wrapper = new ChefWrapper();
            wrapper.chef = chef;
            wrapper.chefImageUrl = chef.Image_URL__c;
            wrapper.foodImageUrl = foodImageByChef.get(chef.Id);
            wrappedChefs.add(wrapper);
        }
        return wrappedChefs;
    }

    public class ChefWrapper {
        @AuraEnabled public Chef__c chef;
        @AuraEnabled public String chefImageUrl;
        @AuraEnabled public String foodImageUrl;
    }
}
