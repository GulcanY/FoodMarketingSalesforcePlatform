trigger CatalogFoodAvailabilityTrigger on Food__c (after update) {
    Set<Id> changed = new Set<Id>();
    for (Food__c food : Trigger.new) {
        if (food.Available__c != Trigger.oldMap.get(food.Id).Available__c) {
            changed.add(food.Id);
        }
    }
    if (!changed.isEmpty()) {
        CatalogImagePublisher.sync(changed);
    }
}
