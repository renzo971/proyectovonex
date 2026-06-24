---
agent: neo
---
### CCH-8056: Add Cancel Restriction Button

**Request**: Add cancel button feature to restriction detail page

## Task
Create a cancel button component for the restriction detail page that:
- Opens a confirmation modal with title
- Follows the pattern from InstructionDetailCancelButton
- Integrates with the Restriction Detail Footer page
- Calls the API endpoint: GET `/settlement/private/v1/restrictions/{restrictionId}/cancellation`

## Deliverables
1. RestrictionDetailCancelButton component in `src/components/`
2. Integration with Restriction Detail Footer page
3. Route updates if necessary
4. Test files for new components

## Reference
- API Documentation: swagger-def.yaml
- Similar component: InstructionDetailCancelButton