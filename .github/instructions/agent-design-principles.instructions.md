---
applyTo: ".github/agents/**"
description: Six codified principles for designing effective AI agents in Enterprise SDD
---

## Agent Design Principles

Every agent MUST satisfy these six principles:

1. **Less Is More** — one job, one phase, one clear sentence of purpose.
2. **Explicit Boundaries** — define Always Do, Ask First, and Never Do sections.
3. **Failure Behavior** — specify escalation triggers, owner, and residual state.
4. **Template Discipline** — primary artifacts use structured templates, not free-form prose.
5. **Tool Minimalism** — request only the tools required for the agent's real job.
6. **Handoff Clarity** — use `send: false`, define trigger, contract, and prompt.

Use the quick test for scope: if you need the word "and" to explain the purpose, the agent is too broad.

See [agent-design-rationale.instructions.md](agent-design-rationale.instructions.md) for detailed rationale, tool guidance, and handoff examples.

For the ordered activation-sequence guardrail (mandatory-startup-files, never-infer, per-step confirmation), see [agent-activation-discipline.instructions.md](agent-activation-discipline.instructions.md) (Wave 27 §26 #5).
