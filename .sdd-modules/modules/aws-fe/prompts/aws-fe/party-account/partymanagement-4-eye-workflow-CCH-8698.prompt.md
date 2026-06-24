---
agent: neo
---
Request: Implement the 4-eyes workflow validation system for Party Requests with approve, reject, and discard actions.

## Context
 - API Documentation: swagger-def.yml
 - Target APIs:
   - POST /party-account/private/v1/party-management/party-requests/{id}/clients/{clientId}/approve?tenant={csd}
   - POST /party-account/private/v1/party-management/party-requests/{id}/clients/{clientId}/reject?tenant={csd}
   - POST /party-account/private/v1/party-management/party-requests/{id}/clients/{clientId}/discard?tenant={csd}
 - Reference Implementation: settlement/RestrictionRequest pattern for buttons, footers, and page integration

## Implementation Checklist

### 1. Models
 - Create `PartyRequestOperations` class in `models/core.ts` with canApprove, canReject, canDiscard, canUpdate flags
 - Create `PartyRequestModel` interface in `models/core.ts` with id, csdClientId, operations properties
 - Update all request models to add operations field with `new PartyRequestOperations()`

### 2. API Layer
 - Implement `PartyRequestActionsAPI.ts` in `api/` with three separate functions:
   - `approvePartyRequestAPI(id, csdClientId, csd)`
   - `rejectPartyRequestAPI(id, csdClientId, csd, reason: string)`
   - `discardPartyRequestAPI(id, csdClientId, csd, reason: string)`
 - Add comprehensive API tests for all three actions
 - Export from `api/index.ts`

### 3. Mock API Responses
 - Create mock endpoints in `mock/api/party-requests-actions/`:
   - `party-request-approve-post.mjs`
   - `party-request-reject-post.mjs`
   - `party-request-discard-post.mjs`
 - Update existing response JSONs with operations object (all flags true for testing)

### 4. Button Components
 - Create `CommonRequestApproveButton` in `src/components/`:
   - Button with confirmation modal
   - Props: partyRequest, setFooterVisible, reloadData
   - Calls approvePartyRequestAPI (no reason parameter)
   
 - Create `CommonRequestRejectButton` in `src/components/`:
   - Secondary danger button with modal
   - Textarea for rejection reason (max 500 chars) with label `rejectionReasonLabel`
   - Calls API with REJECT action

 - Create `CommonRequestDiscardButton` in `src/components/`:
   - Ghost danger button with modal
   - Textarea for comment (max 500 chars) with label `commentOptionalLabel`
   - Calls API with DISCARD action

 - Add tests for each button following settlement pattern

### 5. Footer Components
 - Create footer for each request type:
   - `PartyCreationRequestFooter`
   - `PartyClosingRequestFooter`
   - `PartyUpdateRequestFooter`

 - Footer structure:
   - PaperFooter with space-between layout
   - Discard on left, Reject/Approve/Update on right
   - Conditionally render based on operations flags
   - Update button with EditIcon (TODO for route)

 - Add tests for each footer

### 6. Page Integration
 - Update all three request pages (PartyCreationRequestPage, PartyClosingRequestPage, PartyUpdateRequestPage):
   - Add isFooterVisible state
   - Determine visibility in useCover: `[operations.canApprove, operations.canReject, operations.canDiscard].some(Boolean)`
   - Conditionally render footer: `{isFooterVisible && <Footer />}`

### 7. Translation
 - Add workflow translations in `common` section:
   - Button labels and modal texts
   - Generic success message: partyRequestSuccessUpdated: `Party request updated`

### 8. Key Requirements
 - Follow settlement RestrictionRequest patterns exactly
 - Keep files under 300 lines
 - Add tests for all new files
 - Backend handles empty string values for optional reasons
