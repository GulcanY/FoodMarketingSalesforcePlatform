public with sharing class MiddleEasternCuisineController {
    @AuraEnabled(cacheable=true)
    public static List<FoodCatalogService.FoodWithChefWrapper> getMiddleEasternCuisineFoods() {
        return FoodCatalogService.getAvailableFoods('Middle Eastern');
    }
}
