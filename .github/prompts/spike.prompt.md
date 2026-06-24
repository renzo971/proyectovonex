---
mode: agent
description: "Structured spike/experiment template for time-boxed feasibility investigations before entering the SDD pipeline."
---

# Spike: {{SPIKE_NAME}}

> **Purpose:** Investigate a technical hypothesis with a time-boxed experiment BEFORE entering the formal SDD specification pipeline. Spike code is disposable — findings feed into specs, not production.

---

## Hypothesis

<!-- What do you believe to be true? What are you trying to prove or disprove? -->

- **Claim:** [State the hypothesis clearly]
- **Why it matters:** [What decision depends on this answer?]

---

## Approach

<!-- How will you investigate? What will you build, test, or measure? -->

1. [Step 1]
2. [Step 2]
3. [Step 3]

**Tools / Libraries / APIs to evaluate:**
- [List any technologies being explored]

---

## Success Criteria

<!-- How will you know the spike succeeded? Define measurable outcomes. -->

| # | Criterion | Target | Result |
|---|-----------|--------|--------|
| 1 | [e.g., API responds within 200ms] | [target value] | ⬜ Not tested |
| 2 | [e.g., Library supports our auth model] | [target value] | ⬜ Not tested |
| 3 | [e.g., Data format is compatible] | [target value] | ⬜ Not tested |

---

## Time-box

- **Maximum duration:** [e.g., 4 hours / 1 day]
- **Started:** [date]
- **Deadline:** [date]
- **Wrap-up trigger:** Time expires OR all success criteria have a result

---

## Findings

<!-- Fill this section after the spike is complete. Use `sdd spike wrap <slug>` to finalize. -->

### What We Learned
- [Key finding 1]
- [Key finding 2]

### Recommendation

- [ ] **Proceed** — hypothesis confirmed, create a feature spec
- [ ] **Pivot** — partially confirmed, adjust approach and re-spike
- [ ] **Abandon** — hypothesis disproved, document why and move on

### Artifacts Produced
<!-- List any code, diagrams, or notes produced during the spike -->
- [File or link 1]
- [File or link 2]

### Feed Into Spec
<!-- If proceeding, which spec artifacts should incorporate these findings? -->
- Constitution updates needed: [yes/no — describe]
- Requirements to create: [US-XXX descriptions]
- Design constraints discovered: [list]
