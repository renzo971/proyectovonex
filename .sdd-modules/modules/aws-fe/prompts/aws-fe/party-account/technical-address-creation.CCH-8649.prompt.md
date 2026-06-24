---
agent: neo
---

## Technical Address Create Component

### Endpoint and mocks
- Read the `swagger-def.yml` file to understand the `createTechnicalAddressAPI` endpoint.
- Generate mocks for the create endpoint of technical addresses.
- Read the `swagger-def.yml` file to understand the 
`getCsdClients` endpoint.
- Generate mocks for the `getCsdClients` endpoint.

### Refactor

- Move the create `<Button>` from `TechnicalAddressesPage` for creating technical addresses into its own component named  `TechnicalAddressCreateButton`.


### Implementation 

- Ensure that alongside the `<Button>` component, there is a `<Modal>` component from stratos library. 
- The `<Modal>` should be shown when the button is clicked.
- The modal should have:
  - A title that reads "Create new Technical Address".
  - Two buttons: "Cancel" and "Submit", the first should be a `ButtonVariant.GHOST` variant. The label buttons should use the i18n keys from `common`. The buttons must be enclosed by an `HorizontalFlex` with a gap of `Space.V8`, a justification of `flex-end`, and a breakpoint of `Breakpoint.S`.

- When the "Submit" button is clicked:
  - the modal should close.
  - a toast notification from stratos should appear with the common loading message
  - the `createTechnicalAddressAPI` function should be called with mock values for creating a technical address.
  - If the API call is successful, a success toast notification from stratos should appear with the message "New Technical Address created".
  - If the API call fails, an error toast notification from stratos should appear with the generic error message.


### Update the Modal to include a form

- Inside the modal, include a form with the following fields:
  - A select field using stratos `<TableSelect>` component for the csd client, ensure it have a "Client ID" label. The field is required.
  - The options for the select field should be populated from the `getCsdClients` function.
  - A text input for "Technical Address" with label "Technical Address" and an "Enter a value" placeholder. The field is required. The input should use the stratos `<TextField>` component.
  - Implement form validation to ensure both fields are filled before allowing submission. The "Submit" button should be disabled until the form is valid.
  - The fields must be enclosed in a `VerticalFlex` with a gap of `Space.V24`.
  - The text input should have a caption that reads "Eg. cn=t2sapplicationprod,o=emcfnl2a,o=swift".
