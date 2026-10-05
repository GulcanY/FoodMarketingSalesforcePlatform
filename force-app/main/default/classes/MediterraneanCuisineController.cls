public with sharing class MediterraneanCuisineController {
    @AuraEnabled(cacheable=true)
    public static List<FoodCatalogService.FoodWithChefWrapper> getMediterraneanCuisineFoods() {
        return FoodCatalogService.getAvailableFoods('Mediterranean');
    }
}
