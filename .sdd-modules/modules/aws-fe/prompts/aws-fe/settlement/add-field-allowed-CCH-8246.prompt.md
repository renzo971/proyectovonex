---
agent: neo
---
### CCH-8246: Settlement Instructions - Instruction Details - Settlement Data - Settlement Details - Add Modification/cancellation allowed

**Request**: Add field "Modification/cancellation allowed" in the Settlement details tab

## Reference
- API Endpoint: GET `/settlement/private/v1/instructions/${instructionId}`
- API Documentation: swagger-def.yaml

## Task
Update Settlement details tab to include "Modification/cancellation allowed" field:
- Add "Modification/cancellation allowed" field in last position on first table in Settlement details tab
- Ensure "Modification/cancellation allowed" exists in models
- Verify/update "Modification/cancellation allowed" is present in mock API responses