public with sharing class ChefController {
    @AuraEnabled(cacheable=true)
    public static List<Chef__c> getChefs() {
        try {
        return [SELECT Id, Name__c FROM Chef__c ORDER BY Name ASC];
    } catch (Exception e) {
        throw new AuraHandledException('Failed to fetch chefs: ' + e.getMessage());
    }
}
}