---
agent: neo
---
### CCH-9967: Update Securities Account Fields to Use Taxonomy-Based Select Components

**Request**: Replace Search components with Select components using taxonomy for securitiesAccountOwnerBic and securitiesAccount fields in instruction setup form

## Reference
- API Documentation: swagger-def.yaml
- Restriction setup form pattern (already uses Select with taxonomy)
- Follow InstructionSetupProcessing component pattern

## Task
Migrate instruction setup from Search-based to taxonomy-based Select components:

1. Create InstructionSetupBic component merging all three BIC/account Select fields (instructingPartyBic, securitiesAccountOwnerBic, securitiesAccount)
2. Update InstructionSetupStep1 to use new component
3. Remove old Search-based components (InstructionSetupBic/, InstructionSetupAccount/ directories) and API functions
4. Update mock data with taxonomy options (value === label format)

## Deliverables
- InstructionSetupBic component with Select fields
- InstructionSetupStep1 refactored with reduced complexity
- Unused API functions removed
- Mock files updated with taxonomy options
