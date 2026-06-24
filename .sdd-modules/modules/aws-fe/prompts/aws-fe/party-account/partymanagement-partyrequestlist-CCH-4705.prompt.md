---
agent: neo
---
Request: Implement the party requests list feature with search functionality, filters, pagination, and status modal for the Party Management section.

## Context
 - API Documentation: swagger-def.yml
 - Target APIs: 
   - POST /private/v1/party-management/party-requests/search
   - GET /private/v1/party-management/party-requests/filters/taxonomy
 - Implement this design from Figma.
@https://www.figma.com/design/tf28uCZ71LAlnMr3FTaK0r/Acme FE-Account-Management?node-id=5127-11995&m=dev
 - Status Tooltip Modal: Implement this design from Figma.
@https://www.figma.com/design/tf28uCZ71LAlnMr3FTaK0r/Acme FE-Account-Management?node-id=5127-14496&m=dev
 - Reference Implementation: TechnicalAddresses and Parties features
---
## Implementation Checklist

### 1. Models
 - Create enums for:
   - PartyRequestColumn (for table columns)
   - PartyRequestSearchCriteria (partyBic, shortName, requestNumber)
 - Separate search filters from paging/sorting into distinct models
 - Create taxonomy model for filter options
 - Create item and list models for the response data
 - Include searchKey and searchCriteria in search filters

### 2. API Layer
 - Implement search API with query parameters: csd, page, size, sortingField, sortingOrder, searchKey, searchCriteria and search filters in body
 - Implement taxonomy API for filter options (with csd parameter)
 - Add comprehensive API tests for all three endpoints

### 3. Mock API Responses
 - Create mock endpoints in mock/api/party-requests/
 - Create JSON response files with realistic sample data
 - Mock taxonomy endpoint with request types, statuses, and CSD clients

### 4. Redux Store
 - Create partyRequests slice with:
   - searchData (includes searchKey, searchCriteria, and other filters)
   - searchPaging (page, size, sortingField, sortingOrder)
 - Implement update actions for both state parts
 - Export appropriate selectors

### 5. Translation
 - Add partyRequestsList section with:
   - columns (requestNumber, requestType, creationDate, lastUpdate, author, partyBic/ShortName, clientID/ShortName, status)
   - statuses (with both short labels and descriptions for tooltip)
   - requestTypes (Creation, Update, Closing)
   - searchCriteria labels (Party BIC, Party Short Name, Request N°)
   - pagination labels
   - buttons (createNewParty)
   - statusTooltipModal (title and descriptions for each status)
 - Use enum-based translation keys for consistency

### 6. Components
 - Implement PartyRequestsFilters with:
   - Search bar with criteria dropdown (Party BIC, Short Name, Request N°)
   - MultiSelectFilter for Request Type 
   - TableMultiSelectFilter for CSD clients
   - MultiSelectFilter for Status (single-select behavior)
   - RangeFilter for Creation Date
   - RangeFilter for Last Update
   - Show only my requests checkbox
   - Filter chips with delete handlers in a hook
 
 - Implement StatusTooltipModal component:
   - Modal with "Request Status" title
   - ResponsiveGrid showing Status Badge, Status Name, and Description
   - All status descriptions as per requirements
   - Proper styling matching Figma design
 
 - Implement PartyRequestsList with:
   - Custom hooks for table headings and rows
   - Enum-based column definitions
   - Integrated sorting with Redux (only Creation Date and Last Update are sortable)
   - DataTable with pagination
   - Status column with tooltip icon that opens StatusTooltipModal
   - Display Party BIC/Short Name together
   - Display Client ID/Short Name together
   - Author displayed
 
 - Implement PartyRequestsTab as main container:
   - Use useCover pattern for loading/error states
   - Include "Create new Party" primary button at top (with can_create permission check)
   - Integrate search, filters, list, and pagination
   - Load taxonomy on mount for filter options
 
 - Add comprehensive tests for all components

### 7. Routing
 - Add route for party-requests under PartyManagementTab

### 8. Key Requirements
 - Follow patterns from TechnicalAddresses and Parties implementations
 - Use enum-based column/status/requestType references throughout
 - Implement proper sorting with columnIndex mapping (only for sortable columns)
 - Pass only changed fields in filter handlers (no spreading entire objects)
 - Do NOT use cacheData
 - Keep files under 300 lines (extract hooks if needed)
 - Ensure all iterated elements have unique keys
 - Add tests for every new file
 - Implement status tooltip icon next to Status column header
 - Search functionality with selectable criteria dropdown
 - "Create new Party" button should only show for users with canCreate permission

