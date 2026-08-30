public without sharing class FoodCtrl {
    
    @AuraEnabled
    public static Food__c[] searchFood(String word) {

        String searchFood = '%'+word+'%';
        return [Select Id, Name, Chef__c, Available__c,Food_Location__c, Ingredients__c, Price__c, (SELECT ContentDocument.LatestPublishedVersionId FROM ContentDocumentLinks) From Food__c Where Name LIKE:searchFood];  
    }



    @AuraEnabled(cacheable=true)
    public static List<FoodWrapper> getTopOrderedFoods() {
        // Aggregate the order counts from Cart_Item__c
        List<AggregateResult> groupedResults = [
            SELECT Food__c, SUM(l_Quantity__c)
            FROM Cart_Item__c WHERE Food__c != null
            GROUP BY Food__c
            ORDER BY SUM(l_Quantity__c) DESC
            LIMIT 5
        ];
        System.debug('groupedResults --> ' + groupedResults);

        // Extract the Food__c IDs and the order counts
        List<Id> foodIds = new List<Id>();
        Map<Id, Decimal> foodOrderCountMap = new Map<Id, Decimal>();
        for (AggregateResult ar : groupedResults) {
            Id foodId = (Id) ar.get('Food__c');
            Decimal totalOrders = (Decimal) ar.get('expr0');  // 'expr0' is the default alias for the aggregated result
            foodIds.add(foodId);
            foodOrderCountMap.put(foodId, totalOrders);
        }

        // Query the Food__c records based on the aggregated results
        List<Food__c> topOrderedFoods = [SELECT Id, Name, Description__c, Price__c, Chef__c, Cuisine_Type__c
                                         FROM Food__c
                                         WHERE Id IN :foodIds];
        
        // Get the attachments for the Food__c records
        List<ContentDocumentLink> contentLinks = [SELECT ContentDocumentId, LinkedEntityId, ContentDocument.LatestPublishedVersionId 
                                                  FROM ContentDocumentLink 
                                                  WHERE LinkedEntityId IN :foodIds];

        Map<Id, String> foodToImageUrlMap = new Map<Id, String>();
        for (ContentDocumentLink link : contentLinks) {
            if (!foodToImageUrlMap.containsKey(link.LinkedEntityId)) {
                foodToImageUrlMap.put(link.LinkedEntityId, '/sfc/servlet.shepherd/version/download/' + link.ContentDocument.LatestPublishedVersionId);
            }
        }

        // Create a Map for Chef__c Ids to Names
        Set<Id> chefIds = new Set<Id>();
        for (Food__c food : topOrderedFoods) {
            if (food.Chef__c != null) {
                chefIds.add(food.Chef__c);
            }
        }

        Map<Id, String> chefMap = new Map<Id, String>();
        for (Chef__c chef : [SELECT Id, Name FROM Chef__c WHERE Id IN :chefIds]) {
            chefMap.put(chef.Id, chef.Name);
        }

        // Create the wrapper objects
        List<FoodWrapper> foodWrappers = new List<FoodWrapper>();
        for (Food__c food : topOrderedFoods) {
            String imageUrl = foodToImageUrlMap.get(food.Id);
            Decimal orderCount = foodOrderCountMap.get(food.Id);
            String chefName = chefMap.containsKey(food.Chef__c) ? chefMap.get(food.Chef__c) : '';
            foodWrappers.add(new FoodWrapper(food, imageUrl, orderCount, chefName));
        }

        return foodWrappers;
    }

    public class FoodWrapper {
        @AuraEnabled
        public Food__c food { get; set; }
        @AuraEnabled
        public String imageUrl { get; set; }
        @AuraEnabled
        public Decimal orderCount { get; set; }
        @AuraEnabled
        public String chefName { get; set; }

        public FoodWrapper(Food__c food, String imageUrl, Decimal orderCount, String chefName) {
            this.food = food;
            this.imageUrl = imageUrl;
            this.orderCount = orderCount;
            this.chefName = chefName;
        }
    }
}