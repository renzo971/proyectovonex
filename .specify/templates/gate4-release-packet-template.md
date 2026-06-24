# Gate 4 Release Packet: [FEATURE_NAME]

**Feature ID:** [NNN]-[feature-slug]
**Created:** [DATE]
**Synthesised by:** `release-triad-synthesis.prompt.md`
**Status:** Draft | GO | GO with conditions | NO-GO

---

## Evidence Artifacts Reviewed

| Evidence Stream | Artifact | Status |
|-----------------|----------|:------:|
| Code Review | `.specify/specs/[feature-id]/review-output.md` | Reviewed ✅ / NOT PROVIDED ⚠️ |
| Security Review | `.specify/specs/[feature-id]/security-review-output.md` | Reviewed ✅ / NOT PROVIDED ⚠️ |
| Test Evidence | `.specify/specs/[feature-id]/test-report.md` | Reviewed ✅ / NOT PROVIDED ⚠️ |

---

## Traceability Check

| Check | Result | Notes |
|-------|:------:|-------|
| All User Stories have accepted Test Cases | ✅ / ❌ | [detail] |
| All Acceptance Criteria map to passing tests | ✅ / ❌ | [detail] |
| No open Critical/High security findings | ✅ / ❌ | [detail] |
| Constitution compliance verified | ✅ / ❌ | [detail] |

---

## Blockers

> Blockers must ALL be resolved (or explicitly accepted with stakeholder sign-off) before GO verdict.

| # | Source | Severity | Finding | Resolution Required |
|---|--------|:--------:|---------|---------------------|
| [1] | [Code Review / Security Review / Test Evidence] | [Critical/High] | [finding description] | [specific action needed] |

_No blockers_ if this section is empty.

---

## Risks

> Risks are documented concerns that do not block release but must be acknowledged.

| # | Source | Severity | Finding | Mitigation |
|---|--------|:--------:|---------|------------|
| [1] | [source] | [Medium] | [finding description] | [mitigation approach or deferral note] |

_No risks_ if this section is empty.

---

## Rollback Plan

> Describe how to revert this feature if a critical issue is discovered post-release.

- **Rollback trigger:** [conditions that should trigger rollback]
- **Rollback steps:**
  1. [Step 1]
  2. [Step 2]
- **Data migration reversibility:** [Yes / No / Partial — explain]
- **Estimated rollback time:** [estimate]

---

## Notes

> Advisory findings, improvement suggestions, and deferred items.

- [Note 1]
- [Note 2]

---

## GO/NO-GO Verdict

**Verdict: [GO / GO with conditions / NO-GO]**

> [One-sentence rationale for the verdict, citing specific blockers or confirming their absence]

---

## Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Tech Lead | | | |
| Security | | | |
| Product Owner | | | |
