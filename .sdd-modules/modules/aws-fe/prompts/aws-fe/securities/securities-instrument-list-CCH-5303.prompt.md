---
agent: neo
---

# Implementation: Securities - Instrument List of Available ISINs page

Generate the SecuritiesInstrumentsTab with the following steps:

## Reference
- API Documentation: swagger-def.yml
- API Endpoints: 
  - `/securities/private/v1/instruments`
  - `/securities/private/v1/instruments/taxonomy`
- Implement this design from `figma\index.html` use only as reference, do not copy the code directly. The design is a starting point and can be adjusted as needed to fit the implementation requirements.
- Implement the code with precise reference to the `party-account-ui` in workspace, `PartyRequestsTab`, `PartyRequestsFilters`, `PartyRequestsList`, `PartyRequestsSearch` templates and patterns to match it exactly in terms of structure, logic, and functionality. This includes:
  - Implementing similar logic for handling search, filters, and list rendering
  - Using the same UI components from '@dap-ui/stratos' for consistency in design and user experience
  - Use the `nna-ui` project in the workspace and figma/index.html as a reference to verify if the implementation of 'Columns manage' in filters are completed (Ref. ISIN list filters) and complete it


## Implementation Checklist

### 1. Models
 - Create enums for:
   - SecuritiesInstrumentsColumn (for table columns)
   - SecuritiesInstrumentsSearchCriteria (isin, issuerID, issuerShortName)
   - SecuritiesInstrumentsSearchReloader (newSearch: SecuritiesInstrumentsSearchModel)
 - Create taxonomy model for filter options
 - Create item and list models for the response data
 - Include searchKey and searchCriteria in search filters
 - Import { SorterType } from '@dap-ui/stratos' and use it in the list model for sortingOrder.

### 2. API Layer
 - Implement search API with query parameters
 - Implement taxonomy API for filter options (with csd parameter)
 - Add comprehensive API tests for all three endpoints

### 3. Mock API Responses
 - Create mock endpoints in mock/api/securities-instruments/
 - Create JSON response files with realistic sample data
 - Mock taxonomy endpoint

### 4. Redux Store
 - Create securitiesInstruments slice with:
   - search
 - Implement update actions for both state parts
 - Export appropriate selectors

 ### 5. Translation
 - Add securitiesInstrumentsTab section with:
   - columns
   - searchCriteria labels (ISIN, Issuer ID, Issuer Short Name)
 - Use enum-based translation keys for consistency

### 6. Components
 - use '@dap-ui/stratos' components documentation for DataTable, Pagination, Filters, etc.
 - group files into subfolders into SecuritiesInstrumentsTab folder for better organization, example: 
    - 'SecuritiesInstrumentsTab/SecuritiesInstrumentsTab/SecuritiesInstrumentsTab.tsx'
    - 'SecuritiesInstrumentsTab/SecuritiesInstrumentsFilters/SecuritiesInstrumentsFilters.tsx'
    - 'SecuritiesInstrumentsTab/SecuritiesInstrumentsSearches/SecuritiesInstrumentsSearches.tsx'
 - Update all references to these components in the code accordingly.


 - Implement SecuritiesInstrumentsTab with:
  - Organize the logic of the const content and emptyState within the return statement and the Cover component — this way the tab becomes cleaner
  - Redux selectors for search, csd via useAppSelector
  - Local state for list and taxonomy using model class defaults (useState)
  - useCover fetching list + taxonomy in parallel with Promise.all, setting both states on success
  - useEffect on mount to trigger reloadData(search)
  - useEffect on loading change to call restoreScrollbar()
  - <SecuritiesInstrumentsSearches> with reloadData prop
  - <SecuritiesInstrumentsFilters> with taxonomy and reloadData props
  - <Cover> with content, emptyState (guard !list.items.length), and errorState (guard errorCode)

 - Implement SecuritiesInstrumentsSearches with:
   - Search bar with criteria dropdown (ISIN, Issuer ID, Issuer Short Name)
   - Use the reloadData prop to trigger a new search when the search criteria or key changes. by InstructionRequestsReloader type from models, this way we can keep the search logic centralized and avoid code duplication.
   - Use <SearchTrigger /> component from '@dap-ui/stratos' for the search input, ensuring to pass the correct props for value, placeholder, and onSearch handler to manage the search state effectively.
   - Use <ActionMenu /> component from '@dap-ui/stratos' for the criteria dropdown, ensuring to pass the correct props for options, searchKey, and onSelect handler to manage the search criteria state effectively.
   - centralizes the logic into a single const handle, example:
    const handleChange = (searchKey: string, searchCriteria: InstructionRequestsSearchCriteria) => {
    const newSearch = {
      ...search,
      searchKey,
      searchCriteria,
    };
   - Update all references to these components in the code accordingly.

 - Implement SecuritiesInstrumentsFilters with:
   - Search bar with criteria dropdown (ISIN, Issuer ID, Issuer Short Name)
   - RangeFilter for dates 
   - Filter chips with delete handlers in a hook
   - Use <MultiSelectFilter> for option array date (not <MultiSelect>) as in the example below, ensuring to pass the correct props for value, options, labels, and onChange handler to manage the filter state effectively.
   - Filter chips with delete handlers in a hook, use handleChange into to onChange to update the filter state more efficiently and centrally, avoiding code duplication and improving component maintainability (example below).
    <MultiSelectFilter
      value={search.requestTypes}
      options={requestTypes.map(option => ({
        ...option,
        label: t(`instructionRequests.requestTypes.${option.label}`, option.label),
      }))}
      label={t(`instructionRequests.columns.${InstructionRequestsColum.REQUEST_TYPE}`)}
      selectAllLabel={t('common.selectAll')}
      resetLabel={t('common.clearOptionLabel')}
      emptyLabel={t('common.noData')}
      filterPlaceholder={t('common.searchPlaceholder')}
      menuSize={PopoverSize.M}
      onChange={value => handleChange({
        requestTypes: value as InstructionRequestsTypes[],
      })}
    />
    - groups <HorizontalFlex> into a <Filter> component to improve readability and make code more organized and modular.


 - Implement SecuritiesInstrumentsList with:
   - Custom hooks for table headings and rows
   - Enum-based column definitions
   - Integrated sorting with Redux
   - DataTable with pagination
   - Use <Padder $padY={Space.V16}> <SimplePagination /> (not <FullPagination />)
 
 - Add comprehensive tests for all components

 # Future Improvements: implement actions for each row of the list, with the following steps:
  - Update models to include operations permissions in the item model.
  - Create a new component SecuritiesInstrumentsActions with two icons for actions:
    - AddIcon for Create new workflow for this instrument with condition {item.operations.canCreateWorkflow}
    - EditIcon for Update workflow for this instrument with condition {item.operations.canUpdateInstrument} and open the modal on click:
      - Add the modal to the onclick of the canUpdateInstrument button (Ref. settlement-ui > SecuritiesInstrumentsActions)

### 7. Routing
 - Add route for securities-instruments is subtab of Securities

