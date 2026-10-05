public with sharing class ItalianCuisineController {
    @AuraEnabled(cacheable=true)
    public static List<FoodCatalogService.FoodWithChefWrapper> getItalianCuisineFoods() {
        return FoodCatalogService.getAvailableFoods('Italian');
    }
}
