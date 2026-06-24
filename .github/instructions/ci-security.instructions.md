---
description: CI supply-chain security policy — SHA-pinning, minimum permissions, and dependent-action review for all GitHub Actions workflows.
applyTo: "**/.github/workflows/**"
---

# CI Security Policy (Wave 23 §23.B.11)

> Source: Spec Kit v0.8.6 — every `uses:` reference in committed workflow files
> MUST be SHA-pinned to a 40-character commit hash. Floating tags such as `@v4`
> can be silently re-tagged upstream, rolling unreviewed code into your runner.

## Rule 1 — SHA-pin every action

Every `uses:` MUST match `^[^@]+@[a-f0-9]{40}$` and carry a `# vX.Y.Z` comment.
`sdd doctor --ci-action-pin` (Wave 23 §23.B.12) ERRORs on any floating tag.

```yaml
# CORRECT
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
# WRONG — floating tag, blocked by sdd doctor
- uses: actions/checkout@v4
```

## Rule 2 — Declare minimum-scope permissions

Every workflow MUST declare an explicit top-level `permissions:` block. Default
to `permissions: read-all` and elevate per-job only where strictly required.

```yaml
permissions: read-all
jobs:
  comment:
    permissions:
      pull-requests: write
      contents: read
```

## Rule 3 — Review dependent actions before adding or upgrading

Inspect each action at the pinned SHA before committing; prefer official
`actions/*` and `github/*` namespaces; document non-trivial third-party actions
in `enterprise-sdd/PLAYBOOK.md` § CI Security with the trust rationale.

## Rule 4 — Monthly bump cadence

Run the `sdd-ci-bump` prompt monthly to diff and review upgrade candidates
before updating any pin.
