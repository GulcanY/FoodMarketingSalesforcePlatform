public with sharing class cartDetails {
    // Fetch the most recent cart details for a given customer ID
    @AuraEnabled(cacheable=true)  // Set cacheable to false to ensure fresh data on each call
    public static Cart__c getMostRecentClosedCart() {
        List<Cart__c> carts = [
            SELECT Id, Name, Total_Amount__c, Total_Quantity__c,
                   CustomerH__r.Name, CustomerH__r.Last_Name__c, CustomerH__r.Street_Address__c,
                   CustomerH__r.City__c, CustomerH__r.State__c,CustomerH__r.Country__c, CustomerH__r.Zip_Code__c
            FROM Cart__c
            WHERE Status__c = 'Closed'
            ORDER BY CreatedDate DESC  // Ensure you're ordering by the last modified date
            LIMIT 1
        ];
        return carts.isEmpty() ? null : carts[0];
    }
}