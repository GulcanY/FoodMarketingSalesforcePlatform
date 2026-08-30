trigger CartTrigger on Cart__c (before insert, after update) {

    Set<Id> closedCartIds = new Set<Id>();
    
    // Only collect IDs of carts that were just closed
    for (Cart__c cart : Trigger.new) {
        if (cart.Status__c == 'Closed' && Trigger.oldMap.get(cart.Id).Status__c != 'Closed') {
            closedCartIds.add(cart.Id);
        }
    }
    
    if (!closedCartIds.isEmpty()) {
        CartTriggerHandler.sendOrderConfirmationEmails(closedCartIds);
    }

}