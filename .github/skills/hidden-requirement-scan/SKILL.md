# hidden-requirement-scan

Purpose: surface implicit, assumed, or unstated requirements in a specification before Phase 2 close — preventing costly Phase 4 rework.

## When to Use

- During Phase 2 Clarify, before closing the clarification round.
- When a spec references a domain, protocol, or regulation by name without explicit acceptance criteria.
- When the user asks to find hidden or implicit requirements.

## Categories

Scan the specification against these 6 implicit-requirement categories:

| # | Category | What to Look For |
|---|----------|------------------|
| 1 | **API conventions** | Pagination, versioning, content-type negotiation, rate-limit headers, error-response envelopes assumed but not specified |
| 2 | **Security defaults** | AuthN/AuthZ, input validation, encryption at rest/in transit, RBAC rules assumed but absent from AC |
| 3 | **Observability** | Structured logging, metrics endpoints, distributed tracing, health/readiness probes assumed but unstated |
| 4 | **Compliance regimes** | GDPR, PCI-DSS, SOX, HIPAA, or other regulations referenced by name without explicit controls in AC |
| 5 | **Performance SLAs** | Latency ceilings, throughput targets, availability percentages implied by domain language but not quantified |
| 6 | **Accessibility defaults** | WCAG conformance level, keyboard navigation, screen-reader support assumed for user-facing UIs but absent from AC |

## Execution Flow

1. Read `spec.md` and `business-context.md` for the target feature.
2. For each of the 6 categories, search for domain signals (keywords, named standards, implied constraints).
3. For each finding, extract the **evidence** (the spec text that implies the requirement).
4. Classify the finding and propose a candidate requirement statement.
5. Produce the output report for user review.

## Output Contract

Append a **Hidden Requirement Candidates** section to `clarifications.md`:

```markdown
## Hidden Requirement Candidates

> Scanned on [DATE]. Review each candidate: Accept → promote to AC in spec.md, Reject → mark N/A, Defer → move to backlog.

| # | Category | Candidate Requirement | Evidence (spec quote) | Disposition |
|---|----------|-----------------------|-----------------------|-------------|
| 1 | Security defaults | Input validation on all public endpoints | "REST API for user registration" | ☐ Accept / ☐ Reject / ☐ Defer |
| 2 | Observability | Structured JSON logging for audit trail | "audit log of login attempts" | ☐ Accept / ☐ Reject / ☐ Defer |
```

## Gate Integration

- Phase 2 gate validation requires the **Hidden Requirement Candidates** section to exist in `clarifications.md` (even if empty after review).
- Accepted candidates should be promoted to explicit AC entries in `spec.md` before Gate 2 close.
- Rejected candidates remain documented for audit trail.

## Boundary

- This skill scans for implicit requirements; it does not invent requirements from nothing.
- Findings are candidates for human review — never auto-promote to AC without user approval.
- Do not duplicate the full specification content in the output.
