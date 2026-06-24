---
agent: neo
---
Request: Implement the party creation request feature as per the specifications below.

## Context
 - API Documentation: swagger-def.yml
 - Target APIs: GET /party-account/private/v1/party-management/party-requests/{id}/clients/{clientId}/creation-overview 

 - Implement this design from Figma. 
 (check temporary `figma-template/index.html` for reference exported from figma)

 - Reference Implementation: PartyClosingRequest feature for structure and patterns to follow

## Implementation Checklist


### 1. Models
 - Create `PartyCreationRequestModel` in `models/party-creation-request.ts`
 - Normalize the status enum:
   - Move the shared status enum to `models/core.ts` (exported as `PartyRequestStatus`)
   - Update both `PartyCreationRequestModel` and `PartyClosingRequestModel` to use `PartyRequestStatus`

### 2. API Layer
 - Implement GET party creation request API
 - Add comprehensive API tests

### 3. Mock API Responses
 - Create mock endpoints for the API in mock/api/party-creation-request/
 - Create JSON response files with realistic sample data

### 4. Translation
 - Add `partyCreationRequest` section with page labels and fields
 - Add status translations under `common.partyRequestStatuses.*` for all status values
 - Update existing status references to use the common translation node

### 5. Refactor Badge Component
 - Create shared `CommonPartyRequestBadge` component in `src/components/CommonPartyRequestBadge/`:
   - Read translations from `common.partyRequestStatuses.*`
   - Map `PartyRequestStatus` enum values to appropriate `StatusBadgeVariant`
 - Refactor existing badge:
   - Find ALL usages of `PartyClosingRequestBadge` in the codebase
   - Replace all imports with `CommonPartyRequestBadge`
   - Update tests to use the shared component
   - Remove the entire `PartyClosingRequestBadge` directory

### 6. Components
 - Implement PartyCreationRequestPage component
   - Use useCover pattern for data fetching and state management
   - Use Paper component for layout with BackLink for navigation
   - Integrate header and content components

 - Implement PartyCreationRequestHeader component
   - Display request number and status badge using PaperHeader
   - Show summary information using Summary component
   - Include CloseButton for navigation
   
 - Implement PartyCreationRequestContent component
   - Render two data tables using TableScroller components
   - Display party details and creation date information
   
 - use CommonPartyRequestBadge component

### 7. Routing
 - Add route constant in ROUTES enum with path parameters: `PARTY_CREATION_REQUEST: '${base}/party-creation-request/:id/:clientId'`
 - Create route definition for Party Creation Request page

### 8. Key Requirements
 - Keep files under 300 lines
 - Ensure all iterated elements have unique keys
 - Add tests for every new file
