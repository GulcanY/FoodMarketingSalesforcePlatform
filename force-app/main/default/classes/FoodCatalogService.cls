/**
 * Shared, public-safe food catalog used by the cuisine controllers.
 * Only available foods of available chefs are returned, queries run in
 * USER_MODE (sharing + CRUD/FLS), and the chef relationship exposes only Name.
 */
public with sharing class FoodCatalogService {

    public static List<FoodWithChefWrapper> getAvailableFoods(String cuisineType) {
        List<Food__c> foods = [
            SELECT Id, Name, Description__c, Dietary__c, Price__c, Cuisine_Type__c, Chef__c, Chef__r.Name,
                   Ingredients__c, Prep_Time__c, Servings__c, Spice_Level__c, Image_URL__c, Chef__r.Image_URL__c
            FROM Food__c
            WHERE Cuisine_Type__c = :cuisineType
              AND Available__c = true
              AND Chef__r.Available__c = true
            WITH USER_MODE
            ORDER BY Name
            LIMIT 200
        ];

        List<FoodWithChefWrapper> wrappedFoods = new List<FoodWithChefWrapper>();
        for (Food__c food : foods) {
            FoodWithChefWrapper wrapper = new FoodWithChefWrapper();
            wrapper.food = food;
            wrapper.foodImageUrl = food.Image_URL__c;
            wrapper.chefImageUrl = food.Chef__r.Image_URL__c;
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
