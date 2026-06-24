---
agent: neo
---
### CCH-9961: Add Instructing Party BIC to Hold/Release Modal

Add a required `Instructing Party BIC` Select to the instruction hold/release modal.

Key points:
- Load options from `GET /settlement/private/v1/parties-bic?csd={csd}` via `getPartiesBic(csd)`
- Pass selected `instructingPartyBic` to `POST /instructions/{instructionId}/hold-release`
- Show loading/error states and field-level validation (use `getCaption` for errors)

Minimum deliverables:
- API: `getPartiesBic(csd)` in `src/api/PartiesBicAPI.ts` + test
- Model: `EntryModel[]` (use existing `EntryModel` in `src/models/core.ts`)
- UI: Add Select to `CommonInstructionHoldModal` and send value to hold API
- Mocks: `parties-bic-get.mock.mjs` and response JSON; update hold-post mock for validation
- Translation: `attributes.fields.instructingPartyBic`
