import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getMenuItems from '@salesforce/apex/SiteNavigationController.getMenuItems';
import basePath from '@salesforce/community/basePath';
import LOGO from '@salesforce/resourceUrl/Home2HomeLogo';
import FONTS from '@salesforce/resourceUrl/Home2HomeFont';
import { loadStyle } from 'lightning/platformResourceLoader';

// Renders the site's navigation menu (Experience Builder > Navigation) as a header bar.
// Login-only items are hidden from guests by SiteNavigationController.
export default class SiteNavigation extends NavigationMixin(LightningElement) {
    @api menuName = 'Default Navigation';
    items = [];
    logoUrl = LOGO;
    publishedState;

    connectedCallback() {
        // @font-face must live in the document, not the component's shadow tree
        loadStyle(this, FONTS + '/fonts.css').catch(error => {
            console.error('Error loading header font:', error);
        });
    }

    @wire(CurrentPageReference)
    setPublishedState(pageRef) {
        const app = pageRef && pageRef.state && pageRef.state.app;
        this.publishedState = app === 'commeditor' ? 'Draft' : 'Live';
    }

    @wire(getMenuItems, { menuName: '$menuName', publishedState: '$publishedState' })
    wiredMenu({ data, error }) {
        if (data) {
            this.items = data.map(item => ({
                id: item.id,
                label: item.label,
                href: item.type === 'InternalLink' ? basePath + item.target : item.target,
                isInternal: item.type === 'InternalLink'
            }));
        } else if (error) {
            console.error('Error loading navigation menu:', error);
            this.items = [];
        }
    }

    get homeHref() {
        return basePath ? basePath + '/' : '/';
    }

    handleHomeClick(event) {
        event.preventDefault();
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Home' }
        });
    }

    handleClick(event) {
        const { href, internal } = event.currentTarget.dataset;
        if (internal === 'true') {
            event.preventDefault();
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: { url: href }
            });
        }
    }
}
