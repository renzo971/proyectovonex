---
agent: neo
---
### CCH-8247: Settlement Restrictions - Retain Action

**Request**: Add "Retain restriction" action to restriction search results and detail page

## Reference
- API Endpoint: POST `/settlement/private/v1/restrictions/{restrictionId}/retain`
- API Documentation: swagger-def.yaml
- Similar component: CommonRemoveRetentionModal

## Task
Implement "Retain restriction" functionality for restrictions that:
- Uses retention field from RestrictionSearchListItem model (already exists)
- Creates CommonRetainModal component with confirmation dialog
- Adds "Retain restriction" option in RestrictionSearchActions ActionMenu (visible when retention=false)
- Adds RestrictionRetainButton component to restriction detail footer (visible when retention=false)
- Updates mock API to include retain endpoint
- Shows success toast: "Restriction retained"

## Modal Specifications
- Title: "Retain restriction"
- Description: "By retaining the restriction, you will prevent it from being automatically cancelled. Are you sure you want to retain this restriction?"
- Close button: "Go Back"
- Confirm button: "Confirm retention"

## Mock API Requirements
- Endpoint: POST `/private/v1/restrictions/{restrictionId}/retain`
- Response: 200 status code with empty body
- Create mock in `mock/api/restriction-detail/`
