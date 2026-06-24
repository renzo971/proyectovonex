---
agent: neo
---
Request: Implement the parties list feature with search functionality, filters, and pagination for the Party Management section.

## Context
 - API Documentation: swagger-def.yml
 - Target APIs: 
   - POST /party-account/private/v1/party-management/parties/search
   - GET /party-account/private/v1/party-management/parties/filters/taxonomy
 - Figma Design: https://www.figma.com/design/tf28uCZ71LAlnMr3FTaK0r/Acme FE-Account-Management?node-id=5112-6430&m=dev
 - Reference Implementation: TechnicalAddresses feature
---
## Implementation Checklist

### 1. Models
 - Create enums for PartiesStatus and PartiesColumn
 - Separate search filters from paging/sorting into distinct models
 - Create taxonomy model for filter options
 - Create item and list models for the response data

### 2. API Layer
 - Implement search API with separate searchFilters and searchPaging parameters
 - Implement taxonomy API for filter options
 - Add comprehensive API tests

### 3. Mock API Responses
 - Create mock endpoints for both APIs in mock/api/parties/
 - Create JSON response files with realistic sample data
 - Include multiple CSD clients and all status types

### 4. Redux Store
 - Create parties slice with separate searchData and searchPaging state
 - Implement update actions for both state parts
 - Export appropriate selectors

### 5. Translation
 - Add partiesList section with columns, statuses, and pagination labels
 - Use enum-based translation keys for consistency

### 6. Components
 - Implement PartiesFilters with:
   - TableMultiSelectFilter for CSD clients
   - RangeFilter for date ranges
   - MultiSelectFilter for statuses
   - Filter chips with delete handlers
 - Implement PartiesList with:
   - Custom hooks for table headings and rows
   - Enum-based column definitions
   - Integrated sorting with Redux
   - DataTable with pagination
 - Create PartiesTab as main container using useCover pattern
 - Add comprehensive tests for all components

### 7. Routing
 - Add route for parties under PartyManagementTab

### 8. Key Requirements
 - Follow patterns from TechnicalAddresses implementation
 - Use enum-based column/status references throughout
 - Implement proper sorting with columnIndex mapping
 - Pass only changed fields in filter handlers (no spreading entire objects)
 - Do NOT use cacheData
 - Keep files under 300 lines
 - Ensure all iterated elements have unique keys
 - Add tests for every new file