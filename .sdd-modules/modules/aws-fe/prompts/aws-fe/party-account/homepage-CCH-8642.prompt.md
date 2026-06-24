---
agent: neo 
---

# Implementation of the homepage with tabs and technical addresses page

Generate the homepage structure with the following steps:

## Scaffold the page

-  Run this command `npx gear g l TechnicalAddresses`

## HomePage Component

Create a component `HomePage` that:

  - Uses <VerticalFlex> component with $gap `Space.V24` for main layout. 
  - Has an header with an <HorizontalFlex> $justify `space-between`. 
  - Inside the header, there are two elements:
    - On the left side, there is the application name inside a
      `<HeadingL>` component, which should be retrieved using the
      translation key `common.appName`. 
  - In the content section which is a <VerticalFlex> with $gap
    `Space.V8`, include:
    - The <Outlet> component from `react-router-dom` to render nested
      routes.
 

##  Create Home Routes

Create home routes in `home.routes.tsx`:

  - The base route `/home` should render the `HomePage` component.
  - DO NOT lazy import any component!.
  - Create a nested route for `Party Management` and create a component named `PartyManagementTab`, skip the default element for now.
  - Create a nested route for `Securities Accounts` and place a string placeholder inside of it, skip the default element for now.
  - Create a nested route for `Cash Accounts` and place a string placeholder inside of it, skip the default element for now.
  - Create a nested route under `Party Management` for `Parties` and place a string placeholder inside of it.
  - Create a nested route under `Party Management` for `Party Requests` and place a string placeholder inside of it.
  - Create a nested route under `Party Management` for `Technical Addresses` that renders the `TechnicalAddresses` component created in the first step.
  - Inside `PartyManagementTab`, add <Tabs> component for `Parties`, `Party Requests`, and `Technical Addresses`, place the configuration of the tabs items in a TabItems array, fill the active tab based on the current route.
  - Inside `HomePage`, add <Tabs> component for `Party Management`, `Securities Accounts`, and `Cash Accounts`, place the configuration of the tabs items in a TabItems array, fill the active tab based on the current route.
  - Remove the generated routes file generate by the scaffold command.

## Clean up

  - Update the `TechnicalAddressesBadge` component, the statuses should be "ACTIVE" and "INACTIVE" only with labels "Active" and "Closed" respectively.
  - Remove the `TechnicalAddressesOwner` component and all its references, including i18n keys.
  - Empty the `TechnicalAddressesFilters` <Filter> fields value, keep the props, the change and the reloadData function.
  - Remove the `useFilterChips` hook and all its references.
  - Remove the `TechnicalAddressesSearches` component and all its references, including i18n keys.
  - Remove the `TechnicalAddressesSubContent` component and all its references, including i18n keys.
  - Remove the `TechnicalAddressesOwner` component and all its references, including i18n keys.
  - Remove the "technical addresses details get" mock endpoint and all its references.
  - Remove the "technical addresses names get" mock endpoint and all its references.
  - Remove the "technical addresses patch" mock endpoint and all its references.
  - Remove the TechnicalAddressesTabs and all references
