# Canonical hotspot-review fixture output — used by `.sdd-eval.yaml` assertions.

# Hotspot Report

## Summary
- **Feature:** 042-payments-reconciliation
- **Diff Range:** abc1234..HEAD
- **History Window:** HEAD~100..HEAD
- **Files Scored:** 8
- **Critical:** 1 · **Elevated:** 2 · **Normal:** 5
- **Regressions (>15%):** 1

## Methodology
- LoC source: `wc -l`
- Churn source: `git log --pretty=oneline -- <file>` over `HEAD~100..HEAD`
- Complexity tool: `radon` (factor scaled to 1.0–3.0)

## Findings

### Critical
| File | LoC | Churn | Complexity | Score | Δ vs base |
|------|-----|-------|------------|-------|-----------|
| src/reconcile/engine.py | 612 | 41 | 2.4 | 60221 | +18% |

### Elevated
| File | LoC | Churn | Complexity | Score | Δ vs base |
|------|-----|-------|------------|-------|-----------|
| src/reconcile/queue.py | 318 | 22 | 1.8 | 12592 | +6% |
| src/reconcile/audit.py | 244 | 19 | 1.6 | 7416 | +0% |

### Normal
5 files (omitted for scannability).
