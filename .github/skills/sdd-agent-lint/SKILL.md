# sdd-agent-lint

Purpose: verify agent and instruction files for structural correctness, convention compliance, and quality standards.

## Input

- Target path: a single agent file, instruction file, or directory to scan
- If no path provided, scan all files in `.github/agents/` and `.github/instructions/`

## Checks

### Agent Checks

| # | Check | Severity | Rule |
|---|-------|----------|------|
| AG-01 | YAML frontmatter present and valid | FAIL | Must start with `---` and contain valid YAML |
| AG-02 | Required fields: `name`, `description`, `tools`, `phase` | FAIL | All four fields must exist |
| AG-03 | `send: false` on all handoffs | FAIL | Human-in-the-loop enforcement |
| AG-04 | Boundary rules (Always/Ask/Never) present | FAIL | All three sections must exist |
| AG-05–10 | Concrete rules, size tier, identity, artifact, naming | WARN | Style and convention checks |

### Instruction Checks

| # | Check | Severity | Rule |
|---|-------|----------|------|
| IN-01 | YAML frontmatter with `applyTo` glob | FAIL | Must specify activation scope |
| IN-02–06 | Valid glob, actionable content, naming, min length | WARN | Structural quality checks |
| IN-07 | Instruction wiring check | WARN | Must have valid `applyTo` or explicit parent-agent reference |
| IN-08 | Version-drift check | WARN | All files in same pack must declare same stack version |

## Execution Flow

1. Identify target files (single file, directory, or default scan).
2. Classify each file as agent (`.agent.md`) or instruction (`.instructions.md`).
3. For each agent file, run checks AG-01 through AG-10.
4. For each instruction file, run checks IN-01 through IN-08.
5. Aggregate results and produce report.

## Verdict Logic

| Condition | Verdict |
|-----------|---------|
| Zero FAIL, zero WARN | **PASS** — all checks passed |
| Zero FAIL, some WARN | **PASS with warnings** — review warnings for improvement |
| Any FAIL | **FAIL** — structural issues must be resolved |

## Output Contract

Produce a report with: files scanned (agents + instructions), verdict (PASS / PASS with warnings / FAIL), results table (file, type, check, severity, status, detail), and actionable recommendations.

## Common Rationalizations

| Rationalization | Correct behavior |
|---|---|
| "Instruction works without `applyTo`" | Add a valid glob; without it the file is silently non-operative in strict mode. |
| "Version drift is cosmetic" | Align all `stack-version` declarations; drift causes contradictory guidance. |
| "I'll lint before the PR" | Lint after creating/modifying any agent or instruction to catch issues early. |
