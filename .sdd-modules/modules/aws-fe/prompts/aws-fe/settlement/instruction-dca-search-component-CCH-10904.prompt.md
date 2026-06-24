---
agent: neo
---
### Settlement Instructions - Creation form - Step 1 - Dedicated Cash Account (DCA) 

**Request**: On securities account number change, clear DCA search component

## Reference: 
- Read the updated GET '/settlement/private/v1/instruction-setup/dca-account' in the swagger-def.yml

## Scenario
Scenario Dedicated Cash Account table search:
Given   a user_A of the Settlement app with the can_create unitary permission
When    the user_A selects an instruction type with payment type = APMT
Then    the Cash Details section appears, with the Dedicated Cash Account field
And     the options that the user can see in the Dedicated Cash Account dropdown are the List of DCAs linked to the preselected SAC through SAC/DCA link
    -POST /tenants/{tenant]/custody/V1/search/cash-accounts filtering by
        -securityAccountIds = the the UUID of the instructionRequest/quantityAndAccountDetails/securitiesAccount/identification from step 1
        -cashAccountType = DCA
    -Return the /dedicatedCashAccountIdentifier

## Behavior Scenario Instructions
- Scenario Dedicated Cash Account component behaviour:
Given   a user_A of the Settlement app with the can_create unitary permission
If      the Cash Details section is displayed
And     the Securities Account Number is not selected yet
Then    the Dedicated Cash Account field is greyed out
If      the user changes the Securities Account Number selection
Then    the Dedicated Cash Account field is cleared

- Dedicated Cash Account (DCA): Update search to trigger after 3 characters