public with sharing class IndianCuisineController {
    @AuraEnabled(cacheable=true)
    public static List<FoodCatalogService.FoodWithChefWrapper> getIndianCuisineFoods() {
        return FoodCatalogService.getAvailableFoods('Indian');
    }
}
