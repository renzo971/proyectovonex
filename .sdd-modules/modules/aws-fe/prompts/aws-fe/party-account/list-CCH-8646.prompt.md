---
agent: neo 
---

# List Technical Addresses

## Investigate the swagger-def.yml file.

- Read the swagger-def.yml file to identify the format and endpoints for the "Technical Addresses" entity.

## Update the mock data

- Update the mock data for technical addresses.

| technical address | client id | short name | linked to a party | status |
| --- |--- | --- | --- | --- |
| cn=t2sapplicationprod,o=emcfnl2a,o=swift | 40046 | Intesa San Paolo | NO | ACTIVE |
| cn=t2sapplicationdev,o=emcfnl2a,o=swift | 40047 | UniCredit | YES | ACTIVE |
| cn=t2sapplicationtest,o=emcfnl2a,o=swift | 40048 | Banca Nazionale del Lavoro | NO | ACTIVE |
| cn=t2sapplicationqa,o=emcfnl2a,o=swift | 40049 | Banco BPM | NO | ACTIVE |
| cn=t2sapplicationuat,o=emcfnl2a,o=swift | 40050 | Mediobanca | NO | ACTIVE |
| cn=t2sapplicationpreprod,o=emcfnl2a,o=swift | 40051 | Credem | YES | ACTIVE |
| cn=t2sapplicationprod1,o=emcfnl2a,o=swift | 40052 | BPER Banca | YES | ACTIVE |
| cn=t2sapplicationprod2,o=emcfnl2a,o=swift | 40053 | FinecoBank | NO | ACTIVE |
| cn=t2sapplicationprod3,o=emcfnl2a,o=swift | 40054 | Carige | YES | ACTIVE |
| cn=t2sapplicationprod4,o=emcfnl2a,o=swift | 40055 | Banca Sella | NO | ACTIVE |
| cn=t2sapplicationprod5,o=emcfnl2a,o=swift | 40056 | Poste Italiane | YES | ACTIVE |
| cn=t2sapplicationprod6,o=emcfnl2a,o=swift | 40057 | Cassa Depositi e Prestiti | YES | ACTIVE |

  - The `canClosure` field should be set to true if the linked to a party is `true`.

## Update the Technical Addresses List component
- Ensure that the ´TechnicalAddressesList´ component retrieves the technical addresses data from the backend API using the existing service method.
- Ensure that the component displays the following columns in the table:
  - Technical Address
  - Client ID/Shorname
  - Linked to a party
  - Status
- The Client ID/Shortname column should display the Client ID and Shortname encapsulated in MediumTextM and RegularTextS components respectively, the second row should be a also a muted text.
- The Linked to a party column should display a green checkmark icon if the technical address is linked to a party, otherwise it should display a gray cross icon.
- The Status column should display the status using the     TechnicalAddressesBadge component.
- The Status column also contains a button with a Times icon to close the technical address. Just place the button, the functionality to close the technical address will be implemented later.
- All the components should use the stratos library components for the table and icons.
- Ensure that all the `ListRowModel[]` is populated in a hook called `useListRows`, the hook should only have one parameter that is the `TechnicalAddressesListModel`.
- Skip pagination and filtering for now.
- Ensure that the headings for the list are defined using the `ListHeadingModel` interface are defined and exported from the hook file. The width of the columns and headings should be as follows:
  - Technical Address: 380px
  - Client ID/Shortname: 380px
  - Linked to a party: 380px
  - Status: 168px
