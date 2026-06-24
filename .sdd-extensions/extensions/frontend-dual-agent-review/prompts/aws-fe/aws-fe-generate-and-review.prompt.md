---
mode: agent
description: "Execute a generate-then-review cycle using Neo generator followed by Smith reviewer"
---
# Generate and Review Cycle

Execute a two-phase workflow: first generate frontend code using the **Neo generator** profile, then review it using the **Smith reviewer** profile.

## Instructions

Read before executing:
- `agent-patches/agent-neo-generator.patch.md` for generation behavior
- `agent-patches/agent-smith-reviewer.patch.md` for review behavior
- All referenced instruction files from both patches

## Input

Provide:
1. **Feature description** — what to implement
2. **Feature ID** (SDD feature context)
3. **Scope** — which files/components to generate
4. **Constraints** — any specific requirements or limitations

## Phase 1: Generate (Neo Profile)

1. Read feature context (spec, design, tasks)
2. Align models and API contracts first
3. Generate component files following MFE structure
4. Generate test files for every component
5. Record any UI ambiguities in `decisions.md`
6. Use Stratos tokens exclusively

## Phase 2: Review (Smith Profile)

1. Review all generated files against project rules
2. Check architecture, token compliance, state management, testing
3. Report findings by severity
4. Fill out branch-diff-review-checklist

## Phase 3: Remediate

1. Fix all `high` severity findings immediately
2. Fix `medium` findings if within scope
3. Document `low` findings for later iteration
4. Re-run review after fixes to confirm resolution

## Output

Deliver:
1. Generated code files
2. Generated test files
3. Review report with findings and fixes
4. Updated `decisions.md` with any ambiguity resolutions
5. Final review checklist (all checks passing)

## Mode Compatibility

- **Standard:** Interactive generation + review + fix cycle
- **Autonomous-guided:** Generate → review → present findings → wait for approval → fix
- **Autonomous-governed:** Generate → review → auto-fix high/medium → escalate if unresolved
