---
agent: neo
---
### CCH-8247: Settlement Restrictions - Remove Retention Action

**Request**: Add "Remove retention" action to restriction search results and detail page

## Reference
- API Endpoint: POST `/settlement/private/v1/restrictions/{restrictionId}/removeRetain`
- API Documentation: swagger-def.yaml
- Similar component: CommonInstructionCancellationModal

## Task
Implement "Remove retention" functionality for restrictions that:
- Adds retention field to RestrictionSearchListItem model
- Creates CommonRemoveRetentionModal component with confirmation dialog
- Adds "Remove retention" option in RestrictionSearchActions ActionMenu (visible when retention=true)
- Moves cancel button into ActionMenu alongside remove retention
- Adds RestrictionRemoveRetentionButton component to restriction detail footer
- Updates mock API to include retention field and removeRetain endpoint
- Shows success toast: "Restriction retention removed"

## Modal Specifications
- Title: "Remove restriction retention"
- Description: "By removing the retention, the restriction could be automatically cancelled on its intended settlement date if not settled. Are you sure you want to remove the retention on this restriction?"
- Close button: "Go Back"
- Confirm button: "Remove retention"