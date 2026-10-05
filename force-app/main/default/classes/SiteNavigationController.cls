/**
 * Returns the current site's navigation menu links for the siteNavigation LWC.
 * Runs without sharing because guests cannot query NavigationMenuItem; it only
 * reads menu metadata (labels and URLs), scoped to the current site, and hides
 * login-only items from guests.
 */
public without sharing class SiteNavigationController {

    @AuraEnabled(cacheable=true)
    public static List<MenuItem> getMenuItems(String menuName, String publishedState) {
        String status = publishedState == 'Draft' ? 'Draft' : 'Live';
        return getMenuItems(Network.getNetworkId(), menuName, status, Auth.CommunitiesUtil.isGuestUser());
    }

    @TestVisible
    private static List<MenuItem> getMenuItems(Id networkId, String menuName, String status, Boolean isGuest) {
        if (networkId == null || String.isBlank(menuName)) {
            return new List<MenuItem>();
        }
        return toMenuItems([
            SELECT Id, Label, Target, Type, AccessRestriction
            FROM NavigationMenuItem
            WHERE NavigationLinkSet.NetworkId = :networkId
              AND NavigationLinkSet.MasterLabel = :menuName
              AND Status = :status
              AND ParentId = null
            ORDER BY Position
        ], isGuest);
    }

    @TestVisible
    private static List<MenuItem> toMenuItems(List<NavigationMenuItem> navItems, Boolean isGuest) {
        List<MenuItem> items = new List<MenuItem>();
        for (NavigationMenuItem navItem : navItems) {
            Boolean isLink = navItem.Type == 'InternalLink' || navItem.Type == 'ExternalLink';
            Boolean isHidden = isGuest && navItem.AccessRestriction == 'LoginRequired';
            if (!isLink || isHidden) {
                continue;
            }
            MenuItem item = new MenuItem();
            item.id = navItem.Id;
            item.label = navItem.Label;
            item.target = navItem.Target;
            item.type = navItem.Type;
            items.add(item);
        }
        return items;
    }

    public class MenuItem {
        @AuraEnabled public String id;
        @AuraEnabled public String label;
        @AuraEnabled public String target;
        @AuraEnabled public String type;
    }
}
