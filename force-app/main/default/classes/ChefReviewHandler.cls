public class ChefReviewHandler {
    public static void updateChefRatings(Set<Id> chefIds) {
        List<Chef__c> chefsToUpdate = new List<Chef__c>();

        for (Id chefId : chefIds) {
            Decimal averageRating = calculateAverageRating(chefId);
            System.debug('Updating Chef: ' + chefId + ' with new Avg Rating: ' + averageRating);
            chefsToUpdate.add(new Chef__c(Id = chefId, AvgRate__c = averageRating));
        }

        // Attempt to update all affected chef records
        try {
            update chefsToUpdate;
            System.debug('Successfully updated chefs with new averages.');
        } catch (Exception e) {
            System.debug('Error updating chefs: ' + e.getMessage());
        }
    }

    private static Decimal calculateAverageRating(Id chefId) {
        Decimal totalRating = 0;
        Integer reviewCount = 0;
        List<ChefReview__c> reviews = [SELECT Rating__c FROM ChefReview__c WHERE Chef__c = :chefId];
        System.debug('Found ' + reviews.size() + ' reviews for Chef ID: ' + chefId);

        for (ChefReview__c review : reviews) {
            totalRating += Decimal.valueOf(review.Rating__c);
            reviewCount++;
        }

        Decimal averageRating = reviewCount > 0 ? totalRating / reviewCount : 0;
        System.debug('Calculated Avg Rating: ' + averageRating + ' for Chef ID: ' + chefId);

        return averageRating;
    }
}