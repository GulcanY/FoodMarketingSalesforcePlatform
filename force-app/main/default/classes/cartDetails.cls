public with sharing class cartDetails {

    @AuraEnabled(cacheable=true)
    public static Cart__c getMostRecentClosedCart() {
        List<Cart__c> carts = [
            SELECT Id, Name, Total_Amount__c, Total_Quantity__c,
                   CustomerH__r.Name,
                   CustomerH__r.Last_Name__c,
                   CustomerH__r.Street_Address__c,
                   CustomerH__r.City__c,
                   CustomerH__r.State__c,
                   CustomerH__r.Country__c,
                   CustomerH__r.Zip_Code__c
            FROM Cart__c
            WHERE Status__c = 'Closed'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        return carts.isEmpty() ? null : carts[0];
    }

    @AuraEnabled(cacheable=true)
    public static Cart__c getCartDetails() {
        return getMostRecentClosedCart();
    }
}