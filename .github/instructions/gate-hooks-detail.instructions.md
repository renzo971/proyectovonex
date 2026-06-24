---
applyTo: ".specify/**,.github/agents/**"
description: Gate hook configuration schema, execution detail, and advanced hook contracts
---

# Gate Hooks Detail

See [gate-hooks.instructions.md](gate-hooks.instructions.md) for the always-on contract.

## Configuration Shape

```json
{
	"gateHooks": {
		"gate_1": { "on_pass": ["notify"], "on_fail": ["notify"] },
		"gate_2": { "on_pass": ["auto-commit", "notify"] },
		"gate_4": { "on_pass": ["auto-commit", "export-report", "notify"] }
	}
}
```

## Auto-Commit Format

```text
sdd: gate <N> passed for <feature-slug>

Artifacts: [list of staged files]
Verdict: PASS [WITH WARNINGS]
```

## Trigger-Next Mapping

| Gate Passed | Next Phase | Suggested Agent |
|-------------|------------|-----------------|
| Gate 1 | Design | `@architect` |
| Gate 2 | Preparation | `@test-explorer` |
| Gate 3 | Implementation | `@software-engineer` |
| Gate 4 | Ship | `@review` -> `sdd ship` |

In `autonomous-governed` mode, `trigger-next` may auto-start the next step. In other modes it prints a suggestion.

## CLI Usage

```bash
sdd gate 001 2 --hooks
```

## Advanced Hooks

- `skill-eval-verify`: runs `sdd skill validate <skill> --eval` for curated skills that ship `.sdd-eval.yaml` and writes `.specify/reports/SKILL-EVAL-REPORT.md`.
- `post-merge-verify`: runs `sdd gate post-merge <feature-id>` against the post-merge tree, writes `POST-MERGE.md` on success and `INCIDENT.md` on failure, and never auto-reverts.
