---
applyTo: "**/*.{tsx,ts,jsx}"
---
# Component Ambiguity Resolution Protocol

## Purpose

When a UI implementation choice changes behavior materially, force the operator or agent to STOP, record the ambiguity, and resolve it before proceeding.

## When This Protocol Activates

An ambiguity exists when:

1. **Multiple Stratos components** could fulfill the same UI need (e.g., `Select` vs. `Autocomplete`, `Modal` vs. `Drawer`, `Tabs` vs. accordion)
2. **A data-entry pattern** has behavioral implications (e.g., inline edit vs. form page, optimistic vs. pessimistic update)
3. **A layout choice** affects user workflow (e.g., master-detail vs. separate pages, wizard vs. single form)
4. **A state location** could be local, store, or URL-driven with different UX consequences

## Resolution Steps

### Step 1 — Detect and STOP

When generating or reviewing code and encountering any of the above, **stop implementation** immediately.

### Step 2 — Record the Ambiguity

Write the following to the feature's `decisions.md`:

```markdown
## UI Ambiguity: [Short title]

**Date:** [ISO date]
**Component/Pattern:** [What needs to be decided]
**Options:**
1. [Option A] — [behavioral impact]
2. [Option B] — [behavioral impact]

**Evidence needed:** [What information would resolve this]
**Current recommendation:** [Option N] because [rationale]
**Status:** PENDING | RESOLVED
```

### Step 3 — Resolve

- In `standard` mode: wait for operator decision
- In `autonomous-guided` mode: present options + recommendation, wait for approval
- In `autonomous-governed` mode: if confidence >= escalation threshold, apply recommendation and log evidence; otherwise escalate

### Step 4 — Proceed

Only after the decision is recorded with status `RESOLVED` in `decisions.md`, proceed with implementation using the chosen option.

## Common Ambiguity Patterns

| Pattern | Options | Default Recommendation |
|---------|---------|----------------------|
| Dropdown vs. Autocomplete | `Select` (small list) vs. `Autocomplete` (>15 items) | `Select` if ≤15 items |
| Modal vs. Drawer | `Modal` (blocking) vs. `Drawer` (contextual) | `Modal` for create/confirm; `Drawer` for detail view |
| Inline edit vs. Form page | Edit in table row vs. navigate to edit page | Form page for >3 fields |
| Tabs vs. Accordion | `Tabs` (parallel sections) vs. Accordion (sequential) | `Tabs` for ≤5 sections |
| Single-step vs. Wizard | One form vs. multi-step wizard | Single form if ≤8 fields |
| Optimistic vs. Pessimistic | Immediate UI update vs. wait for server | Pessimistic for financial data |
| DateField vs. RangeField | `DateField` (single date) vs. `RangeField` (from/to) | `DateField` unless range is required by AC |
| Table vs. DataGrid | `Table` (read-only display) vs. `DataGrid` (sort/filter/edit) | `Table` for ≤5 columns read-only; `DataGrid` for interactive data |

## Enforcement

- Gate validation must check: no unresolved ambiguities in `decisions.md`
- Agents must not guess when multiple Stratos components could apply
- Review agents must flag unreported ambiguities as `medium` severity findings
