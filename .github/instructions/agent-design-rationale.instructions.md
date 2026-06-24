---
applyTo: ".github/agents/**"
description: Detailed rationales and examples for the six agent design principles
---

# Agent Design Principle Rationales

See [agent-design-principles.instructions.md](agent-design-principles.instructions.md) for the principles summary.

## Principle 2: Explicit Boundaries (Detailed)

Every agent MUST define three boundary rule sections:

- **Always Do** — Mandatory behaviors the agent follows in every invocation
- **Ask First** — Actions the agent proposes but requires human approval before executing
- **Never Do** — Hard prohibitions the agent must not violate under any circumstances

Boundary rules are the primary mechanism for preventing agent scope creep and ensuring predictable behavior.

## Principle 3: Failure Behavior (Detailed)

Define what the agent does when it **cannot complete its task**:

- What triggers an escalation? (missing artifacts, low confidence, contradictions)
- Who does it escalate to? (human operator, another agent, gate failure)
- What state does it leave behind? (partial artifact, error report, nothing)

An agent that silently produces partial or incorrect output is worse than one that stops and explains why.

## Principle 4: Template Discipline (Detailed)

Agent outputs must use **structured templates**, not free-form prose:

- Primary artifacts use named templates from `.specify/templates/`
- Reports follow section-based layouts with consistent headings
- Data outputs use tables, structured lists, or JSON — not paragraphs

Free-form output is acceptable only for conversational responses (clarification Q&A). Deliverable artifacts always follow templates.

## Principle 5: Tool Minimalism (Detailed)

Request only the tools the agent actually needs:

- `read` — for agents that analyze but don't change files
- `read, edit` — for agents that produce or modify artifacts
- `read, edit, search` — for agents that need to find files across the workspace
- `read, edit, search, run` — only for agents that execute commands (testing, building)

Never request `fetch` (external network access) unless the agent's core function requires it. Read-only agents must never have `edit` access.

## Principle 6: Handoff Clarity (Detailed)

Every agent that transitions work to another agent must:

1. Use `send: false` on all handoffs (human-in-the-loop by default)
2. Document the handoff contract: what the next agent expects to receive
3. Specify the handoff trigger: when the transition should happen
4. Include a handoff prompt template with context variables

Example:
```yaml
handoffs:
  - label: Submit for Review
    agent: review
    prompt: |
      Implementation complete for feature {{featureId}}.
      Files changed: {{changedFiles}}
      Test results: {{testSummary}}
    send: false
```
