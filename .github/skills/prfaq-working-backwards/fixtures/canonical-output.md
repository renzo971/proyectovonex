# Canonical prfaq-working-backwards fixture output — used by `.sdd-eval.yaml` assertions.

# PRFAQ — Payments Reconciliation Self-Service

## 1. Press Release
- **Headline:** Acme Securities introduces same-day reconciliation, cutting investigation time from days to minutes.
- **Subhead:** A self-service workspace for operations to reconcile counter-party trades on the same business day.
- **Launch Date (intended):** 2026-09-30
- **Body:** Today, when an operations analyst spots a trade-break, they spend the rest of the day chasing emails. Starting in Q3, Acme Securities customers can open a reconciliation workspace, replay the trade timeline, and resolve breaks themselves — closing the average investigation in under fifteen minutes.
- **Customer Quote:** "I used to lose half a day to one stuck trade. Now I solve it before lunch." — Operations Analyst, mid-tier broker

## 2. Internal FAQ
- **Q:** What is the worst-case replay throughput?
  **A:** 5,000 trades/second over a 30-minute window, sized to the largest customer's end-of-day burst.
- **Q:** Do we need a new persistence tier?
  **A:** No — the existing event store covers the replay window with a six-month retention guarantee.

## 3. External FAQ
- **Q:** When will this be available in my region?
  **A:** EMEA at launch (Q3 2026), APAC and US in Q4.
- **Q:** Will my existing trade format need to change?
  **A:** No — the workspace consumes the current FIX 4.4 envelope.

## 4. Assumptions Log
| ID | Assumption | Severity | Status | Owner | Resolution |
|----|------------|:--------:|:------:|-------|------------|
| A-01 | Six-month retention is sufficient for replay coverage | Killer | open | Platform PO | Validate with top-5 customers' historical break ages |
| A-02 | Operators can resolve 80% of breaks without back-office help | Material | open | Operations PO | Pilot with two customers before GA |
| A-03 | Existing FIX 4.4 envelope carries all required fields | Material | validated | Architect | Confirmed via field audit on 2026-04-14 |

## 5. Recommendation
- **Verdict:** proceed-with-caveats
- **Rationale:** A-01 and A-02 are open killer/material assumptions. The pilot must close them before Gate 4.
- **Next Steps:** `sdd new payments-reconciliation-self-service`; pilot kickoff owned by Operations PO; revisit verdict at Gate 1.
