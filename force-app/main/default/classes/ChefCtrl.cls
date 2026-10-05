/**
 * Public chef catalog for the Food Marketing site.
 * Every query runs with sharing and in USER_MODE (CRUD/FLS), only returns
 * available chefs/foods, and never selects contact fields (Email__c, Phone__c,
 * address). Image links come from Image_URL__c (see CatalogImagePublisher).
 */
public with sharing class ChefCtrl {

    @AuraEnabled(cacheable=true)
    public static Chef__c[] searchChef(String word) {
        if (String.isBlank(word)) {
            return new List<Chef__c>();
        }
        String searchChef = '%' + word.trim().replace('\\', '\\\\').replace('%', '\\%').replace('_', '\\_') + '%';
        return [
            SELECT Id, Name__c, AvgRate__c, Cuisine_Type__c, Pickup_Delivery_Preference__c, Social_Media_Links__c
            FROM Chef__c
            WHERE Name__c LIKE :searchChef AND Available__c = true
            WITH USER_MODE
            ORDER BY Name__c
            LIMIT 50
        ];
    }

    @AuraEnabled(cacheable=true)
    public static String relatedFiles(Id chefImageId) {
        if (chefImageId == null || chefImageId.getSobjectType() != Chef__c.SObjectType) {
            return null;
        }
        List<Chef__c> chefs = [
            SELECT Image_URL__c FROM Chef__c
            WHERE Id = :chefImageId AND Available__c = true
            WITH USER_MODE
            LIMIT 1
        ];
        return chefs.isEmpty() ? null : chefs[0].Image_URL__c;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getRelatedFiles(Id chefId) {
        List<Map<String, Object>> foodDetails = new List<Map<String, Object>>();
        if (chefId == null) {
            return foodDetails;
        }
        List<Food__c> foods = [
            SELECT Id, Name, Price__c, Image_URL__c
            FROM Food__c
            WHERE Chef__c = :chefId AND Available__c = true AND Chef__r.Available__c = true
            WITH USER_MODE
            ORDER BY Name
            LIMIT 100
        ];
        for (Food__c food : foods) {
            foodDetails.add(new Map<String, Object>{
                'foodId' => food.Id,
                'foodName' => food.Name,
                'foodPrice' => food.Price__c,
                'imageUrl' => food.Image_URL__c
            });
        }
        return foodDetails;
    }

    @AuraEnabled(cacheable=true)
    public static Chef__c[] getAllChefs() {
        return [
            SELECT Id, Name__c, AvgRate__c, Cuisine_Type__c
            FROM Chef__c
            WHERE Available__c = true
            WITH USER_MODE
            ORDER BY Name__c
            LIMIT 200
        ];
    }
}
