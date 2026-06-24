---
description: Monthly maintenance review of SHA-pinned GitHub Actions — surface upgrade candidates, diff the new SHAs against the pinned ones, and update only after explicit human approval.
mode: agent
---

# CI Action Bump Review (Wave 23 §23.B.13)

> Run this prompt **monthly** (or after a high-severity advisory) to refresh
> the SHA pins introduced by Wave 23 §23.B.10. Do not run it ad-hoc; out-of-band
> bumps short-circuit the dependent-action review policy of `ci-security`.

## Inputs

- All `.github/workflows/*.yml` and `.specify/templates/workflows/*.yml`
- The `ci-security.instructions.md` policy file
- The pin baseline `enterprise-sdd/_audit/CI-PIN-BASELINE.md` (created on first
  run if absent)

## Procedure

1. **Inventory.** List every `uses:` reference and its current pin SHA + version
   comment. Group by repository.

2. **Resolve latest.** For each pinned action, fetch the latest stable release
   tag and resolve it to a 40-char SHA via `gh api repos/<owner>/<repo>/git/refs/tags/<tag>`.

3. **Diff and triage.** For each action where the upstream SHA differs from the
   pin:
   - Pull the comparison: `gh api repos/<owner>/<repo>/compare/<old-sha>...<new-sha>`
   - Summarise the changes: file count, lines changed, security-relevant files
     (anything under `dist/`, `lib/`, `src/`, `action.yml`).
   - Classify: 🟢 trivial / 🟡 review / 🔴 blocked.

4. **Propose.** Emit a markdown table:

   | Action | From | To | Severity | Recommendation |
   |--------|------|----|---------|----------------|
   | actions/checkout | v4.2.2 | v4.2.3 | 🟢 | Bump |

5. **Approval gate.** STOP and wait for explicit human approval per row. Do not
   batch-approve. Do not auto-apply.

6. **Apply.** For approved rows, edit the workflow file in place: replace the
   SHA, update the version comment. Re-run `sdd doctor --ci-action-pin` to
   confirm the gate passes.

## Example Action Upgrade

```yaml
# Before
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
# After (approved on 2026-06-11)
- uses: actions/checkout@a1b2c3d4e5f60718293a4b5c6d7e8f9001020304 # v4.2.3
```

## Output

- Updated workflow files (only for approved rows)
- Appended row in `enterprise-sdd/_audit/CI-PIN-BASELINE.md` with the new SHA,
  the diff link, the approver, and the date.
