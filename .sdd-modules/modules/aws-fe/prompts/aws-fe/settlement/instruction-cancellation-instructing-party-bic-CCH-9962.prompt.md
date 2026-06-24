```prompt
---
agent: neo
---
### CCH-9962: Add Instructing Party BIC to Instruction Cancellation

Add a required `Instructing Party BIC` Select to the instruction cancellation modal and include the selected BIC in the cancellation API request.

Key points:
- Load options from `GET /settlement/private/v1/parties-bic?csd={csd}` via `getPartiesBic(csd)`
- Add `instructingPartyBic` parameter to `POST /settlement/private/v1/instructions/{instructionId}/cancellation`
- In the UI (`CommonInstructionCancellationModal`):
  - Add a `Select` for `instructingPartyBic`
  - Use `useCover` to load options and show loading / error states via `Cover` and `CommonErrorState`
  - Position the `Select` inside a `ResponsiveGrid` (layout: `9fr 3fr`) before the existing body content
  - Use `getCaption()` to display validation caption for the field
  - Make the field required and prevent submit when empty
- Update tests to mock `useCover` from `@dap-ui/stratos`

Minimum deliverables:
- API: Update `cancelInstructionDetailAPI()` signature to accept `instructingPartyBic` and include it in the request body
- UI: `src/components/CommonInstructionCancellationModal/CommonInstructionCancellationModal.tsx` updated with `Select`, `Cover`, `useCover`, and proper validation
- Tests: Update `CommonInstructionCancellationModal.test.tsx` to mock `useCover`
- Translations: Ensure `attributes.fields.instructingPartyBic` exists in i18n files
- Mocks: Add or update mock responses for `parties-bic` if necessary

References:
- Swagger: `swagger-def.yml` (see `CancellationReason` schema includes `instructingPartyBic`)
- Similar implementation: `.github/prompts/instruction-hold-instructing-party-bic-CCH-9961.prompt.md`

```