---
description: "Author and tighten Module/Extension/Skill governance policies (Wave 26 §25 #1)."
applyTo: '**/.sdd-modules/policy.yaml'
---

# Module/Extension Governance Policy

> Wave 26 §25 #1 — convergence of Spec Kit #2559 (Agent Governance extension) and APM #1290 (ternary policy inheritance).

Authoritative schema: [.specify/schemas/policy.schema.json](../../.specify/schemas/policy.schema.json).

## Always Do
- Place the project policy at `.sdd-modules/policy.yaml`.
- Set `schema_version: 1`.
- Run `sdd doctor --policy-preflight` after every edit.
- Use `sdd module install <id> --explain-policy` to dry-run decisions.
- Audit existing installs with `sdd doctor --policy-compliance` (add `--strict` in CI).

## Ternary semantics (per `allow`/`deny` list)
- field absent / `null` → **inherit verbatim** from parent.
- `[]` (explicit empty) → **override** parent for that category.
- `[items]` → **explicit list** (allowlists intersect with parent; denylists union with parent).

Result: a child policy can only **tighten**; it can never widen what its parent allows.

## Tighten-only invariant
- `modules.allow: [a, b]` in parent + `modules.allow: [a, c]` in child ⇒ effective `[a]` (intersection).
- `modules.deny: [x]` in parent + `modules.deny: [y]` in child ⇒ effective `[x, y]` (union).

## Org → Project pattern
- Org root policy lives outside the repo and is referenced via `extends: ../../org-policy.yaml`.
- `fetch_failure_default: block` (default) refuses to load if the parent is missing — fail-closed.
- Use `warn` only in dev sandboxes.

## Capability denial
- `capabilities.deny: [shell-exec, network-egress]` refuses any module/skill/extension whose manifest declares those capabilities, regardless of allowlist match.

## Never Do
- Never list the same id in both `allow` and `deny` for one category.
- Never widen the allowlist below an `extends:` parent — it has no effect.
- Never edit `policy.yaml` to bypass a denied install; raise the parent instead.
