public without sharing class ChefCtrl {
    
    @AuraEnabled(cacheable=true)
    public static Chef__c[] searchChef(String word){

        String searchChef = '%'+word+'%';
        return [Select Id, Name__c, AvgRate__c, Pickup_Delivery_Preference__c, Social_Media_Links__c From Chef__c Where Name__c LIKE:searchChef];
       
    }


    @AuraEnabled(cacheable=true)
    public static String relatedFiles(Id chefImageId){
        List<ContentDocumentLink> contentDocumentLinks = [SELECT ContentDocument.FileExtension, ContentDocument.LatestPublishedVersion.Title, ContentDocument.LatestPublishedVersion.VersionData
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :chefImageId
                    LIMIT 1];

        String chefimageUrl;
        if(!contentDocumentLinks.isEmpty()) {
            ContentDocumentLink cdl = contentDocumentLinks[0];
            chefimageUrl = '/sfc/servlet.shepherd/version/download/' + cdl.ContentDocument.LatestPublishedVersionId;
            
        }
        return chefimageUrl;
    }


    // @AuraEnabled(cacheable=true)
    // public static List<ContentDocumentLink> getRelatedFiles(Id chefId) {
    //     List<ContentDocumentLink> contentDocumentLinks = [SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension, ContentDocument.LatestPublishedVersionId
    //                                                        FROM ContentDocumentLink 
    //                                                        WHERE LinkedEntityId IN (SELECT Id FROM Food__c WHERE Chef__c = :chefId)];
    //     return contentDocumentLinks;
    // }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getRelatedFiles(Id chefId) {
        List<Food__c> foods = [SELECT Id, Name, Price__c FROM Food__c WHERE Chef__c = :chefId];
        List<Map<String, Object>> foodDetails = new List<Map<String, Object>>();
        
        for (Food__c food : foods) {
            Map<String, Object> details = new Map<String, Object>();
            details.put('foodId', food.Id);
            details.put('foodName', food.Name);
            details.put('foodPrice', food.Price__c);

            List<ContentDocumentLink> contentDocumentLinks = [SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension, ContentDocument.LatestPublishedVersionId
                                                               FROM ContentDocumentLink 
                                                               WHERE LinkedEntityId = :food.Id];
            if (!contentDocumentLinks.isEmpty()) {
                ContentDocumentLink link = contentDocumentLinks[0];
                details.put('documentId', link.ContentDocumentId);
                details.put('documentTitle', link.ContentDocument.Title);
                details.put('latestPublishedVersionId', link.ContentDocument.LatestPublishedVersionId);
            }
            foodDetails.add(details);
        }
        return foodDetails;
    }
    

    
    @AuraEnabled(cacheable=true)
    public static Chef__c[] getAllChefs() {
        return[SELECT Id, Name__c, AvgRate__c FROM Chef__c WHERE Available__c = true];
    }
}