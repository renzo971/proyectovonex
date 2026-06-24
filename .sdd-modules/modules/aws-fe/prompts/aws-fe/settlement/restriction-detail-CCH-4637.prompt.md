---
agent: neo
---
### CCH-4637: Restriction Detail API

**Request**: Add restriction detail API endpoint integration

## Task
Implement API integration for fetching restriction details:
- **API Endpoint**: GET `/settlement/private/v1/restrictions/{restrictionId}`
- Returns comprehensive restriction information including data and linkages
- Requires CSD parameter

## Models Required
1. **RestrictionDetailDataModel**: Core restriction data fields
2. **RestrictionDetailLinkagesModel**: Related linkages information
3. **RestrictionDetailModel**: Main model combining data and linkages

All model field names must match swagger schema exactly.

## Deliverables
1. **Models**: Create `restriction-detail.ts` with class-based models
2. **API Layer**: Create `RestrictionDetailAPI.ts` with typed functions
3. **Mock API**: 
   - Handler: `restriction-detail-get.mjs`
   - Response: `restriction-detail-get.response.json`
   - Ensure data matches swagger schema
4. **Tests**: API test file with full coverage

## Reference
- API Documentation: swagger-def.yaml
- Similar implementation: InstructionDetailAPI



