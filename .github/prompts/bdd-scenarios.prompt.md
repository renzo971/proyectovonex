---
description: Create BDD/Gherkin test scenarios from user stories
mode: agent
---

**Create BDD/Gherkin scenarios** for the specified user stories.

Invoke `@gherkin-analyst` to run the 6-phase BDD workflow:

1. **Input Gathering** — provide user story references (e.g., US-001)
2. **Analysis** — agent reads spec.md and extracts acceptance criteria
3. **Gap Identification** — agent asks clarifying questions (P1/P2/P3)
4. **Scenario Drafting** — positive/happy-path scenarios first
5. **Education & Review** — learn why each scenario matters
6. **Save & Deliver** — `.feature` files saved to `tests/features/`

All scenarios are tagged with `@US-XXX` and `@AC-XXX` for traceability.
Prefers `Scenario Outline` with `Examples` tables for parameterized tests.
