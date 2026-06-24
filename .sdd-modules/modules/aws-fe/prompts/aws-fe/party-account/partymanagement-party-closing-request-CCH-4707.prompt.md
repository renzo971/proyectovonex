---
agent: neo
---
Request: Implement the party closing request feature as per the specifications below.

## Context
 - API Documentation: swagger-def.yml
 - Target APIs: 
  GET /party-account/private/v1/party-management/party-requests/{id}/clients/{clientId}/closing
 - Implement this design from Figma.
@https://www.figma.com/design/tf28uCZ71LAlnMr3FTaK0r/Acme FE-Account-Management?node-id=6537-86620&m=dev

 - Reference Implementation: TechnicalAddressesBadge component for Badge usage
 
## Implementation Checklist

### 1. Models
 - Create models for PartyClosingRequestModel inside models/party-closing-request.ts
 - Create enum for PartyClosingRequestStatus

### 2. API Layer
 - Implement GET party closing request API
 - Add comprehensive API tests

### 3. Mock API Responses
 - Create mock endpoints for the API in mock/api/party-closing-request/
 - Create JSON response files with realistic sample data

### 4. Translation
 - Add partyClosingRequest section with relevant labels, summary fields, and statuses
 - Organize summary-related translations under partyClosingRequest.summary.*

### 5. Components
  - Implement PartyClosingRequestPage component
   - Use useCover pattern for data fetching and state management
   - Use Paper component for layout with BackLink for navigation
   - Integrate header and content components

  - Implement PartyClosingRequestHeader component
   - Display request number and status badge using PaperHeader
   - Show summary information using Summary component
   - Include CloseButton for navigation
   
  - Implement PartyClosingRequestContent component
   - Display party overview Notify with link to party details
   - Render closing date information in a table (proposed and actual closing dates)

  - Implement PartyClosingRequestBadge component
   - Map status values to appropriate badge variants
   - Support all status types from PartyClosingRequestStatus enum

### 6. Routing
 - Add route constant in ROUTES enum with path parameters: PARTY_CLOSING_REQUEST: `${base}/party-closing-request/:id/:clientId`
 - Create route definition for Party Closing Request page

### 7. Key Requirements
 - Keep files under 300 lines
 - Ensure all iterated elements have unique keys
 - Add tests for every new file