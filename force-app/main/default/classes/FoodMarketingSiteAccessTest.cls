/**
 * Access tests for the Food Marketing site, run as the real site guest user and
 * as a Customer Community Plus user with the Food_Marketing_Customer permission set.
 */
@isTest
private with sharing class FoodMarketingSiteAccessTest {

    private static final String CHEF_EMAIL = 'private.chef@example.com';
    private static final String CHEF_PHONE = '(555) 999-0000';
    // 1x1 transparent PNG
    private static final String PNG_BASE64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

    @TestSetup
    static void setupCatalog() {
        Chef__c openChef = new Chef__c(Name = 'Open Chef', Name__c = 'Open Chef', Email__c = CHEF_EMAIL,
            Phone__c = CHEF_PHONE, Available__c = true, AvgRate__c = 4.5, Cuisine_Type__c = 'Asian',
            Zip_Code__c = '99999', Street_Address__c = '1 Private Street');
        Chef__c closedChef = new Chef__c(Name = 'Closed Chef', Name__c = 'Closed Chef', Email__c = 'closed.chef@example.com',
            Phone__c = '(555) 999-0001', Available__c = false, AvgRate__c = 5, Cuisine_Type__c = 'Asian');
        insert new List<Chef__c>{ openChef, closedChef };

        insert new List<Food__c>{
            new Food__c(Name = 'Visible Noodles', Chef__c = openChef.Id, Cuisine_Type__c = 'Asian', Available__c = true, Price__c = 10),
            new Food__c(Name = 'Hidden Dumplings', Chef__c = openChef.Id, Cuisine_Type__c = 'Asian', Available__c = false, Price__c = 9),
            new Food__c(Name = 'Closed Chef Curry', Chef__c = closedChef.Id, Cuisine_Type__c = 'Asian', Available__c = true, Price__c = 8)
        };

        insert new List<ContentVersion>{
            new ContentVersion(Title = 'open-chef', PathOnClient = 'open-chef.png',
                VersionData = EncodingUtil.base64Decode(PNG_BASE64), FirstPublishLocationId = openChef.Id),
            new ContentVersion(Title = 'closed-chef', PathOnClient = 'closed-chef.png',
                VersionData = EncodingUtil.base64Decode(PNG_BASE64), FirstPublishLocationId = closedChef.Id),
            new ContentVersion(Title = 'secret-notes', PathOnClient = 'secret-notes.txt',
                VersionData = Blob.valueOf('private'), FirstPublishLocationId = openChef.Id)
        };
    }

    private static User guestUser() {
        return [SELECT Id FROM User WHERE UserType = 'Guest' AND Profile.Name = 'Food Marketing Profile' AND IsActive = true LIMIT 1];
    }

    private static Chef__c chef(String name) {
        return [SELECT Id FROM Chef__c WHERE Name__c = :name];
    }

    private static Food__c food(String name) {
        return [SELECT Id FROM Food__c WHERE Name = :name];
    }

    private static void assertNoContactData(Object response) {
        String json = JSON.serialize(response);
        Assert.isFalse(json.contains(CHEF_EMAIL), 'Chef email must not be returned: ' + json);
        Assert.isFalse(json.contains(CHEF_PHONE), 'Chef phone must not be returned: ' + json);
        Assert.isFalse(json.contains('Email__c') || json.contains('Phone__c'), 'Contact fields must not be returned: ' + json);
        Assert.isFalse(json.contains('99999') || json.contains('Private Street'), 'Address must not be returned: ' + json);
    }

    @isTest
    static void guestCannotReadChefContactFieldsOrUnavailableImages() {
        Id closedChefId = chef('Closed Chef').Id;
        System.runAs(guestUser()) {
            Assert.isFalse(Schema.SObjectType.Chef__c.fields.Email__c.isAccessible(), 'Guest must not read chef email');
            Assert.isFalse(Schema.SObjectType.Chef__c.fields.Phone__c.isAccessible(), 'Guest must not read chef phone');
            Assert.isFalse(Schema.SObjectType.Chef__c.fields.Zip_Code__c.isAccessible(), 'Guest must not read chef zip code');
            Assert.isFalse(Schema.SObjectType.Chef__c.fields.Street_Address__c.isAccessible(), 'Guest must not read chef address');
            Assert.isNull(ChefCtrl.relatedFiles(closedChefId), 'Unavailable chef image must not be returned');
            Assert.isTrue(ChefCtrl.getRelatedFiles(closedChefId).isEmpty());
            Assert.isTrue(ChefCtrl.searchChef('Closed').isEmpty());
            try {
                ChefDetailsController.getChefDetails(closedChefId);
                Assert.fail('Unavailable chef must not be returned');
            } catch (AuraHandledException e) {
                Assert.areEqual('Chef not found.', e.getMessage());
            }
        }
    }

    @isTest
    static void catalogReturnsImagesAndNoContactDataForAdmin() {
        Id openChefId = chef('Open Chef').Id;
        List<FoodCatalogService.FoodWithChefWrapper> foods = FoodController.getAsianCuisineFoods();
        Assert.areEqual(1, foods.size(), 'Only available foods of available chefs');
        Assert.areEqual('Visible Noodles', foods[0].food.Name);
        Assert.isTrue(foods[0].chefImageUrl.startsWith('https://'), 'Chef image should be a public file link');
        assertNoContactData(foods);

        Assert.areEqual(1, ChefCtrl.getAllChefs().size());
        assertNoContactData(ChefCtrl.getAllChefs());
        assertNoContactData(ChefCtrl.searchChef('Chef'));
        Assert.isTrue(ChefCtrl.searchChef(' ').isEmpty());
        Assert.isTrue(ChefCtrl.relatedFiles(openChefId).startsWith('https://'), 'Chef image link is returned');
        Assert.areEqual(1, [SELECT COUNT() FROM ContentDistribution], 'Only the available chef image gets a public link (not the closed chef image or the text file)');
        Assert.isNull([SELECT Image_URL__c FROM Chef__c WHERE Name__c = 'Closed Chef'].Image_URL__c);
        Assert.areEqual(1, ChefCtrl.getRelatedFiles(openChefId).size());
        assertNoContactData(ChefDetailsController.getChefDetails(openChefId));

        List<TopChefsController.ChefWrapper> topChefs = TopChefsController.getTopChefs();
        Assert.areEqual(1, topChefs.size());
        Assert.isNotNull(topChefs[0].chefImageUrl);
        assertNoContactData(topChefs);
    }

    @isTest
    static void imageLinksFollowAvailability() {
        Chef__c openChef = [SELECT Id, Image_URL__c FROM Chef__c WHERE Name__c = 'Open Chef'];
        Assert.isNotNull(openChef.Image_URL__c);
        Food__c noodles = food('Visible Noodles');
        insert new ContentVersion(Title = 'noodles', PathOnClient = 'noodles.png',
            VersionData = EncodingUtil.base64Decode(PNG_BASE64), FirstPublishLocationId = noodles.Id);
        Assert.isNotNull([SELECT Image_URL__c FROM Food__c WHERE Id = :noodles.Id].Image_URL__c, 'Available food image is published');
        Assert.areEqual(2, [SELECT COUNT() FROM ContentDistribution]);
        List<FoodController.CarouselSlide> slides = FoodController.getCarouselFoods();
        Assert.areEqual(1, slides.size(), 'Carousel shows available foods with images');
        Assert.areEqual('Visible Noodles', slides[0].name);
        Assert.isTrue(slides[0].imageUrl.startsWith('https://'));

        Test.startTest();
        noodles.Available__c = false;
        update noodles;
        Assert.isNull([SELECT Image_URL__c FROM Food__c WHERE Id = :noodles.Id].Image_URL__c, 'Closed food link is revoked');
        Assert.isTrue(FoodController.getCarouselFoods().isEmpty(), 'Closed foods leave the carousel');
        Assert.areEqual(1, [SELECT COUNT() FROM ContentDistribution]);

        openChef.Available__c = false;
        update openChef;
        Assert.isNull([SELECT Image_URL__c FROM Chef__c WHERE Id = :openChef.Id].Image_URL__c, 'Closed chef link is revoked');
        Assert.areEqual(0, [SELECT COUNT() FROM ContentDistribution]);

        openChef.Available__c = true;
        update openChef;
        noodles.Available__c = true;
        update noodles;
        Test.stopTest();
        Assert.isNotNull([SELECT Image_URL__c FROM Chef__c WHERE Id = :openChef.Id].Image_URL__c, 'Reopened chef is published again');
        Assert.isNotNull([SELECT Image_URL__c FROM Food__c WHERE Id = :noodles.Id].Image_URL__c, 'Reopened food is published again');
        Assert.areEqual(2, [SELECT COUNT() FROM ContentDistribution]);
    }

    @isTest
    static void newImageVersionReplacesThePublicLink() {
        Chef__c openChef = [SELECT Id, Image_URL__c FROM Chef__c WHERE Name__c = 'Open Chef'];
        Id documentId = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :openChef.Id AND ContentDocument.Title = 'open-chef'].ContentDocumentId;
        Test.startTest();
        insert new ContentVersion(ContentDocumentId = documentId, Title = 'open-chef-v2', PathOnClient = 'open-chef-v2.png',
            VersionData = EncodingUtil.base64Decode(PNG_BASE64));
        Test.stopTest();
        String newUrl = [SELECT Image_URL__c FROM Chef__c WHERE Id = :openChef.Id].Image_URL__c;
        Assert.isNotNull(newUrl);
        Assert.areNotEqual(openChef.Image_URL__c, newUrl, 'Link points to the new version');
        List<ContentDistribution> links = [SELECT ContentVersion.IsLatest FROM ContentDistribution];
        Assert.areEqual(1, links.size(), 'Old version link is revoked');
        Assert.isTrue(links[0].ContentVersion.IsLatest);
    }

    @isTest
    static void guestCannotUseCart() {
        Id foodId = food('Visible Noodles').Id;
        System.runAs(guestUser()) {
            try {
                ShoppingCartController.addToCart(foodId, 1, 1);
                Assert.fail('Guest must not add to cart');
            } catch (AuraHandledException e) {
                Assert.areEqual(ShoppingCartController.LOGIN_REQUIRED, e.getMessage());
            }
        }
        Assert.areEqual(0, [SELECT COUNT() FROM Cart_Item__c]);
    }

    @isTest
    static void customerManagesOnlyOwnCartWithServerPrices() {
        List<User> customers = createCustomers(2);
        Id foodId = food('Visible Noodles').Id;
        Id hiddenFoodId = food('Hidden Dumplings').Id;
        Id cartItemId;

        Test.startTest();
        System.runAs(customers[0]) {
            List<FoodCatalogService.FoodWithChefWrapper> foods = FoodController.getAsianCuisineFoods();
            Assert.areEqual(1, foods.size());
            assertNoContactData(foods);
            Assert.isFalse(Schema.SObjectType.Chef__c.fields.Email__c.isAccessible(), 'Customer must not read chef email');

            // client price is ignored, the Food__c price is used
            cartItemId = ShoppingCartController.addToCart(foodId, 2, 0.01).Id;
            ShoppingCartController.addToCart(foodId, 1, 0.01);
            List<CartController.CartItemWrapper> items = CartController.getCartItems();
            Assert.areEqual(1, items.size());
            Assert.areEqual(10, items[0].cartItem.Price__c);
            Assert.areEqual(3, items[0].cartItem.l_Quantity__c);

            CartController.updateCartItem(cartItemId, 5);
            Assert.areEqual(5, CartController.getCartItems()[0].cartItem.l_Quantity__c);

            try {
                ShoppingCartController.addToCart(hiddenFoodId, 1, 1);
                Assert.fail('Unavailable food must not be added');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e);
            }
        }

        System.runAs(customers[1]) {
            Assert.isTrue(CartController.getCartItems().isEmpty(), 'Other customers must not see the cart');
            try {
                CartController.removeCartItem(cartItemId);
                Assert.fail('Other customers must not change the cart');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e);
            }
        }

        System.runAs(customers[0]) {
            CartController.updateCartItem(cartItemId, 0);
            Assert.isTrue(CartController.getCartItems().isEmpty(), 'Quantity 0 removes the item');
        }
        Test.stopTest();
    }

    @isTest
    static void cuisineControllersReturnOnlyTheirCuisine() {
        Chef__c openChef = chef('Open Chef');
        Map<String, String> cuisines = new Map<String, String>{
            'American' => 'A', 'Indian' => 'I', 'Italian' => 'It', 'Mediterranean' => 'Me', 'Mexican' => 'Mx', 'Middle Eastern' => 'Mi'
        };
        List<Food__c> foods = new List<Food__c>();
        for (String cuisine : cuisines.keySet()) {
            foods.add(new Food__c(Name = cuisine + ' Dish', Chef__c = openChef.Id, Cuisine_Type__c = cuisine, Available__c = true, Price__c = 5));
        }
        insert foods;

        Assert.areEqual('American Dish', AmericanCuisineController.getAmericanCuisineFoods()[0].food.Name);
        Assert.areEqual('Indian Dish', IndianCuisineController.getIndianCuisineFoods()[0].food.Name);
        Assert.areEqual('Italian Dish', ItalianCuisineController.getItalianCuisineFoods()[0].food.Name);
        Assert.areEqual('Mediterranean Dish', MedCuisineController.getMedCuisineFoods()[0].food.Name);
        Assert.areEqual('Mediterranean Dish', MediterraneanCuisineController.getMediterraneanCuisineFoods()[0].food.Name);
        Assert.areEqual('Mexican Dish', MexicanCuisineController.getMexicanCuisineFoods()[0].food.Name);
        Assert.areEqual('Middle Eastern Dish', MiddleEasternCuisineController.getMiddleEasternCuisineFoods()[0].food.Name);
        Assert.areEqual(1, FoodController.getAsianCuisineFoods().size());
    }

    @isTest
    static void chefValidationRequiresContactInfo() {
        try {
            insert new Chef__c(Name = 'No Contact', Name__c = 'No Contact', Phone__c = '(555) 123-4567', Available__c = true);
            Assert.fail('Email and phone are required');
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains('Email and Phone are required'), e.getMessage());
        }
    }

    @isTest
    static void navigationReturnsOnlyLinksAndHidesLoginItemsFromGuests() {
        System.runAs(guestUser()) {
            Assert.isTrue(SiteNavigationController.getMenuItems('Default Navigation', 'Live').isEmpty(), 'No site context in tests');
        }
        Id networkId = [SELECT Id FROM Network WHERE Name = 'Food Marketing'].Id;
        Assert.isNotNull(SiteNavigationController.getMenuItems(networkId, 'Default Navigation', 'Live', true));
        Assert.isTrue(SiteNavigationController.getMenuItems(networkId, '', 'Live', true).isEmpty());

        List<NavigationMenuItem> navItems = (List<NavigationMenuItem>) JSON.deserialize(
            '[{"attributes":{"type":"NavigationMenuItem"},"Label":"Asian","Target":"/asian-cuisine","Type":"InternalLink","AccessRestriction":"None"},' +
            '{"attributes":{"type":"NavigationMenuItem"},"Label":"Cart","Target":"/cart","Type":"InternalLink","AccessRestriction":"LoginRequired"},' +
            '{"attributes":{"type":"NavigationMenuItem"},"Label":"Topics","Target":"ShowMoreTopics","Type":"NavigationalTopic","AccessRestriction":"None"}]',
            List<NavigationMenuItem>.class);
        List<SiteNavigationController.MenuItem> memberItems = SiteNavigationController.toMenuItems(navItems, false);
        List<SiteNavigationController.MenuItem> guestItems = SiteNavigationController.toMenuItems(navItems, true);
        Assert.areEqual(2, memberItems.size(), 'Only link items are returned');
        Assert.areEqual(1, guestItems.size(), 'Login-only Cart link is hidden from guests');
        Assert.areEqual('/asian-cuisine', guestItems[0].target);
    }

    private static CheckoutController.DeliveryInfo delivery() {
        CheckoutController.DeliveryInfo info = new CheckoutController.DeliveryInfo();
        info.name = 'Demo Customer';
        info.phone = '(555) 123-4567';
        info.street = '1 Test Street';
        info.city = 'Istanbul';
        info.zip = '34000';
        return info;
    }

    @isTest
    static void customerPlacesDemoOrderWithoutPayment() {
        List<User> customers = createCustomers(2);
        Id foodId = food('Visible Noodles').Id;
        CheckoutController.OrderSummary summary;

        Test.startTest();
        System.runAs(customers[0]) {
            ShoppingCartController.addToCart(foodId, 3, 0.01);
            try {
                CheckoutController.DeliveryInfo missing = delivery();
                missing.street = ' ';
                CheckoutController.placeDemoOrder(missing);
                Assert.fail('Street is required');
            } catch (AuraHandledException e) {
                Assert.areEqual('Street is required.', e.getMessage());
            }

            summary = CheckoutController.placeDemoOrder(delivery());
            Assert.areEqual(CheckoutController.DEMO_STATUS, summary.status);
            Assert.areEqual(30, summary.totalAmount, 'Total uses the server price');
            Assert.areEqual(3, summary.totalQuantity);
            Assert.isTrue(summary.orderNumber.startsWith('O-'));
            Assert.isTrue(CartController.getCartItems().isEmpty(), 'Ordered cart is no longer open');

            try {
                CheckoutController.placeDemoOrder(delivery());
                Assert.fail('Empty cart must not be ordered');
            } catch (AuraHandledException e) {
                Assert.areEqual('Your cart is empty.', e.getMessage());
            }
            Assert.areEqual(1, [SELECT COUNT() FROM OrderH__c], 'Customer sees own order');
        }
        System.runAs(customers[1]) {
            Assert.areEqual(0, [SELECT COUNT() FROM OrderH__c], 'Other customers must not see the order');
        }
        Test.stopTest();

        OrderH__c order = [SELECT OwnerId, Status__c, Cart__r.Status__c, Total_Amount__c FROM OrderH__c WHERE Id = :summary.orderId];
        Assert.areEqual(customers[0].Id, order.OwnerId);
        Assert.areEqual('Ordered', order.Cart__r.Status__c);
        for (String fieldName : Schema.SObjectType.OrderH__c.fields.getMap().keySet()) {
            Assert.isFalse(fieldName.containsIgnoreCase('card') || fieldName.containsIgnoreCase('cvv'), 'No card data on orders: ' + fieldName);
        }
    }

    @isTest
    static void unavailableItemsBlockCheckoutAndGuestsCannotOrder() {
        User customer = createCustomers(1)[0];
        Food__c noodles = food('Visible Noodles');
        System.runAs(customer) {
            ShoppingCartController.addToCart(noodles.Id, 1, 1);
        }
        noodles.Available__c = false;
        update noodles;
        System.runAs(customer) {
            try {
                CheckoutController.placeDemoOrder(delivery());
                Assert.fail('Unavailable items must block the order');
            } catch (AuraHandledException e) {
                Assert.isTrue(e.getMessage().contains('no longer available'), e.getMessage());
            }
        }
        System.runAs(guestUser()) {
            try {
                CheckoutController.placeDemoOrder(delivery());
                Assert.fail('Guests must not order');
            } catch (AuraHandledException e) {
                Assert.areEqual(ShoppingCartController.LOGIN_REQUIRED, e.getMessage());
            }
        }
        Assert.areEqual(0, [SELECT COUNT() FROM OrderH__c]);
    }

    private static List<User> createCustomers(Integer count) {
        User owner;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            UserRole role = new UserRole(Name = 'Food Marketing Test Owner');
            insert role;
            owner = new User(
                Alias = 'fmowner', Email = 'fm.owner@example.com', EmailEncodingKey = 'UTF-8', LastName = 'Owner',
                LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/Los_Angeles',
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id, UserRoleId = role.Id,
                Username = 'fm.owner.' + Crypto.getRandomInteger() + '@example.com');
            insert owner;
        }

        List<Contact> contacts = new List<Contact>();
        System.runAs(owner) {
            Account account = new Account(Name = 'Food Marketing Test Customers');
            insert account;
            for (Integer i = 0; i < count; i++) {
                contacts.add(new Contact(AccountId = account.Id, LastName = 'Customer' + i, Email = 'fm.customer' + i + '@example.com'));
            }
            insert contacts;
        }

        List<User> customers = new List<User>();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Id profileId = [SELECT Id FROM Profile WHERE Name = 'Food Marketing Customer'].Id;
            for (Integer i = 0; i < count; i++) {
                customers.add(new User(
                    Alias = 'fmcust' + i, Email = contacts[i].Email, EmailEncodingKey = 'UTF-8', LastName = 'Customer' + i,
                    LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/Los_Angeles',
                    ProfileId = profileId, ContactId = contacts[i].Id,
                    Username = 'fm.customer' + i + '.' + Crypto.getRandomInteger() + '@example.com'));
            }
            insert customers;
            Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Food_Marketing_Customer'].Id;
            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
            for (User customer : customers) {
                assignments.add(new PermissionSetAssignment(AssigneeId = customer.Id, PermissionSetId = permissionSetId));
            }
            insert assignments;
        }
        shareAvailableChefs(customers);
        return customers;
    }

    // Criteria-based sharing rules are not applied to records created in tests, so this
    // mirrors Food_Marketing_Customers_Available_Chefs with manual shares. The rule itself
    // is verified against real data in FoodMarketingGuestCatalogTest.
    private static void shareAvailableChefs(List<User> customers) {
        List<Chef__Share> shares = new List<Chef__Share>();
        for (Chef__c chef : [SELECT Id FROM Chef__c WHERE Available__c = true]) {
            for (User customer : customers) {
                shares.add(new Chef__Share(ParentId = chef.Id, UserOrGroupId = customer.Id, AccessLevel = 'Read', RowCause = Schema.Chef__Share.RowCause.Manual));
            }
        }
        insert shares;
    }
}
