trigger CatalogChefAvailabilityTrigger on Chef__c (after update) {
    Set<Id> changed = new Set<Id>();
    for (Chef__c chef : Trigger.new) {
        if (chef.Available__c != Trigger.oldMap.get(chef.Id).Available__c) {
            changed.add(chef.Id);
        }
    }
    if (!changed.isEmpty()) {
        CatalogImagePublisher.syncChefs(changed);
    }
}
