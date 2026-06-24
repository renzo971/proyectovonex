---
agent: neo
---
### CCH-7942: Add Transaction ID to Request Header

**Request**: Add Transaction ID display to restriction request header

## Task
Update the restriction request header component to display Transaction ID:
- Add Transaction ID field in fourth position of header
- Ensure Transaction ID exists in models
- Verify Transaction ID is present in mock API responses

## Deliverables
1. Update Header component in `src/pages/` (restriction request section)
2. Verify/update model to include transactionId field
3. Verify/update mock API response data

## Reference
- API Endpoint: GET `/settlement/private/v1/restriction-requests/{restrictionId}`
- API Documentation: swagger-def.yaml