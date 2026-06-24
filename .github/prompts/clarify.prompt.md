---
description: Ask clarification questions about requirements, design, or implementation
mode: agent
---

Ask me **clarification questions** about the current feature or problem.

**MANDATORY:** Follow the structured question format defined in
`.github/instructions/question-format.instructions.md`.

Invoke `@clarification` to identify and resolve ambiguities in the spec.
Focus on:
- Missing acceptance criteria
- Unclear business rules
- Ambiguous edge cases
- Undefined error handling behavior
- Authorization model gaps

---

## Hidden Requirement Scan

Before closing Phase 2, scan the specification for **implicit requirements** that are assumed but never stated. Surface them as candidates for the user to accept, reject, or defer.

### Categories to Scan

| # | Category | What to look for | Example |
|---|----------|-------------------|---------|
| 1 | **API conventions** | REST/gRPC/GraphQL standards assumed but not specified (pagination, versioning, content types, rate headers) | Spec says "REST API" but never defines pagination strategy or error-response envelope |
| 2 | **Security defaults** | Authentication, authorization, input validation, encryption-at-rest/in-transit assumed but not in AC | Spec mentions "user data" but has no AC for encryption at rest or RBAC rules |
| 3 | **Observability** | Logging, metrics, tracing, health-check endpoints assumed but unstated | Spec describes a service but never mentions structured logging or readiness probes |
| 4 | **Compliance regimes** | Regulations referenced by name without explicit controls (GDPR, PCI-DSS, SOX, HIPAA) | Spec says "handle payment data" — implies PCI-DSS scope but has no AC for it |
| 5 | **Performance SLAs** | Latency, throughput, or availability targets implied by domain language but not quantified | Spec says "real-time updates" without defining latency ceiling or throughput target |
| 6 | **Accessibility defaults** | WCAG level, keyboard navigation, screen-reader support assumed but not in AC | Spec describes a user-facing UI but has no AC for WCAG 2.1 AA compliance |

### Output — Hidden Requirement Candidates

After scanning, produce a **Hidden Requirement Candidates** section in `clarifications.md`:

```markdown
## Hidden Requirement Candidates

> Scanned on [DATE]. Review each candidate: Accept → promote to AC in spec.md, Reject → mark N/A, Defer → move to backlog.

| # | Category | Candidate Requirement | Evidence (spec quote) | Disposition |
|---|----------|-----------------------|-----------------------|-------------|
| 1 | Security defaults | Input validation on all public endpoints | "REST API for user registration" | ☐ Accept / ☐ Reject / ☐ Defer |
| 2 | Observability | Structured JSON logging for audit trail | "audit log of login attempts" | ☐ Accept / ☐ Reject / ☐ Defer |
```

**Gate 2 enforcement:** The Phase 2 gate requires the **Hidden Requirement Candidates** section to be present in `clarifications.md` (even if all candidates were rejected or the section is empty after review). This ensures the scan was performed.
