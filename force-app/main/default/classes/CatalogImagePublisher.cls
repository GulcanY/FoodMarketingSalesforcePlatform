/**
 * Publishes catalog images for the Home2Home (Food Marketing) site.
 * Site guests cannot read Salesforce Files, so image files attached to public
 * catalog records get a public file link (ContentDistribution) whose download URL
 * is stored in Image_URL__c. Only available chefs and available foods of available
 * chefs are public: when a record is not public its links are deleted (revoked)
 * and Image_URL__c is cleared. Non-image attachments are never published.
 */
public without sharing class CatalogImagePublisher {

    private static final Set<String> IMAGE_TYPES = new Set<String>{ 'PNG', 'JPG', 'JPEG', 'GIF', 'WEBP' };
    private static final Integer MAX_IMAGE_BYTES = 5000000;

    // ContentDocumentLink trigger: a file was attached to a record
    public static void publish(List<ContentDocumentLink> links) {
        Set<Id> recordIds = new Set<Id>();
        for (ContentDocumentLink link : links) {
            if (isCatalogRecord(link.LinkedEntityId)) {
                recordIds.add(link.LinkedEntityId);
            }
        }
        sync(recordIds);
    }

    // ContentVersion trigger: a new version of an attached file was uploaded
    public static void publishNewVersions(List<ContentVersion> versions) {
        Set<Id> documentIds = new Set<Id>();
        for (ContentVersion version : versions) {
            documentIds.add(version.ContentDocumentId);
        }
        Set<Id> recordIds = new Set<Id>();
        if (!documentIds.isEmpty()) {
            for (ContentDocumentLink link : [
                SELECT LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :documentIds
            ]) {
                if (isCatalogRecord(link.LinkedEntityId)) {
                    recordIds.add(link.LinkedEntityId);
                }
            }
        }
        sync(recordIds);
    }

    // Chef__c trigger: availability changed, so the chef's foods change visibility too
    public static void syncChefs(Set<Id> chefIds) {
        Set<Id> recordIds = new Set<Id>(chefIds);
        for (Food__c food : [SELECT Id FROM Food__c WHERE Chef__c IN :chefIds]) {
            recordIds.add(food.Id);
        }
        sync(recordIds);
    }

    // Brings public links and Image_URL__c in line with each record's visibility
    public static void sync(Set<Id> recordIds) {
        recordIds.remove(null);
        if (recordIds.isEmpty()) {
            return;
        }
        Map<Id, Boolean> isPublicById = new Map<Id, Boolean>();
        Map<Id, String> currentUrlById = new Map<Id, String>();
        for (Chef__c chef : [SELECT Id, Available__c, Image_URL__c FROM Chef__c WHERE Id IN :recordIds]) {
            isPublicById.put(chef.Id, chef.Available__c);
            currentUrlById.put(chef.Id, chef.Image_URL__c);
        }
        for (Food__c food : [SELECT Id, Available__c, Chef__r.Available__c, Image_URL__c FROM Food__c WHERE Id IN :recordIds]) {
            isPublicById.put(food.Id, food.Available__c && food.Chef__r.Available__c);
            currentUrlById.put(food.Id, food.Image_URL__c);
        }
        if (isPublicById.isEmpty()) {
            return;
        }

        // latest image version per record, and every version id per record (for revocation)
        Map<Id, Id> recordIdByDocument = new Map<Id, Id>();
        for (ContentDocumentLink link : [
            SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :isPublicById.keySet()
        ]) {
            recordIdByDocument.put(link.ContentDocumentId, link.LinkedEntityId);
        }
        Map<Id, ContentVersion> imageByRecord = new Map<Id, ContentVersion>();
        Map<Id, Id> recordIdByVersion = new Map<Id, Id>();
        if (!recordIdByDocument.isEmpty()) {
            for (ContentVersion version : [
                SELECT Id, Title, FileType, ContentSize, ContentDocumentId, IsLatest
                FROM ContentVersion
                WHERE ContentDocumentId IN :recordIdByDocument.keySet()
            ]) {
                Id recordId = recordIdByDocument.get(version.ContentDocumentId);
                recordIdByVersion.put(version.Id, recordId);
                Boolean isImage = IMAGE_TYPES.contains(version.FileType) && version.ContentSize <= MAX_IMAGE_BYTES;
                if (version.IsLatest && isImage && !imageByRecord.containsKey(recordId)) {
                    imageByRecord.put(recordId, version);
                }
            }
        }

        Map<Id, ContentDistribution> existingByVersion = new Map<Id, ContentDistribution>();
        List<ContentDistribution> toRevoke = new List<ContentDistribution>();
        if (!recordIdByVersion.isEmpty()) {
            for (ContentDistribution distribution : [
                SELECT Id, ContentVersionId FROM ContentDistribution WHERE ContentVersionId IN :recordIdByVersion.keySet()
            ]) {
                // keep only the link of the record's current image; links of hidden records
                // and of older file versions are revoked
                Id recordId = recordIdByVersion.get(distribution.ContentVersionId);
                ContentVersion current = imageByRecord.get(recordId);
                if (isPublicById.get(recordId) && current != null && current.Id == distribution.ContentVersionId) {
                    existingByVersion.put(distribution.ContentVersionId, distribution);
                } else {
                    toRevoke.add(distribution);
                }
            }
        }
        delete toRevoke;

        List<ContentDistribution> toCreate = new List<ContentDistribution>();
        for (Id recordId : imageByRecord.keySet()) {
            ContentVersion version = imageByRecord.get(recordId);
            if (isPublicById.get(recordId) && !existingByVersion.containsKey(version.Id)) {
                toCreate.add(new ContentDistribution(
                    // unique name: a link revoked earlier in the same transaction still blocks its old name
                    Name = version.Title.left(60) + ' ' + String.valueOf(Math.abs(Crypto.getRandomLong())).left(12),
                    ContentVersionId = version.Id,
                    PreferencesAllowViewInBrowser = true,
                    PreferencesAllowOriginalDownload = true,
                    PreferencesLinkLatestVersion = true,
                    PreferencesNotifyOnVisit = false,
                    PreferencesPasswordRequired = false
                ));
            }
        }
        insert toCreate;

        Map<Id, String> urlByVersion = new Map<Id, String>();
        if (!imageByRecord.isEmpty()) {
            for (ContentDistribution distribution : [
                SELECT ContentVersionId, ContentDownloadUrl FROM ContentDistribution
                WHERE ContentVersionId IN :new Map<Id, ContentVersion>(imageByRecord.values()).keySet()
            ]) {
                urlByVersion.put(distribution.ContentVersionId, distribution.ContentDownloadUrl);
            }
        }

        List<SObject> changed = new List<SObject>();
        for (Id recordId : isPublicById.keySet()) {
            ContentVersion image = imageByRecord.get(recordId);
            String url = isPublicById.get(recordId) && image != null ? urlByVersion.get(image.Id) : null;
            if (url != currentUrlById.get(recordId)) {
                SObject record = recordId.getSobjectType().newSObject(recordId);
                record.put('Image_URL__c', url);
                changed.add(record);
            }
        }
        changed.sort();
        update changed;
    }

    private static Boolean isCatalogRecord(Id recordId) {
        if (recordId == null) {
            return false;
        }
        SObjectType type = recordId.getSobjectType();
        return type == Food__c.SObjectType || type == Chef__c.SObjectType;
    }
}
