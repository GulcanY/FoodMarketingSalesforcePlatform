public with sharing class FoodController {
    @AuraEnabled(cacheable=true)
    public static List<FoodCatalogService.FoodWithChefWrapper> getAsianCuisineFoods() {
        return FoodCatalogService.getAvailableFoods('Asian');
    }

    // Home page carousel: name, cuisine and public image of available foods only
    @AuraEnabled(cacheable=true)
    public static List<CarouselSlide> getCarouselFoods() {
        List<CarouselSlide> slides = new List<CarouselSlide>();
        for (Food__c food : [
            SELECT Id, Name, Cuisine_Type__c, Image_URL__c
            FROM Food__c
            WHERE Available__c = true AND Chef__r.Available__c = true AND Image_URL__c != null
            WITH USER_MODE
            ORDER BY Name
            LIMIT 12
        ]) {
            CarouselSlide slide = new CarouselSlide();
            slide.id = food.Id;
            slide.name = food.Name;
            slide.cuisine = food.Cuisine_Type__c;
            slide.imageUrl = food.Image_URL__c;
            slides.add(slide);
        }
        return slides;
    }

    public class CarouselSlide {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String cuisine;
        @AuraEnabled public String imageUrl;
    }
}
