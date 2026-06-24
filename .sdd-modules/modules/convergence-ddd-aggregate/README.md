# convergence-ddd-aggregate

> **⚠️ Scope Constraint:** This module is for **DDD contexts only**. Do not activate if your project does not use aggregate-based domain modeling (Domain-Driven Design). Activating this module in a non-DDD context adds no value and may introduce confusion.

---

## Overview

`convergence-ddd-aggregate` is an **optional** Enterprise SDD module that provides DDD aggregate boundary decision support. It is harvested from the VORTEX framework's `ddd-aggregate-design` skill analysis, adapted to the SDD module system and philosophy.

### What it provides

| Asset | File | Purpose |
|-------|------|---------|
| Skill | `skills/ddd-aggregate-design.skill.md` | Invariant-first aggregate boundary analysis with anti-pattern detection |
| Template | `templates/aggregate-decision-record-template.md` | Structured ADR for aggregate boundary decisions |

### What it does NOT provide

- No agents — aggregate design is a **skill** invoked within Gate 2, not a standalone phase
- No instructions — DDD-specific conventions stay in the module, not in core SDD instructions
- No automation — this is a human-guided decision framework, not an automated boundary detector

---

## Activation

### Install the module

```bash
sdd module add convergence-ddd-aggregate
```

### Verify activation

```bash
sdd module list
# Expected: convergence-ddd-aggregate  v1.0.0  optional  [active]
```

### Run the skill for a feature

```bash
sdd skill run ddd-aggregate-design <feature-id>
```

The skill output will be written to `.specify/specs/<feature-id>/aggregate-decision-record.md`.

---

## When to Use

Use this module when:

- Your project explicitly models domain aggregates with bounded contexts
- Gate 2 (design complete) requires aggregate boundary documentation
- An architecture review has flagged aggregate ambiguity or a God Aggregate risk
- A tech lead wants an auditable record of DDD design decisions for a feature

Do **not** use this module when:

- The project is CRUD-only with no domain invariants
- The team does not use Domain-Driven Design
- Aggregate boundaries are already well-established and not under review for this feature

---

## Skill Workflow

The `ddd-aggregate-design` skill follows a five-step process:

1. **Identify aggregate candidates** from domain entities in the spec
2. **Apply invariant-first boundary test** to each candidate
3. **Check anti-patterns** (God Aggregate, Anemic Aggregate, Cross-Aggregate Reference, etc.)
4. **Complete the decision matrix** with trade-off records
5. **Produce the Aggregate Decision Record** artifact

---

## SDD Philosophy Compliance

This module was designed to respect all 9 SDD inviolable constraints:

| Constraint | Compliance |
|-----------|:----------:|
| Constitution supremacy | ✅ Module does not override constitution |
| Gate integrity | ✅ Skill produces Gate 2 evidence; does not bypass gates |
| Traceability | ✅ ADR artifact is citable in gate evidence |
| Template discipline | ✅ Structured ADR template enforces consistent output |
| Boundary rules | ✅ Skill has explicit step-by-step flow |
| Additive evolution | ✅ Optional module; no changes to core SDD |
| Team-oriented | ✅ ADR is a shared, auditable team artifact |
| Tech-agnostic core | ✅ DDD knowledge stays in this optional module |
| Human-readable | ✅ Markdown skill + template; no binaries |

---

## Version History

| Version | Date | Notes |
|---------|------|-------|
| 1.0.0 | April 24, 2026 | Initial release — Wave 19 VORTEX harvest |
