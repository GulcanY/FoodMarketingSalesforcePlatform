public with sharing class ChefDetailsController {
    // Method to fetch chef details
    @AuraEnabled(cacheable=true)
    public static Chef__c getChefDetails(Id recordId) {
        try {
            // Log the incoming record ID to verify it's being passed correctly
            System.debug('Fetching details for Chef with ID: ' + recordId);

            // Execute the SOQL query and store the result
            Chef__c chef = [
                SELECT Id, Name, Name__c, AvgRate__c, Cuisine_Type__c, Bio__c, Email__c,
                       Phone__c, State__c, Zip_Code__c, Social_Media_Links__c,
                       Pickup_Delivery_Preference__c
                FROM Chef__c
                WHERE Id = :recordId
                LIMIT 1
            ];

            // Log the retrieved Chef record to verify the data
            System.debug('Retrieved Chef details: ' + chef);

            return chef;
        } catch (Exception e) {
            // Log the exception details if the query or other operations fail
            System.debug('Error fetching Chef details: ' + e.getMessage());
            throw new AuraHandledException('Unable to fetch Chef details: ' + e.getMessage());
        }
    }
}