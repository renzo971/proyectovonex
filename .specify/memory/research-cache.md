---
# Wave 23 §23.A.9/§23.A.10 — memory frontmatter for time-decay ranking
last_referenced_at: "2026-04-11T13:18:21.979015+00:00"
reference_count: 0
---
# Research Cache

> **Project-wide** cache of external research findings.
> Agents append entries after completing research (technology evaluation, pattern analysis,
> library comparison, etc.)
> Entries expire after 7 days by default — re-research if stale.

---

## How to Use

After researching a topic, append:

```
## [Topic Name]

**Researched:** [YYYY-MM-DD]
**Feature:** [NNN or "project-wide"]
**Relevance:** [HIGH / MEDIUM / LOW]
**Expires:** [+7 days from research date]

### Key Findings
- [Finding 1 with source reference]
- [Finding 2 with source reference]

### Patterns Found
- [Pattern with context]

### Constraints Discovered
- [Constraint from constitution or external source]

### Open Questions
- [Unanswered question]
```

---

## Freshness Guide

| Relevance | Age | Action |
|-----------|-----|--------|
| HIGH | < 3 days | Use directly |
| MEDIUM | 3-7 days | Use with caution, verify if critical |
| LOW | > 7 days | Re-research before using |

---

## Cache

<!-- Append new research entries below this line -->
