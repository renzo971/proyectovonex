---
agent: neo
---
### Add Instructing Party BIC Field

**Request**: Add "Instructing Party BIC" field to Instruction Detail and Restriction Detail pages

## Reference
- API Field Name: `instructingPartyBic`
- API Endpoints: 
  - GET `/settlement/private/v1/instructions/${instructionId}`
  - GET `/settlement/private/v1/restrictions/${restrictionId}`
- API Documentation: swagger-def.yaml

## Task
Add `instructingPartyBic` field to instruction and restriction details:

### Instruction Detail
- Add as second item in first row of instruction detail header summary

### Restriction Detail  
- Add as first table value in restriction details tab

## Deliverables
1. Update models to include `instructingPartyBic` field
2. Verify/update mock API responses with field (example value: `CXOOPRRTVCX`)
3. Add field to instruction detail header summary
4. Add field to restriction details table (update subsequent row keys)
5. Add translations for `instructingPartyBic` in `attributes.fields` and `attributes.summary`
