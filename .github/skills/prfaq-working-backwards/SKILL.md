# prfaq-working-backwards

Purpose: validate a feature idea before Gate 1 by writing a one-page Press Release with paired FAQ documents (working-backwards style), surfacing assumptions and converting them into explicit acceptance criteria or out-of-scope items before the spec phase begins.

## When to Use

- Before `sdd new` for any non-trivial feature whose value proposition has not been independently verified by a Product Owner.
- Whenever an operator is tempted to "skip directly to spec" on a feature whose target user, success metric, or release moment is fuzzy.
- Operator triggers via `sdd skill run prfaq-working-backwards <feature-id>` (or invokes the skill manually before creating the feature workspace).

## Input

- The proposed feature name and a one-paragraph value hypothesis from the Product Owner.
- Any existing `business-context.md` or upstream Jira/Confluence link (optional — if absent, the skill helps draft the first one).
- Constitution principles under `.specify/memory/constitution.md` (used as guardrails when drafting customer benefits and assumptions).

## Execution Flow

1. Draft the **Press Release** from the customer's point of view, dated at the *intended* launch moment (not today). One page maximum.
2. Draft the **Internal FAQ** — answers to the questions the build team will ask (architecture trade-offs, dependencies, cost model).
3. Draft the **External FAQ** — answers to the questions a customer or partner will ask (pricing, availability, migration path, SLA).
4. Maintain an **Assumptions Log** — every load-bearing claim made in the press release or either FAQ, with status (`open` / `validated` / `out-of-scope`).
5. Produce the **Recommendation** — `proceed` / `proceed-with-caveats` / `pause` / `kill`, with rationale citing the assumptions log.

## Severity Classification

| Severity | Definition | Action |
|----------|------------|--------|
| **Killer assumption** | A claim whose falsification invalidates the entire press release | BLOCK — escalate to PO before `sdd new` |
| **Material assumption** | A claim whose falsification reshapes scope but does not invalidate value | WARN — must become an explicit AC or out-of-scope entry in the spec |
| **Minor assumption** | A claim that affects polish but not value or scope | NOTE — record in `clarifications.md` after spec creation |

## Output Contract

Produce `PRFAQ.md` next to the feature workspace (or in a brainstorming directory pre-creation) with this structure:

```markdown
# PRFAQ — <Feature Name>

## 1. Press Release
- **Headline:** <one line that a customer would tweet>
- **Subhead:** <one-sentence positioning>
- **Launch Date (intended):** <YYYY-MM-DD>
- **Body:** <one to three paragraphs in customer voice>
- **Customer Quote:** <imagined quote from the named customer segment>

## 2. Internal FAQ
- **Q:** <build-team question>
  **A:** <answer>
- ...

## 3. External FAQ
- **Q:** <customer or partner question>
  **A:** <answer>
- ...

## 4. Assumptions Log
| ID | Assumption | Severity | Status | Owner | Resolution |
|----|------------|:--------:|:------:|-------|------------|
| A-01 | <claim> | Killer/Material/Minor | open/validated/out-of-scope | <name> | <how it will be resolved or where it lives> |

## 5. Recommendation
- **Verdict:** proceed | proceed-with-caveats | pause | kill
- **Rationale:** <reference assumption IDs>
- **Next Steps:** <`sdd new <id>`, escalation owner, additional research>
```

## Common Rationalizations

| Rationalization | Correct behavior |
|---|---|
| "Jira ticket suffices" | Reference it in FAQ, but still write press release in customer voice. |
| "Assumptions log is premature" | Record assumptions before Gate 1; convert to AC or out-of-scope later. |
| "Verdict is obvious" | Always emit a verdict line — reviewers need to see it, not infer it. |

## Boundary Rules

- **Always:** write in customer voice; record all assumptions with severity; emit `Verdict:` line.
- **Ask First:** before marking assumption `validated` without citation; before converting to out-of-scope.
- **Never:** validate Killer assumptions without evidence; merge External/Internal FAQ; omit Recommendation block.
