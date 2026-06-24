---
agent: neo
---
### Instruction search step 1: Change component to search for account instead of instruction

**Request**: Change component to search for account instead of instruction

## Reference
- the options that the user can see in the Securities Account Number dropdown are the List of SACs linked to the preselected Securities Account Owner BIC (Account Management API): POST /tenants/{tenant}/custody/v1/search/security-accounts  filtering by
 - partyBic = the previously selected securities account owner BIC
 - securitiesAccountIdentifier (text insert by user)
Return: /securitiesAccountIdentifier


- API Documentation 'swagger-def.yaml':
 - Endpoint to use: /settlement/private/v1/instruction-setup/securities-account-number 
 - update the api part if and where necessary in the new instructionSetupAccount and restrictionSetupAccount components

## Scenario
As      a user of Acme FE Settlement on step 1 of the Instruction or Restriction creation form
I want  to select the Instructing Party BIC, Securities account Owner BIC and Number among predefined lists
So That I can only instruct/restrict for parties and accounts I am allowed 

## Behavior Scenario Instructions
 - Scenario: Securities Account Number dropdown
    Given   a user_A of the Settlement app with the can_create unitary permission
    When    the user_A selects a Securities Account Owner BIC
    Then    the Securities Account Number field is enabled
    And     the options that the user can see in the Securities Account Number dropdown are the List of SACs linked to the preselected Securities Account Owner BIC (Account Management API): POST /tenants/{tenant}/custody/v1/search/security-accounts  filtering by
     - partyBic = the previously selected securities account owner BIC
     - securitiesAccountIdentifier (text insert by user)
    Return: /securitiesAccountIdentifier
 - Change component to search, 
  - name: instructionSetupAccount
  - add TODO comment for missing API and set options to empty
  - use taxonomy for options: options={instructionSetupTaxonomy.securitiesAccount.options!}

## Behavior Scenario Restriction
 - Scenario: Securities Account Number dropdown
    Given   a user_A of the Settlement app with the can_create unitary permission
    When    the user_A selects a Securities Account Owner BIC
    Then    the Securities Account Number field is enabled
    And     the options that the user can see in the Securities Account Number dropdown are the List of SACs linked to the preselected Securities Account Owner BIC (Account Management API): POST /tenants/{tenant}/custody/v1/search/security-accounts  filtering by
     - partyBic = the previously selected securities account owner BIC
     - securitiesAccountIdentifier (text insert by user)
    Return: /securitiesAccountIdentifier
 - Change component to search, 
  - name: restrictionSetupAccount
  - add TODO comment for missing API and set options to empty
  - use taxonomy for options: options={restrictionSetupTaxonomy.securitiesAccount.options!}