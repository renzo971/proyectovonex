# hotspot-review

Purpose: identify high-risk files in a code change by computing a composite risk score (LoC × commit churn × optional cyclomatic complexity) and emit a deterministic `HOTSPOTS.md` artifact that the reviewer agent uses to apply stricter scrutiny on historically risky files.

## Input

- The active feature workspace under `.specify/specs/<feature-id>/` (skill writes `HOTSPOTS.md` here).
- A git history window, defaulting to `HEAD~100..HEAD` and overridable with `--since <range>`.
- A diff range (defaulting to the merge-base of the active feature branch versus the trunk) used to scope which files are scored.

## When to Use

- Before Gate 4 (review) on any non-trivial change.
- Operator triggers via `sdd analyze --hotspots [--since <range>]`.
- The reviewer agent reads `HOTSPOTS.md` automatically when present and applies stricter criteria for `Critical` / `Elevated` files.
- Recommended for refactors, large diffs (> 200 LoC), or features touching legacy modules.

## Composite Risk Score

For every file in the diff, the skill computes:

```
score(file) = LoC(file) × commit_count(file, since)
              × complexity_factor(file)        # optional, defaults to 1.0
```

Where:
- `LoC(file)` = current line count of the file.
- `commit_count(file, since)` = number of commits touching the file in the configured history window.
- `complexity_factor(file)` = a best-effort cyclomatic-complexity multiplier obtained from `radon` (Python), `lizard` (any), or any project-configured equivalent. **If no complexity tool is available, the factor is 1.0** and the skill records this fallback in the artifact's `Methodology` section.

## Classification Buckets

Each scored file is classified using the relative-rank rule below:

| Bucket | Rule |
|--------|------|
| **Critical** | Top 5 % of scores in the diff window |
| **Elevated** | Top 25 % (excluding Critical) |
| **Normal**   | Remaining 75 % |

Files smaller than 20 LoC are pinned to **Normal** regardless of churn (composite-score noise floor).

## Execution Flow

1. Resolve the active feature workspace (lock-file → branch heuristic).
2. Determine the diff range (current branch vs trunk merge-base, or operator-supplied).
3. List files in the diff (`git diff --name-only`).
4. For every listed file: compute `LoC`, `commit_count(since)`, and (when a complexity tool is configured) `complexity_factor`.
5. Compute the composite score and classify per the rule above.
6. Compute the **regression delta**: composite score at HEAD versus composite score at the feature branch's merge-base. Score increases > 15 % surface as `Regression` flags.
7. Emit `HOTSPOTS.md` (deterministic ordering: Critical → Elevated → Normal, ties broken alphabetically).

## Output Contract

Produce `.specify/specs/<feature-id>/HOTSPOTS.md` with:

- **Summary:** feature-id, diff range, history window, file counts per bucket, regression count.
- **Methodology:** LoC source (`wc -l`), churn source (`git log`), complexity tool (`radon` | `lizard` | `none`).
- **Findings — Critical / Elevated:** table with File, LoC, Churn, Complexity, Score, Δ vs base columns.
- **Findings — Normal:** summary count only.

The reviewer agent consumes this artifact directly. `Critical` and `Elevated` files become first-class review concerns; `Regression` flags become blocking unless explicitly acknowledged.

## Common Rationalizations

| Rationalization | Rebuttal |
|---|---|
| "I just refactored it once." | Churn measures historical risk across the full window, not current intent. |
| "No complexity tool → unreliable." | LoC × churn alone is a robust risk proxy; complexity is a refinement, not a prerequisite. |
| "Top 5 % is too aggressive." | Buckets are scoped to the diff, not the whole repo — outliers surface naturally. |
| "I can delete the report." | The reviewer agent reads the artifact when present; deletion without rationale is a process violation. |

## Boundary Rules

- **Always:** emit deterministic output; record methodology and tool fallbacks; apply the 20-LoC noise floor.
- **Ask First:** before overriding the `--since` window; before excluding files via deny-list.
- **Never:** silently skip unscored files; rewrite `HOTSPOTS.md` without timestamp bump; classify files as Normal to avoid review.
