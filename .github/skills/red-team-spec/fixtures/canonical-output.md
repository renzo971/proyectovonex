# Canonical red-team-spec fixture output — used by `.sdd-eval.yaml` assertions.

# Red-Team Spec Report

## Summary
- **Feature:** 042-payments-reconciliation
- **Spec Reviewed:** spec.md @ commit abc1234
- **Findings:** 3 (1 High · 1 Medium · 1 Advisory)
- **Verdict:** PASS with warnings

## Findings

### Finding #1 — Race condition under partial-failure replay
- **Severity:** High
- **Probe:** What happens when the reconciliation queue is replayed mid-batch after a worker crash?
- **Description:** AC-07 assumes idempotent replay but the spec does not require deduplication keys.
- **Recommended Action:** Add an explicit dedup-key requirement to AC-07 or document the at-most-once compensation path.

### Finding #2 — Missing rate-limit envelope
- **Severity:** Medium
- **Probe:** Can a malicious upstream flood the audit endpoint and starve the reconciler?
- **Description:** Spec gates throughput by capacity but not by rate.
- **Recommended Action:** Add a rate-limit clause to NFR-03 or link to the platform's shared limiter.

### Finding #3 — Out-of-scope timezone hand-wave
- **Severity:** Advisory
- **Probe:** Operators in APAC may see end-of-day reports drift by a calendar day.
- **Description:** Timezone handling is mentioned but not pinned to a specific reference clock.
- **Recommended Action:** Pin to UTC or document local-time variance in clarifications.md.
