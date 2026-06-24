---
applyTo: ".sdd/gates/**,.specify/scripts/**"
description: "Use when: authoring custom quality gates, extending sdd gate with project-specific rules, reviewing custom gate YAML files"
---

## Custom Quality Gates

### Schema — `.sdd/gates/*.yml`

Each YAML file defines one custom gate rule with these fields:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | ✅ | Unique gate identifier (e.g., `no-bare-todo`) |
| `description` | string | ✅ | Human-readable purpose |
| `filePatterns` | glob list | ✅ | Files to scan (e.g., `["src/**/*.ts"]`) |
| `condition` | string | ✅ | Regex pattern or built-in check type |
| `severity` | enum | ✅ | `WARN` or `FAIL` |
| `message` | string | ✅ | Message shown on match |

### How `sdd gate` loads custom gates

1. `sdd gate` auto-discovers all `.sdd/gates/*.yml` files
2. Custom gates run **after** built-in gate checks
3. Each gate scans files matching `filePatterns` for `condition`
4. Results are reported per custom-gate `name`

### Regex sandboxing

To prevent ReDoS (Regular Expression Denial of Service):

- **Timeout:** each regex evaluation is capped at 100ms (configurable)
- **Max length:** regex patterns limited to 200 characters (configurable)
- **Nested quantifiers:** patterns with nested quantifiers (e.g.,
  `(a+)+`) produce a WARN at load time

### Severity semantics

- **WARN:** reported in output, does not block the gate
- **FAIL:** reported in output, blocks the gate (exit code ≠ 0)
