trigger ChefReviewTrigger on ChefReview__c (after insert, after update, after delete) {
    Set<Id> chefIds = new Set<Id>();

    // Collect chef IDs from inserted or updated reviews
    if (Trigger.isInsert || Trigger.isUpdate) {
        for (ChefReview__c review : Trigger.new) {
            chefIds.add(review.Chef__c);
        }
    }

    // Collect chef IDs from deleted reviews
    if (Trigger.isDelete) {
        for (ChefReview__c review : Trigger.old) {
            chefIds.add(review.Chef__c);
        }
    }

    // Trigger the update process if any chef IDs were collected
    if (!chefIds.isEmpty()) {
        AvgRatingPopulation.updateChefRatings(chefIds);
    }
}