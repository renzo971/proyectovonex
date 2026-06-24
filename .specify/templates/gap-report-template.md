# Gap Report: [FEATURE_NAME]

**Feature ID:** [NNN]-[feature-slug]
**Generated:** [TIMESTAMP]
**Analysis Mode:** Gap-Closure (reverse traceability)

---

## Summary

| Category | Gaps Found | Severity |
|----------|:----------:|:--------:|
| Coverage Gaps | [count] | [High/Medium/Low] |
| Decision Gaps | [count] | [High/Medium/Low] |
| Wiring Gaps | [count] | [High/Medium/Low] |
| **Total** | **[count]** | **[overall]** |

**Verdict:** [PASS — no gaps | PASS with warnings — minor gaps | BLOCK — critical gaps]

---

## 1. Coverage Gaps

<!-- Requirements or constitution decisions that have NO corresponding AC/TC/Task -->
<!-- Each gap = a requirement that was silently dropped during spec decomposition -->

| # | Requirement Source | Requirement Text | Missing From | Severity |
|---|-------------------|------------------|--------------|----------|
| 1 | [constitution / business-context / external] | [requirement text] | [AC / TC / Task] | [High/Med/Low] |

**Impact:** [Brief assessment of what happens if these gaps are not addressed]

---

## 2. Decision Gaps

<!-- Documented decisions (constitution, ADRs, design artifacts) with NO implementation task -->
<!-- Each gap = a decision that was made but never translated into actionable work -->

| # | Decision Source | Decision Text | Missing From | Severity |
|---|---------------|---------------|--------------|----------|
| 1 | [constitution / ADR / plan.md] | [decision text] | [Task / AC] | [High/Med/Low] |

**Impact:** [Brief assessment of what happens if these decisions are not implemented]

---

## 3. Wiring Gaps

<!-- Cross-feature or cross-phase dependencies that are NOT explicitly linked -->
<!-- Each gap = a dependency that exists but is not tracked, risking integration failures -->

| # | Source Feature/Phase | Dependency | Target Feature/Phase | Link Status | Severity |
|---|---------------------|------------|---------------------|-------------|----------|
| 1 | [feature/phase A] | [what depends on what] | [feature/phase B] | [missing / implicit] | [High/Med/Low] |

**Impact:** [Brief assessment of integration risk from unwired dependencies]

---

## Recommendations

<!-- Prioritized list of actions to close the identified gaps -->

1. [Most critical gap to address first]
2. [Second priority]
3. [Third priority]
