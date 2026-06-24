---
agent: neo
---
### CCH-4632: Restriction Cancellation Overview

**Request**: Add restriction cancellation feature with full workflow

## Task
Implement restriction cancellation feature including:
- **API Endpoint**: GET `/settlement/private/v1/restrictions/{restrictionId}/cancellation/{requestId}`
- Complete page with header, content, and footer sections
- Notification component for restriction workflows
- Discard and Approve buttons with proper state management

## Page Structure (Container/Presenter Pattern)
1. **Page Component**: Main container with data loading
2. **Header Component**: Display status and request details
3. **Content Component**: Notification component for workflow
4. **Footer Component**: Discard and Approve buttons

## Deliverables
1. **Models**: CancellationModel and related types
2. **API Layer**: API client with tests
3. **Mock API**: Handler and response data
4. **Routing**: Add route configuration
5. **Translations**: 
   - Add `restrictionCancellation` section
   - Add `restrictionRequestsTab` in CommonDetailNotify translations
   - Extend `home` section for navigation
6. **Components**: Full page implementation with tests

## Special Requirements
- Create CommonRestrictionNotify component (similar to CommonDetailNotify)
- Rename CommonDetailNotify to CommonInstructionNotify
- Update routes to use restriction-specific home paths
- Update success toast messages for restriction context
- Ensure all new components have test files

## Reference
- API Documentation: swagger-def.yaml
- Similar feature: Instruction Cancellation
- Component: CommonDetailNotify (to be adapted)
