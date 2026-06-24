---
agent: neo
---

## Context Selector — CCH-5188

**Request**: Create a `HomeCsdSelector` component that allows users to select a CSD context from a dropdown menu.

- Read the `swagger-def.yml` file to identify the API endpoint for retrieving the list of available CSD contexts.
- Implement the API call to fetch the list of CSD contexts, ensure that the method name is `getUserContextSelectorAPI`.
- Ensure that the mock API is created for the new endpoint and returns a list of CSD contexts:
  | value | label  |
  |-------|--------|
  | cph   | ES-CPH |
  | pto   | ES-PTO |
  | mil   | ES-MIL |
  | osl   | ES-OSL |

- Ensure that both `csd` and `csdOptions` are stored in the `core` slice of the Redux store.
- The `HomeCsdSelector` component should display the current CSD context using the Stratos `Select` component. The `variant` attribute must be `FieldVariant.COMPACT` and the popover size must be `PopoverSize.XS`. Fill the empty label.
- Ensure that the `HomeCsdSelector` component retrieves the current CSD context and the list of available contexts from the Redux store using `useAppSelector`.
  - Ensure that the selector names are `selectCsd` and `selectCsdOptions`.
  - Ensure that the dispatch action for updating the CSD context is named `updateCsd`.
  - Ensure that the dispatch action for updating the CSD options is named `updateCsdOptions`.
- Implement an `onChange` handler in the `HomeCsdSelector` component that dispatches `updateCsd` and re-triggers `loadUser` when the user selects a different context.
- Integrate the `HomeCsdSelector` component into the `HomePage` component, placing it in the header on the right of the title.
- Ensure that the CSD options type is named `EntryModel` and is declared in the `models/core.ts` file.
- Ensure that the `getUserAPI` call includes the selected `csd` as a query parameter.
- Ensure that the `loadUser` thunk reads the current `csd` from the Redux store state.
- Ensure that the CSD options are loaded in `App.tsx` when the application starts using `useCover`. The `AppUser` content should only be rendered after the CSD options have been successfully loaded. On error, render `CommonErrorState` with a reload callback.
