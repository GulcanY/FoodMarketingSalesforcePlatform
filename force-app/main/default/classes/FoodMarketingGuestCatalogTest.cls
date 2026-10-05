/**
 * Guest and customer catalog checks against the org's real data. Criteria-based
 * sharing rules are not applied to records created inside a test, so this class
 * uses SeeAllData and compares the results with the admin's view of
 * "available food of an available chef" instead of fixed counts.
 */
@isTest(SeeAllData=true)
private with sharing class FoodMarketingGuestCatalogTest {

    @isTest
    static void guestSeesExactlyThePublicCatalog() {
        User guest = [SELECT Id FROM User WHERE UserType = 'Guest' AND Profile.Name = 'Food Marketing Profile' AND IsActive = true LIMIT 1];
        Map<Id, Food__c> publicFoods = new Map<Id, Food__c>([
            SELECT Id FROM Food__c
            WHERE Cuisine_Type__c = 'Asian' AND Available__c = true AND Chef__r.Available__c = true
        ]);
        Set<String> privateValues = new Set<String>();
        for (Chef__c chef : [SELECT Email__c, Phone__c FROM Chef__c WHERE Email__c != null]) {
            privateValues.add(chef.Email__c);
            privateValues.add(chef.Phone__c);
        }

        System.runAs(guest) {
            List<FoodCatalogService.FoodWithChefWrapper> foods = FoodController.getAsianCuisineFoods();
            Set<Id> returnedIds = new Set<Id>();
            for (FoodCatalogService.FoodWithChefWrapper wrapper : foods) {
                returnedIds.add(wrapper.food.Id);
            }
            Assert.areEqual(publicFoods.keySet(), returnedIds, 'Guest must see exactly the available foods of available chefs');

            List<Chef__c> chefs = ChefCtrl.getAllChefs();
            for (Chef__c chef : chefs) {
                assertNoPrivateData(ChefDetailsController.getChefDetails(chef.Id), privateValues);
                assertNoPrivateData(ChefCtrl.getRelatedFiles(chef.Id), privateValues);
            }
            assertNoPrivateData(foods, privateValues);
            assertNoPrivateData(chefs, privateValues);
            assertNoPrivateData(TopChefsController.getTopChefs(), privateValues);
            Assert.areEqual(0, [SELECT COUNT() FROM Chef__c WHERE Available__c = false], 'Unavailable chefs must not be shared with guests');
        }
    }

    private static void assertNoPrivateData(Object response, Set<String> privateValues) {
        String json = JSON.serialize(response);
        Assert.isFalse(json.contains('Email__c') || json.contains('Phone__c'), 'Contact fields must not be returned');
        for (String value : privateValues) {
            Assert.isFalse(json.contains(value), 'Private chef data returned: ' + value);
        }
    }

    @isTest
    static void customerSeesOnlyAvailableChefs() {
        List<User> customers = [SELECT Id FROM User WHERE Profile.Name = 'Food Marketing Customer' AND IsActive = true LIMIT 1];
        if (customers.isEmpty()) {
            return; // no site customer in this org yet
        }
        Set<Id> availableChefIds = new Map<Id, Chef__c>([SELECT Id FROM Chef__c WHERE Available__c = true]).keySet();
        System.runAs(customers[0]) {
            Assert.areEqual(0, [SELECT COUNT() FROM Chef__c WHERE Available__c = false], 'Unavailable chefs must not be shared with customers');
            Assert.areEqual(0, [SELECT COUNT() FROM Food__c WHERE Chef__r.Available__c = false], 'Foods of unavailable chefs must not be shared');
            Assert.areEqual(availableChefIds, new Map<Id, Chef__c>([SELECT Id FROM Chef__c]).keySet(), 'Customers see every available chef');
            Assert.isFalse(Schema.SObjectType.Chef__c.fields.Email__c.isAccessible(), 'Customer must not read chef email');
        }
    }
}
