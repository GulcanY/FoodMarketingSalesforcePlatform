public with sharing class CartTriggerHandler {
    public static void sendOrderConfirmationEmails(Set<Id> cartIds) {
        List<Cart_Item__c> cartItems = [SELECT Id, l_Quantity__c, Food__r.Name, Food__r.Chef__r.Name, Food__r.Chef__r.Email__c, 
                                               Cart__r.CustomerH__r.Street_Address__c, Cart__r.CustomerH__r.City__c, 
                                               Cart__r.CustomerH__r.State__c, Cart__r.CustomerH__r.Zip_Code__c
                                        FROM Cart_Item__c
                                        WHERE Cart__c IN :cartIds];
        
        if (cartItems.isEmpty()) {
            System.debug('No cart items found for closed carts.');
            return;
        }

        Map<Id, List<Cart_Item__c>> chefToCartItemsMap = new Map<Id, List<Cart_Item__c>>();
        
        for (Cart_Item__c cartItem : cartItems) {
            Id chefId = cartItem.Food__r.Chef__r.Id;
            if (!chefToCartItemsMap.containsKey(chefId)) {
                chefToCartItemsMap.put(chefId, new List<Cart_Item__c>());
            }
            chefToCartItemsMap.get(chefId).add(cartItem);
        }
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (Id chefId : chefToCartItemsMap.keySet()) {
            List<Cart_Item__c> chefCartItems = chefToCartItemsMap.get(chefId);
            if (chefCartItems.isEmpty()) continue;
            
            Cart_Item__c firstItem = chefCartItems[0];
            String chefName = firstItem.Food__r.Chef__r.Name;
            String chefEmail = firstItem.Food__r.Chef__r.Email__c;
            String customerAddress = firstItem.Cart__r.CustomerH__r.Street_Address__c + ', ' +
                                     firstItem.Cart__r.CustomerH__r.City__c + ', ' +
                                     firstItem.Cart__r.CustomerH__r.State__c + ' ' +
                                     firstItem.Cart__r.CustomerH__r.Zip_Code__c;
            
            String emailBody = 'Dear ' + chefName + ',\n\n' +
                               'You have an order. This is the detail of your order.\n\n';
            
            for (Cart_Item__c item : chefCartItems) {
                emailBody += 'Ordered Food: ' + item.Food__r.Name + '\n' +
                             'Quantity: ' + item.l_Quantity__c + '\n\n';
            }
            
            emailBody += 'Customer Address: ' + customerAddress;
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { chefEmail });
            email.setSubject('Order Confirmation');
            email.setPlainTextBody(emailBody);
            
            emails.add(email);
        }
        
        if (!emails.isEmpty()) {
            System.debug('Sending emails: ' + emails);
            Messaging.sendEmail(emails);
        } else {
            System.debug('No emails to send.');
        }
    }
}