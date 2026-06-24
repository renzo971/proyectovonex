---
applyTo: ".specify/**,.github/agents/**"
description: Exact markdown format, worked examples, and priority-tier tags for structured questions
---

# Structured Question Format Detail

See [question-format.instructions.md](question-format.instructions.md) for the always-on contract.

## Exact Markdown Shape

```markdown
## [Topic or Context Header]

### **Q1. [Question text]**
- **a)** [Option 1] (trade-off or implication)
- **b)** [Option 2] (trade-off or implication)
- **c)** [Option 3] (trade-off or implication)
- **d)** Other: [Please specify]
```

## Example: Single Decision

```markdown
## Authentication Strategy

### **Q1. [P1] Should we use session-based or token-based authentication?**
- **a)** Session-based with Redis store (simpler, stateful)
- **b)** JWT access and refresh tokens (stateless, more complex)
- **c)** OAuth2 delegation only (less control, lower local burden)
- **d)** Other: [Please specify]
```

## Example: Multiple Questions

```markdown
## Data Model Design

### **Q1. [P1] Should audit history stay in the same table or a separate one?**
- **a)** Same table with soft deletes (simpler queries, table growth)
- **b)** Separate audit table (cleaner primary model, joins for history)
- **c)** Event sourcing (full history, highest complexity)
- **d)** Other: [Please specify]

### **Q2. [P2] What granularity for audit timestamps?**
- **a)** Seconds (sufficient for most use cases)
- **b)** Milliseconds (recommended for higher throughput)
- **c)** Microseconds (ordering guarantee focus)
- **d)** Other: [Please specify]
```

## Tier Semantics

- `P1`: answer required before dependent work proceeds.
- `P2`: recommended default allowed, but assumption must be documented.
- `P3`: batch or defer if a stable convention exists.
