---
mode: agent
description: "5-step TCO + ROI framework for building an organizational adoption business case for SDD — produces ADOPTION-BUSINESS-CASE.md."
---

# Adoption Business Case

> **Purpose:** Build a data-driven business case for SDD adoption by quantifying total cost of ownership and return on investment.

---

## Step 1 — Baseline Metrics

Collect current-state measurements (pre-SDD):

| Metric | Value | Source |
|--------|-------|--------|
| Avg. time from story to production | [hours/days] | [Jira / tracking tool] |
| Post-release defect rate | [defects per release] | [bug tracker] |
| Rework percentage | [% of sprint capacity] | [retro data] |
| Specification completeness | [% stories with full AC+TC] | [audit] |
| Onboarding time for new developers | [days to first PR] | [team lead estimate] |

## Step 2 — Cost of Adoption (TCO)

| Cost Category | One-Time | Recurring (monthly) |
|---------------|:--------:|:-------------------:|
| Setup and configuration | [hours × rate] | — |
| Training (2-day workshop) | [hours × team size × rate] | — |
| Champion time (ongoing) | — | [hours × rate] |
| AI tooling licenses | — | [cost] |
| Productivity dip during learning (est. 2–4 weeks) | [hours × rate] | — |
| **Total** | **[sum]** | **[sum]** |

## Step 3 — Expected Benefits (ROI)

| Benefit | Conservative | Optimistic | Evidence Source |
|---------|:------------:|:----------:|----------------|
| Reduced rework (fewer spec gaps) | [%] | [%] | Gate pass rate data |
| Faster time-to-production | [%] | [%] | Phase timing data |
| Fewer post-release defects | [%] | [%] | Traceability coverage |
| Faster onboarding (constitution + playbook) | [days saved] | [days saved] | New-hire feedback |
| Reduced context loss (session handoff) | [hours/week saved] | [hours/week saved] | Developer survey |

## Step 4 — Payback Period

Calculate months to break even:

```
Monthly benefit = (rework reduction + defect reduction + speed improvement) × team hourly rate
Payback months = Total one-time TCO ÷ Monthly benefit
```

**Conservative payback:** [N] months
**Optimistic payback:** [N] months

## Step 5 — Recommendation

Save the completed analysis to `.specify/reports/ADOPTION-BUSINESS-CASE.md` with:

1. Executive summary (2–3 sentences)
2. Baseline vs. projected comparison table
3. TCO breakdown
4. ROI timeline chart description
5. Go / No-Go recommendation with conditions
