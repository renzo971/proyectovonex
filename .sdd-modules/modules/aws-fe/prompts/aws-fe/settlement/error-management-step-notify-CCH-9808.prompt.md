---
agent: neo
---
### CCH-9808: Error Management - Step Navigation and Validation Notify

**Request**: Improve error management in setup pages with step navigation and error notification

## Reference
- API Documentation: swagger-def.yaml
- Validation error response includes `step` field to indicate which step has errors

## Task
Implement two improvements for setup pages (instruction and restriction):

### 1. Error Step Navigation
- When validation errors occur (422 response), navigate to the step with errors
- Use `fields[0]?.step` from API response to determine target step
- Apply to: Continue, Save, and Submit button handlers

### 2. Common Error Notification
- Create reusable `CommonSetupNotify` component to display validation errors
- Show notification when `errorMap.size > 0`
- Display above form content in both instruction and restriction setup pages
- Use existing translation key: `common.validationNotifyErrorText`

### 3. Instructing Party BIC Field
- Add `instructingPartyBic` field to instruction and restriction detail pages
- Instruction Detail: Second item in first row of summary (after securitiesAccountOwnerBic)
- Restriction Detail: First table row in details tab
- Update models, mocks (value: `CXOOPRRTVCX`), and translations

## Deliverables
1. Update `ValidationFieldModel` in models to include `step: number`
2. Create `CommonSetupNotify` component with test file
3. Update all setup button handlers to navigate to error step
4. Integrate `CommonSetupNotify` in InstructionSetupPage and RestrictionSetupPage
5. Refactor setup form components to remove PaperBody wrapper
6. Update mock error responses to include `step` field
7. Add `instructingPartyBic` to models, mocks, UI components, and translations
