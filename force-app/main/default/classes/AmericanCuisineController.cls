public with sharing class AmericanCuisineController {
    @AuraEnabled(cacheable=true)
    public static List<FoodCatalogService.FoodWithChefWrapper> getAmericanCuisineFoods() {
        return FoodCatalogService.getAvailableFoods('American');
    }
}
