public with sharing class MedCuisineController {
    @AuraEnabled(cacheable=true)
    public static List<FoodCatalogService.FoodWithChefWrapper> getMedCuisineFoods() {
        return FoodCatalogService.getAvailableFoods('Mediterranean');
    }
}
