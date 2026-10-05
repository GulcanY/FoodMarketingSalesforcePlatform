public with sharing class MexicanCuisineController {
    @AuraEnabled(cacheable=true)
    public static List<FoodCatalogService.FoodWithChefWrapper> getMexicanCuisineFoods() {
        return FoodCatalogService.getAvailableFoods('Mexican');
    }
}
