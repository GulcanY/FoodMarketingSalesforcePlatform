# FoodMarketingSalesforcePlatform

## Project Overview
FoodMarketingSalesforcePlatform is a Salesforce-based food marketplace application designed to connect home chefs, restaurants, and customers through Experience Cloud.

The public storefront is the **home2home** Experience Cloud (LWR) site. Customers browse home-cooked dishes by cuisine, view chef profiles, and use a login-only cart with a **demo checkout** (no payment is taken and no card data is collected or stored).

> Portfolio project: catalog data, chefs and orders are sample data.

---

## Features

### Customer Features
- Browse meals by cuisine (Asian, American, Indian, Italian, Mediterranean, Mexican, Middle Eastern)
- Search chefs and view public chef profiles
- Add meals to a cart (login required) and place a **demo** order

### Chef Features
- Chef profiles with dishes and images
- Availability control: closed chefs and their dishes are hidden from the site

### Admin Features
- Manage chefs, foods, carts and demo orders
- Image publishing: images attached to available chefs/foods get a public link automatically; links are revoked when a chef or dish becomes unavailable
- Nightly-style batch and data tools for sample data

### Security and privacy
- Public Apex runs `with sharing` and in `USER_MODE` (CRUD/FLS enforced)
- Guest and customer access limited to available records and public fields (chef email, phone and address are never exposed)
- Server-side prices and cart ownership checks; demo orders store delivery details only, never card data
- Local org backups, org sessions and credential files are excluded from Git (`.gitignore`)

---

## Technologies Used

**In this repository**
- Apex (controllers, triggers, batch, tests)
- Lightning Web Components (LWC)
- Experience Cloud (LWR site `Food_Marketing1`, branded home2home)
- Salesforce Flow
- Salesforce CLI, VS Code, GitHub

**Planned / concepts**
- Sales Cloud processes
- Marketing Automation
- Agentforce AI
- Data Cloud

---

## Project Structure

```text
force-app/main/default/
  classes/              Apex controllers, services, triggers' handlers and tests
  lwc/                  Storefront components (catalog, cart, carousel, navigation)
  objects/              Chef__c, Food__c, Cart__c, Cart_Item__c, OrderH__c, ...
  digitalExperiences/   Food_Marketing1 LWR site (pages, theme, branding)
  permissionsets/       Guest, customer and admin access
  sharingRules/         Guest and customer sharing for available chefs
  staticresources/      Logo, carousel images, handwriting font
config/
data/sample/            Sample chefs and foods (sf data import tree)
manifest/
scripts/
```

---

## Getting Started

```bash
# authenticate the target org (alias used in this project: FoodDev)
sf org login web --alias FoodDev

# deploy and run the site tests
sf project deploy start --source-dir force-app --target-org FoodDev \
  --test-level RunSpecifiedTests --tests FoodMarketingSiteAccessTest --tests FoodMarketingGuestCatalogTest

# load sample data
sf data import tree --plan data/sample/plan.json --target-org FoodDev

# publish the Experience Cloud site
sf community publish --name "Food Marketing" --target-org FoodDev
```
