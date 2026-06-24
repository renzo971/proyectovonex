---
agent: neo
---

## Refactor tabs
- Update the tabs to 
  1. Party Management 
    1.1. Party
    1.2. Party Requests
    1.3. Technical Addresses
  2. Securities Accounts 
    2.1. Securities Accounts
    2.2. Securities Account Requests
    2.3. Account Links
  3. Cash Accounts 
    3.1 CSDP Cash Accounts List
    3.2 IPA Cash Accounts List
    3.3 IPA Cash Account Requests
    3.4 POA List
    3.5 POA Requests 
  4. Issuer Paying Agent Designations 
    4.1 IPA Designations List
    4.2 IPA Designation Requests
      
- Ensure that the correct tab is highlighted based on the URL path.
- Do not implement subtabs pages, leave a placeholder in the routes file.

## Load User

- Read `swagger-api.yaml` to understand the `getUserAPI`.
- Implement `getUserAPI` to fetch user details.
- Generate mock data for user details if the API is not available.
- Ensure that the `getUserAPI` returns a class named `UserModel` and the related operations are stored a `UserOperationModel` class.
- Update the `App.tsx` file to call the `getUserAPI` and load user details on app initialization.
- Ensure that the user details are stored in the core slice of the Redux store for global access.
- Ensure that the action to update the user is named `updateUser` in the core slice.
- Ensure that the selector to access the user details from the Redux store is named `selectUser` in the core slice.

## Hide tabs based on user access
- Read the user roles from the `UserModel` returned by the `getUserAPI`.
- Implement logic to hide or show tabs based on the user's roles.
- Ensure that only users with the appropriate roles can see and access specific tabs.

- With `partyManagement.canView` role, show 1, 1.1, 1.2, 1.3
- With `securitiesAccountManagement.canView` role, show 2, 2.1, 2.2
- With `issuerPayingAgentCashAccounts.canView` role, show 3, 3.2, 3.3, 3.4, 3.5, 4, 4.1, 4.2
- With `issuerPayingAgentDesignation.canView` role, show 4, 4.1, 4.2
- With `cashAccountSACLink.canView` role, show 2, 2.3, 2.4, 3, 3.1, 3.4, 3.5

## Default tab
- Ensure that if a user does not have access to the default tab (Securities Accounts), they are redirected to the first tab they have access to based on their roles.

- With `partyManagement.canView` role the default tab is 1.1
- With `securitiesAccountManagement.canView` role the default tab is 2.1
- With `issuerPayingAgentCashAccounts.canView` role the default tab is 3.2
- With `issuerPayingAgentDesignation.canView` role the default tab is 4.1
- With `cashAccountSACLink.canView` role the default tab is 2.3