/**
 * Demo checkout for the Food Marketing site.
 * Turns the current user's open cart into an OrderH__c with status
 * "Demo - Not Paid". No payment is taken and no card data is accepted or stored.
 * Prices are re-read from Food__c, unavailable foods block the order, and the
 * cart is moved to "Ordered" (the CartTrigger chef emails only fire on "Closed").
 */
public with sharing class CheckoutController {

    public static final String DEMO_STATUS = 'Demo - Not Paid';

    @AuraEnabled
    public static OrderSummary placeDemoOrder(DeliveryInfo delivery) {
        ShoppingCartController.requireLogin();
        validate(delivery);

        Id currentUserId = UserInfo.getUserId();
        List<Cart__c> carts = [
            SELECT Id FROM Cart__c
            WHERE Status__c = 'Open' AND OwnerId = :currentUserId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (carts.isEmpty()) {
            throw ShoppingCartController.error('Your cart is empty.');
        }
        Cart__c cart = carts[0];

        // with sharing: foods of unavailable chefs are not visible, so Food__r is null
        List<Cart_Item__c> items = [
            SELECT Id, l_Quantity__c, Food__c, Food__r.Name, Food__r.Price__c, Food__r.Available__c, Food__r.Chef__r.Available__c
            FROM Cart_Item__c
            WHERE Cart__c = :cart.Id
        ];
        if (items.isEmpty()) {
            throw ShoppingCartController.error('Your cart is empty.');
        }

        Decimal totalAmount = 0;
        Decimal totalQuantity = 0;
        List<OrderLine> lines = new List<OrderLine>();
        for (Cart_Item__c item : items) {
            Food__c food = item.Food__r;
            if (food == null || !food.Available__c || food.Chef__r == null || !food.Chef__r.Available__c) {
                throw ShoppingCartController.error('Some items are no longer available. Please remove them from your cart.');
            }
            item.Price__c = food.Price__c;
            totalAmount += food.Price__c * item.l_Quantity__c;
            totalQuantity += item.l_Quantity__c;
            lines.add(new OrderLine(food.Name, item.l_Quantity__c, food.Price__c));
        }

        OrderH__c order = new OrderH__c(
            OwnerId = currentUserId,
            Cart__c = cart.Id,
            Status__c = DEMO_STATUS,
            Delivery_Name__c = delivery.name.trim(),
            Delivery_Phone__c = delivery.phone.trim(),
            Delivery_Street__c = delivery.street.trim(),
            Delivery_City__c = delivery.city.trim(),
            Delivery_State__c = String.isBlank(delivery.state) ? null : delivery.state.trim(),
            Delivery_Zip__c = delivery.zip.trim(),
            Delivery_Notes__c = String.isBlank(delivery.notes) ? null : delivery.notes.trim(),
            Total_Amount__c = totalAmount,
            Total_Quantity__c = totalQuantity,
            Placed_At__c = System.now()
        );

        Savepoint sp = Database.setSavepoint();
        try {
            Database.update(items, AccessLevel.SYSTEM_MODE);
            Database.insert(order, AccessLevel.SYSTEM_MODE);
            cart.Status__c = 'Ordered';
            Database.update(cart, AccessLevel.SYSTEM_MODE);
        } catch (Exception e) {
            Database.rollback(sp);
            throw ShoppingCartController.error('Your order could not be placed. Please try again.');
        }

        OrderSummary summary = new OrderSummary();
        summary.orderId = order.Id;
        summary.orderNumber = [SELECT Name FROM OrderH__c WHERE Id = :order.Id].Name;
        summary.status = DEMO_STATUS;
        summary.totalAmount = totalAmount;
        summary.totalQuantity = totalQuantity;
        summary.lines = lines;
        return summary;
    }

    private static void validate(DeliveryInfo delivery) {
        if (delivery == null) {
            throw ShoppingCartController.error('Delivery details are required.');
        }
        requireText(delivery.name, 'Name', 120);
        requireText(delivery.phone, 'Phone', 40);
        requireText(delivery.street, 'Street', 255);
        requireText(delivery.city, 'City', 80);
        requireText(delivery.zip, 'Zip code', 20);
        if (delivery.state != null && delivery.state.length() > 40) {
            throw ShoppingCartController.error('State is too long.');
        }
        if (delivery.notes != null && delivery.notes.length() > 255) {
            throw ShoppingCartController.error('Notes are too long.');
        }
    }

    private static void requireText(String value, String label, Integer maxLength) {
        if (String.isBlank(value)) {
            throw ShoppingCartController.error(label + ' is required.');
        }
        if (value.trim().length() > maxLength) {
            throw ShoppingCartController.error(label + ' is too long.');
        }
    }

    public class DeliveryInfo {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String phone { get; set; }
        @AuraEnabled public String street { get; set; }
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String state { get; set; }
        @AuraEnabled public String zip { get; set; }
        @AuraEnabled public String notes { get; set; }
    }

    public class OrderSummary {
        @AuraEnabled public Id orderId;
        @AuraEnabled public String orderNumber;
        @AuraEnabled public String status;
        @AuraEnabled public Decimal totalAmount;
        @AuraEnabled public Decimal totalQuantity;
        @AuraEnabled public List<OrderLine> lines;
    }

    public class OrderLine {
        @AuraEnabled public String name;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal price;

        public OrderLine(String name, Decimal quantity, Decimal price) {
            this.name = name;
            this.quantity = quantity;
            this.price = price;
        }
    }
}
