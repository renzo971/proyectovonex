---
name: policy-author
description: "Author and tighten .sdd-modules/policy.yaml; resolve extends chains; choose allow/deny lists; verify with sdd doctor --policy-preflight (Wave 26 §25 #1)."
---

# policy-author

Author or update an Enterprise SDD module/extension/skill governance policy under
`.sdd-modules/policy.yaml`. See [.specify/schemas/policy.schema.json](../../.specify/schemas/policy.schema.json).

## When to use
- Bootstrapping governance in a new project.
- Tightening an org-wide policy from a project repo via `extends:`.
- Adding a new denied capability.
- Recovering from a `sdd doctor --policy-compliance` finding.

## Process
1. Run `sdd doctor --policy-preflight` to check current state.
2. Decide whether the project needs a policy at all (default-permissive is fine for sandboxes).
3. Pick the `extends:` parent if your org publishes one.
4. Write only the *tighter* set: list what you allow or deny relative to the parent.
5. Re-run `sdd doctor --policy-preflight` then `sdd doctor --policy-compliance`.

## Worked snippets

### 1) Project-only policy (no parent)
```yaml
schema_version: 1
modules:
  allow: [core-be, std-fe]
capabilities:
  deny: [shell-exec]
```

### 2) Tighten an org policy
```yaml
schema_version: 1
extends: ../../org-policy.yaml
modules:
  allow: [core-be]   # intersect: only core-be remains from org allowlist
  deny:  [legacy-fe] # union with org denylist
```

### 3) Hard-block all extensions while still allowing modules
```yaml
schema_version: 1
extends: ../../org-policy.yaml
extensions:
  allow: []   # explicit override → no extensions installable
```

## Verify
```bash
sdd doctor --policy-preflight
sdd module install <id> --explain-policy
sdd doctor --policy-compliance --strict
```

## Common Rationalizations (do not fall for these)
- "I'll just delete `policy.yaml` to unblock the install." → Raise the parent or remove the deny entry instead.
- "The child can re-allow what the parent denied." → No: deny is union, allow is intersect.
- "I'll add `fetch_failure_default: warn` so missing parents don't block." → Only in dev sandboxes; never in prod.
