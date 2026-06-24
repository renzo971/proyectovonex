---
applyTo: "**/*"
description: Advanced before/after examples for confidence calibration, cleanup precision, and challenge-first agreement
---

## Anti-Pattern Examples — Advanced Catalog

See [anti-patterns-examples.instructions.md](anti-patterns-examples.instructions.md) for the core catalog covering Rules 1-4.

## Rule 5 — Confidence Calibration

- **Wrong:** assert facts like payment provider, rate limits, or retry policy without reading the relevant artifacts.
- **Correct:** label findings `High`, `Medium`, or `Low` confidence and include a short confidence summary when several findings matter.

## Rule 6 — Orphan Cleanup Precision

- **Import cleanup:** remove only imports made unused by your change; leave pre-existing dead imports alone and mention them separately if useful.
- **Function cleanup:** change the requested function, but do not delete unrelated helpers just because you noticed they look unused.

## Rule 7 — Sycophantic Agreement

- **Caching example:** do not agree to add Redis just because the user suggested it; inspect the current query path and challenge root-cause assumptions first.
- **Technology-choice example:** do not rubber-stamp GraphQL; compare it against current requirements, team conventions, and operational trade-offs before recommending it.

## Application

Use this companion when the short rule text is not enough and you need a worked pattern for evidence grading, cleanup boundaries, or challenge-first technical discussion.
