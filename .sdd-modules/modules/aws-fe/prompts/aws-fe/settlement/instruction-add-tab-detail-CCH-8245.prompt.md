---
agent: neo
---
### CCH-8245: Settlement Instruction - Instruction Details - Other Information - T2S Generated Instruction

**Request**: Add new tab "T2S Generated Instruction" in the Other information tab

## Reference
- API Endpoint: GET `/settlement/private/v1/instructions/${instructionId}`
- API Documentation: swagger-def.yaml
- Similar component: InstructionAmountsTab

## Implementation Steps

### 1. Backend Integration
- Update Models in `src/models/instruction-detail.ts` by adding only the new fields in swagger-def.yaml
- Update Mock API in `mock/api/instruction-detail/` by adding only the new fields in swagger-def.yaml:
  - t2sGenerated
  - t2sGeneratedReason
  - generatedReasonAdditionalInformation
  - cashPartiesDebtorBIC
  - cashPartiesDebtorAccountNumberIBAN
  - cashPartiesDebtorAccountNumberOther
  - cashPartiesCreditorBIC
  - cashPartiesCreditorAccountNumberIBAN
  - cashPartiesCreditorAccountNumberOther
- Update API function and test if necessary in `src/api/InstructionDetailAPI.ts`
- Update Redux slice and test if necessary in `src/store/instruction-detail/slice.ts`

### 2. Create Tab Component
- Location: `src/pages/instruction-detail/InstructionOtherTab/InstructionT2sGeneratedTab/`
- Files to create:
  - `InstructionT2sGeneratedTab.tsx` - Main component
  - `InstructionT2sGeneratedTab.hooks.tsx` - Custom hook with mock API newline mapping
  - `InstructionT2sGeneratedTab.test.tsx` - Unit tests

### 3. Update Routing
- Add route constant in `src/routes/config.ts`
- Add route definition in `src/routes/instructionDetailRoutes.tsx`

### 4. Update Parent Tab
- Update `src/pages/instruction-detail/InstructionOtherTab/InstructionOtherTab/InstructionOtherTab.tsx`
- Add tab item as last position in tabs array

### 5. Update i18n
- Add translations in `src/i18n/en.json` under `instructionDetail.otherTabs` and `instructionDetail.t2sGeneratedTab`