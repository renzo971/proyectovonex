---
agent: neo
---
### CCH-4443: Instruction Lifecycle API

**Request**: Add instruction lifecycle API endpoint integration

## Task
Implement API integration for instruction lifecycle events that:
- Fetches lifecycle history for a specific instruction
- Supports optional sorting (sortingField, sortingOrder parameters)
- Returns timestamped events with settlement amounts
- **API Endpoint**: GET `/settlement/private/v1/instructions/{instructionId}/lifecycle`

## Models Required
1. **InstructionLifecycleItemModel**:
   - timestamp (string)
   - event (string)
   - reason (string)
   - settledAmount (number | null)
   - settledQuantity (number | null)

2. **InstructionLifecycleModel**:
   - lastUpdateTimestamp (string)
   - items (InstructionLifecycleItemModel[])

## Deliverables
1. Models in `src/models/instruction-detail.ts`
2. API function `getInstructionLifecycleAPI` in `src/api/InstructionDetailAPI.ts`
3. Mock API handler and response in `mock/api/instruction-detail/`
4. API tests in `src/api/InstructionDetailAPI.test.ts`

## Mock Data Examples
- full-settlement event
- partial-settlement event
- hold-applied event

## Reference
- API Documentation: swagger-def.yaml
- File: `src/models/instruction-detail.ts`
- File: `src/api/InstructionDetailAPI.ts`
