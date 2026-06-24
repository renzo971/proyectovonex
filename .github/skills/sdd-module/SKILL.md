---
name: sdd-module
namespace: true
keyword-tags: [module, install, update, verify, apm, coexistence, framework-extension]
description: Module operations namespace meta-skill — install, update, verify, APM coexistence.
---

# sdd-module (namespace meta-skill)

Purpose: lightweight router for module-system work (`.sdd-modules/`).

## When to Use

- Installing or updating a SDD module (e.g. `core-be`, `std-fe`, `aws-fe`).
- Verifying module integrity after a pull or merge.
- The user mentions APM coexistence, module drift, or extension management.

## Routed Sub-Skills

| Trigger keywords | Sub-skill | Purpose |
|------------------|-----------|---------|
| `module install`, `add module` | (uses `sdd module install` CLI) | Install a module |
| `module update`, `module upgrade` | (uses `sdd module update` CLI) | Update an installed module |
| `module verify`, `hash baseline`, `drift` | (uses `module_integrity` utility) | Hash-baseline verification |
| `apm`, `agent-package-manager`, `coexistence` | (uses APM coexistence guide) | APM coexistence per `INSTALL-IN-NEW-PROJECT.md` |
| `extension`, `sdd-extension`, `manifest` | (uses `.sdd-extensions/` manifest schema) | Extension manifest checks |

## Invocation Guidance

1. Always run `sdd module verify` after installing or updating a module.
2. For APM coexistence, follow the documented guide before mixing module sources.
3. Extensions are governed by `.sdd-extensions/extensions/<name>/sdd-extension.json`.

## Boundary

- Never modify files inside an installed module by hand — use the module's update path.
- Never bypass hash baselines without recording an `accept-drift` decision (Wave 23 §B).
