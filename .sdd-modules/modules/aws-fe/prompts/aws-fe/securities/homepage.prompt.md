---
agent: neo 
---

# Implementation of the homepage with tabs and technical addresses page

Generate the homepage structure with the following steps:

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
  - Create routes following this structure:
    - 1. Securities
      - 1.1 Securities Search
      - 1.2 Available ISINs
      - 1.3 Requests
      - 1.4 Listing
    - 2. Issuances and Redemptions
      - 2.1 Instructions Search
      - 2.2 Requests

  - Ensure that the first level of routes are placed in a HomeTabs component that renders the tabs using the <Tabs> from stratos.

  - Ensure that the link of the tab redirects to a *Tab component that includes a <Outlet> to render the nested routes and a component named <*SubTabs> that renders the subtabs using the <Tabs> from stratos.

  - Ensures that all the routes renders a placeholder. Do not generate the components for the placeholders, just render a div with the name of the page. 