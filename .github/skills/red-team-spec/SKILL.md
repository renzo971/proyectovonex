# red-team-spec

Purpose: perform adversarial analysis of specification artifacts to find exploitable gaps, implicit security assumptions, and missing failure modes BEFORE any code is written.

## Input

- A completed specification artifact (post-Gate 1), typically:
  - `.specify/specs/<feature-id>/spec.md`
  - `.specify/specs/<feature-id>/business-context.md`
  - `.specify/specs/<feature-id>/plan.md` (design document)

## When to Use

- After Gate 1 passes (spec complete), before Gate 2 (design complete)
- Operator triggers via `sdd skill run red-team-spec`
- Recommended for security-sensitive features, features handling PII/financial data, or public-facing APIs

## Analysis Dimensions

Evaluate the specification against these 7 adversarial dimensions:

| # | Dimension | What to Look For |
|---|-----------|------------------|
| 1 | **Trust Boundary Violations** | Are trust boundaries explicitly defined? Can an untrusted actor reach a trusted component without validation? |
| 2 | **Implicit Security Assumptions** | Does the spec assume "the network is secure," "input is valid," or "the user is authenticated" without explicit checks? |
| 3 | **Missing Error/Failure Modes** | What happens when external services fail, data is corrupted, or resources are exhausted? Are these paths specified? |
| 4 | **Privilege Escalation Paths** | Can a user with role A perform actions reserved for role B? Are role boundaries explicit in acceptance criteria? |
| 5 | **Data Exposure Risks** | Is sensitive data (PII, credentials, tokens) logged, cached, or returned in error messages? Are data classifications defined? |
| 6 | **Denial-of-Service Vectors** | Are rate limits, pagination, and resource caps specified? Can an attacker exhaust resources via legitimate API calls? |
| 7 | **Input Validation Gaps** | Are input formats, lengths, character sets, and ranges explicitly constrained? Are injection vectors (SQL, XSS, command) addressed? |

## Execution Flow

1. Read all specification artifacts for the target feature.
2. For each of the 7 dimensions:
   - Identify specific findings where the spec has gaps or implicit assumptions.
   - Construct a brief attack scenario describing how an adversary could exploit the gap.
   - Map the finding to affected Acceptance Criteria and Test Cases (if they exist).
   - Recommend a specific spec amendment to close the gap.
3. Classify each finding by severity.
4. Produce the output report.

## Severity Classification

| Severity | Definition | Action |
|----------|------------|--------|
| **Critical** | Exploitable vulnerability that would bypass a core security control | BLOCK — spec must be amended before proceeding |
| **High** | Security gap that could be exploited under realistic conditions | BLOCK — spec should be amended; proceed only with explicit operator approval |
| **Medium** | Security assumption that may be exploitable depending on implementation | WARN — flag for design-phase attention; recommend defensive AC |
| **Advisory** | Best-practice gap with low exploitation likelihood | NOTE — document for awareness; no spec change required |

## Output Contract

Produce a deterministic report:

```markdown
# Red-Team Spec Report

## Summary
- **Feature:** [feature-id] — [feature name]
- **Artifacts Reviewed:** [list of files]
- **Findings:** [count by severity]
- **Verdict:** PASS | PASS with warnings | BLOCK

## Findings

### [Finding #N] — [Title]
- **Dimension:** [which of the 7 dimensions]
- **Severity:** [Critical / High / Medium / Advisory]
- **Description:** [what is the gap]
- **Attack Scenario:** [how an adversary could exploit this]
- **Affected AC/TC:** [references to affected acceptance criteria or test cases]
- **Recommended Amendment:** [specific change to the spec]
```

## Integration

- The `security-reviewer.agent.md` can reference red-team findings during post-implementation code review to verify that spec-level gaps were addressed in code.
- Findings classified as Critical or High should be resolved before Gate 2 (design complete).
- Advisory findings should be logged in the feature's `clarifications.md` for design-phase consideration.
