---
agent: neo
---
### CCH-4003: Add Instructing Party BIC Select Field

**Request**: Add instructingPartyBic Select field to instruction and restriction setup forms

## Reference
- API Documentation: swagger-def.yaml
- Follow existing Select component patterns (use taxonomy options)

## Task
Add instructingPartyBic field to setup forms:

1. Update models for instruction and restriction setup
2. Add Select component in InstructionSetupStep1 and RestrictionSetupForm  
3. Update mock data with field and taxonomy options (value === label format)

## Deliverables
- Models updated with instructingPartyBic field
- UI components with Select field integrated
- Mock files updated with taxonomy options


