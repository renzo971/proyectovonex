---
agent: neo
---

## Technical Address Closure Component 

### Endpoint and mocks
- Read the `swagger-def.yml` file to understand the `closureTechnicalAddressAPI` endpoint.
- Generate mocks for the closure endpoint of technical addresses.

### Refactor

- Move the `<IconButton>` for closing technical addresses into its own component.
- Ensure the new component is named `TechnicalAddressClosureButton`.
- Ensure the component have a property named `technicalAddress` of type `TechnicalAddress`.

### Implementation 

Update the `TechnicalAddressClosureButton` component to include the following functionality:

- Ensure that alongside the `<IconButton>` component, there is a `<Modal>` component from stratos library. 
- The `<Modal>` should be shown when the button is clicked.
- The modal should have:
  - A title that reads "Close Technical Address".
  - A body that contains the text "The Technical Address XYZ will be permanently closed. Would you like to proceed?".
  - Two buttons: "Cancel" and "Close Technical Address", the first should be a `ButtonVariant.GHOST` variant, and the second a `ButtonSeverity.DANGER` severity. The label buttons should use the i18n keys `common.goBackButton` and `technicalAddresses`. The buttons must be enclosed by an `HorizontalFlex` with a gap of `Space.V8`, a justification of `flex-end`, and a breakpoint of `Breakpoint.S`.

- When the "Close Technical Address" button is clicked:
  - the modal should close.
  - a toast notification from stratos should appear with the common loading message
  - the `closureTechnicalAddressAPI` function should be called with the `technicalAddress` fields from the props and the `csd` from the redux store.
  - If the API call is successful, a success toast notification from stratos should appear with the message "Technical Address closed".
  - If the API call fails, an error toast notification from stratos should appear with the generic error message.

