---
agent: neo
---
Request: Implement the party update request feature as per the specifications below.

## Context
 - API Documentation: swagger-def.yml
 - Target API: 
  GET /party-account/private/v1/party-management/party-requests/{id}/clients/{clientId}/update-overview

 - Implement this design from Figma. 
 (check temporary `figma-template/index.html` for reference exported from figma)

 - Reference Implementation: PartyClosingRequest components for structure and pattern
 
## Implementation Checklist

### 1. Models
 - Create TechnicalAddressUpdateModel with value, isNew, and isRemoved properties
 - Create PartyUpdateRequestModel with flat structure (no nested partyDetails object)
 - Model must match swagger schema PartyRequestUpdateOverviewResponseDto exactly
 - Use PartyClosingRequestStatus enum for status field

### 2. API Layer
 - Implement GET party update request API with correct endpoint path (update-overview)
 - Add comprehensive API tests

### 3. Mock API Responses
 - Create mock endpoints in mock/api/party-update-request/
 - Include sample data with varied isNew/isRemoved flags for technical addresses

### 4. Translation
 - Add partyUpdateRequest section with pageSubtitle, partyDetailsTitle, technicalAddressesTitle
 - Add partyOverviewNotify and goToPartyOverview for navigation notify
 - Reuse partyClosingRequest.statuses.* for badge status labels

### 5. Components
  - Implement PartyUpdateRequestPage component
   - Follow same pattern as PartyClosingRequestPage
   - Use useCover for data fetching and state management

  - Implement PartyUpdateRequestHeader component
   - Reuse PartyClosingRequestBadge component (shared status enum)
   - Display request number, summary, and status badge

  - Implement PartyUpdateRequestContent component
   - Party Details section: Show partyShortName with conditional rendering:
     * If values unchanged: display single value
     * If values changed: display "before <ArrowRightIcon/> after" using HorizontalFlex
   - Technical Addresses section: Display addresses with state-based styling:
     * Use TableRowModel.marked property for row highlighting (isNew or isRemoved)
     * Use MediumTextM with $strike={isRemoved} for strikethrough
     * Use $tone={Color.Neutral.V50} when isRemoved for gray color
     * NO custom styled-components - use Stratos native props only

### 6. Routing
 - Add PARTY_UPDATE_REQUEST route constant: `${base}/party-update-request/:id/:clientId`
 - Create partyUpdateRequestRoutes.tsx and integrate into AppRoutes

### 7. Key Requirements
 - Keep files under 300 lines
 - Use Stratos native features (marked, $strike, $tone) instead of styled-components
 - Reuse existing components where applicable (PartyClosingRequestBadge)
 - Match swagger schema exactly in model structure
 - Add tests for every new file
