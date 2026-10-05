public with sharing class ChefDetailsController {
    // Public chef profile: available chefs only, no contact or address fields.
    @AuraEnabled(cacheable=true)
    public static Chef__c getChefDetails(Id recordId) {
        List<Chef__c> chefs = [
            SELECT Id, Name, Name__c, AvgRate__c, Cuisine_Type__c, Bio__c, City__c, State__c,
                   Social_Media_Links__c, Pickup_Delivery_Preference__c
            FROM Chef__c
            WHERE Id = :recordId AND Available__c = true
            WITH USER_MODE
            LIMIT 1
        ];
        if (chefs.isEmpty()) {
            throw ShoppingCartController.error('Chef not found.');
        }
        return chefs[0];
    }
}
