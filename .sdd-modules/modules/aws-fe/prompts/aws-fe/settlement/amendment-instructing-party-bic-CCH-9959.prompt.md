---
agent: neo
---
### CCH-9959: Instruction Amendment Form - Add Instructing Party BIC Select Component

**Request**: Add "Instructing Party BIC" field to the instruction amendment form

## Reference
- API Field Name: `instructingPartyBic`
- API Endpoints:
  - POST `/settlement/private/v1/instructions/${instructionId}/amendment/taxonomy`
  - POST `/settlement/private/v1/instructions/${instructionId}/amendment`
- API Documentation: swagger-def.yaml

## Task
Add `instructingPartyBic` select field to amendment setup form:

### Amendment Form
- Add as first field before amendment type selection
- Implement as Select component with standard properties (label, placeholder, required, disabled, etc.)
- Add proper error validation support

### Component Structure
- Extract amendment type and linkage code into separate `AmendSetupType` component to reduce complexity

## Deliverables
1. Update `AmendSetupDataModel` to include `instructingPartyBic` field
2. Update `AmendSetupTaxonomyModel` to include `instructingPartyBic` field configuration
3. Add `instructingPartyBic` to all mock taxonomy responses (empty, link, linkage, priority, partial, unlink)
4. Add `instructingPartyBic` with selected value to model section of mock files
5. Update error validation mock to include `instructingPartyBic` validation
6. Add translation for `instructingPartyBic` in `attributes.fields`
7. Create `AmendSetupType` component for amendment type selection
8. Add test file for `AmendSetupType` component
9. Update `AmendSetupForm` to include instructing party BIC select and new AmendSetupType component
