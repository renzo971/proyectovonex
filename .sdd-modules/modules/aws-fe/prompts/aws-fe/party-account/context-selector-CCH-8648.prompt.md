---
agent: neo
---

## Context Selector

**Request**: Create a `HomeCsdSelector` component that allows users to select a CSD context from a dropdown menu.

- Read the `swagger-def.yml` file to identify the API endpoint for retrieving the list of available CSD contexts.
- Implement the API call to fetch the list of CSD contexts, ensure that the method name is `getUserContextSelectorAPI`.
- Ensure that the mock API is created for the new endpoint to return a list of CSD contexts: 
  | value |  label |
  |-------|--------|
  | cph   | ES-CPH |
  | pto   | ES-PTO |
  | mil   | ES-MIL |
  | osl   | ES-OSL |

- Ensure that both `csd` and `csdOptions` are stored in the `core` slice of the Redux store.
- The `HomeCsdSelector` component should display the current CSD context using strato `Select` component, the variant attribute must be `FieldVariant.Compact` and the popover size must be `PopoverSize.XS`. Fill the empty label.
- Ensure that the `HomeCsdSelector` component retrieves the current CSD context and the list of available contexts from the Redux store using `useAppSelector`.
  - Ensure that the names for the selector are `selectCsd` and `selectCsdOptions`.
  - Ensure that the dispatch for updating the CSD context is named `updateCsd`.
  - Essure that dispatch for updating the CSD options is named `updateCsdOptions`.
- Implement an `onChange` handler in the `HomeCsdSelector` component that dispatches an action to update the selected CSD context in the Redux store when a user selects a different context.
- Integrate the `HomeCsdSelector` component into the `HomePage` component, placing it in the header on the right of the title.
- Ensure that the csd options type is named `EntryModel` and it is declared in the `models/core.ts` file.
- Ensure that the data are loaded in the `App.tsx` file when the application starts. Separate the function 
- Ensure that the `AppRoutes` component is only rendered after the CSD options have been successfully loaded and stored in the Redux store. To do this, use the `Cover` component from the stratos library and the `useCover` hook.

## Csd query parameter

**Request**: Ensure that the selected CSD context is included as a query parameter

- Ensure that the `csd` argument is retrieved from the Redux store using the `selectCsd` selector.
- Update the API call for retrieving the technical addresses to include the selected CSD context as a query parameter named `csd`.
- Ensure that the API call for retrieving the technical addresses taxonomy also includes the selected CSD context as a query parameter named `csd`.
