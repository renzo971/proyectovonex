---
# Wave 23 §23.A.9/§23.A.10 — memory frontmatter for time-decay ranking
last_referenced_at: "2026-04-14T21:22:22.712601+00:00"
reference_count: 0
decay_floor: true
---
# Team Preferences

> **Purpose:** Per-project operational conventions that agents apply silently at the start of every session.
> These are distinct from the constitution (no governance implications, no gate validation) — they are
> lightweight defaults that improve consistency without adding overhead.
>
> **Usage:** Uncomment and fill in the sections that are relevant to your project. Leave sections
> commented that you want agents to decide autonomously.
>
> **Loading:** This file is read at session start via the startup checklist in
> `constitution-reading.instructions.md`. Agents apply all active entries silently — no
> announcement required.

---

## Naming Conventions

# Examples (uncomment to activate):
# naming.exports: named       # prefer named exports over default exports
# naming.components: PascalCase
# naming.hooks: camelCase starting with "use" (e.g., useFeatureFlag, useAuthState)
# naming.services: PascalCase with "Service" suffix (e.g., AuthService, PaymentService)
# naming.tests: *.spec.ts next to source file | *.test.ts in __tests__/ directory
# naming.types: PascalCase interface/type names, no "I" prefix
# naming.constants: UPPER_SNAKE_CASE for true constants, camelCase for config objects

---

## Code Style

# Examples (uncomment to activate):
# style.arrow-functions: preferred over function declarations for callbacks
# style.async-await: preferred over .then() chains
# style.error-handling: always use typed errors (no bare `throw new Error(string)` without context)
# style.imports: absolute imports from src/ root preferred; relative only for same-directory files
# style.comments: no TODO comments in committed code — open a task instead

---

## Verbosity & Communication

# Examples (uncomment to activate):
# verbosity.agent-output: concise    # concise | standard | verbose
# verbosity.artifact-explanations: brief  # brief | full
# verbosity.question-count: max-3    # max questions per interaction before proceeding with assumptions

---

## Review & PR Workflow

# Examples (uncomment to activate):
# review.pr-platform: github         # github | gitlab | azure-devops
# review.required-reviewers: 2
# review.draft-prs: allowed          # allowed | required | not-allowed
# review.squash-merge: preferred

---

## Testing Conventions

# Examples (uncomment to activate):
# testing.framework: vitest          # jest | vitest | pytest | go-test
# testing.coverage-threshold: 80     # minimum coverage % (overrides constitution if more strict)
# testing.e2e-tool: playwright       # playwright | cypress | none
# testing.mock-strategy: vi.mock     # vi.mock | jest.mock | sinon | none

---

## Documentation

# Examples (uncomment to activate):
# docs.api-spec: openapi-3.1         # openapi-3.1 | openapi-3.0 | asyncapi-2.6
# docs.changelog: conventional-commits  # conventional-commits | keepachangelog | none
# docs.readme: required-per-module   # required-per-module | top-level-only | none

---

## Project-Specific Notes

# Free-form notes agents should keep in mind during the project.
# Examples (uncomment to activate):
# note: "This project targets IE11 compatibility — avoid modern CSS grid features not in the polyfill list."
# note: "All monetary amounts are stored as integers (cents). Never use floats for money."
# note: "The legacy API returns dates as Unix timestamps (seconds). The new API uses ISO 8601 strings."
