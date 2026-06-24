# Test Analyst — Domain-Specific Patch

> **Source:** Extracted from `Test Analyst.agent.md` — Acme-specific Gherkin patterns.
> **Install:** Review and merge relevant sections into your project's Test Analyst agent.

## Working with Solution Plans

Solution plans location: `solution-plans/sprintXX/{feature-area}/`

### Story Files
- Format: `CCH-{number}.txt` (Jira export format with markup)
- Contains: AS/WANT/SO THAT, scope, description, acceptance criteria, field tables

### CSV Files
- Field definitions, validation rules, data mappings

### PNG Files
- Diagrams for workflow/state transition understanding

## Gherkin Tag Convention

Use `@CCH-XXXX` tags for traceability back to Jira stories:

```gherkin
@CCH-1234
Scenario Outline: Create instruction with valid data
  Given ...
```

## Feature File Location

Save `.feature` files to: `test/resources/features/`

### Folder Conventions

Organize feature files by domain area:
- `features/powerAttorney/` — Power of attorney features
- `features/cashAccounts/` — Cash account features
- `features/instructions/` — Settlement instruction features
- `features/restrictions/` — Restriction features

## Acme-Specific Patterns

### Entity Types
- Instruction (settlement instruction)
- Restriction (securities restriction)
- Allegement (unmatched settlement notification)

### User Story Parsing
- Extract domain entity and operation type from stories
- Map state transitions from acceptance criteria
- Identify authorization roles from scope

### Test Data
- Use realistic data from CSV files in `Examples` tables
- Include Acme-specific identifiers (ISIN, BIC, SWIFT codes)
- Reference tenant context (e.g., `cph`, `vpd`)

## Priority-Driven Questioning

Before generating scenarios:
- **P1 (Blockers)**: Missing info preventing test scenarios
- **P2 (Important)**: Ambiguities affecting test coverage
- **P3 (Nice-to-have)**: Edge cases or optimization scenarios

## Gherkin Best Practices

- Prefer `Scenario Outline` with `Examples` tables
- Realistic data from CSV in Examples
- Clear scenario names describing behavior
- Independent scenarios (no execution dependencies)

### Scenario Categories
1. **Positive/Happy-path** — Auto-generated after clarifications
2. **Negative** — Suggested by category for user selection:
   - Validation errors
   - Authorization/permissions
   - State transitions
   - Business rule violations
   - Boundary conditions
   - Data integrity
