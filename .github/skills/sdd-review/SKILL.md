---
name: sdd-review
namespace: true
keyword-tags: [injection, malicious-code, source-verification, citation, rtc, return-to-context, supply-chain, secrets, security-review]
description: Phase 5 (Review) namespace meta-skill — injection, malicious-code, citations, RTC.
---

# sdd-review (namespace meta-skill)

Purpose: lightweight router for Phase 5 review work.

## When to Use

- Reviewing a feature before Gate 3 or Gate 4.
- The user mentions security, supply chain, citations, or reasoning quality.
- The diff includes external dependencies, copy-pasted snippets, or unverified claims.

## Routed Sub-Skills

| Trigger keywords | Sub-skill | Purpose |
|------------------|-----------|---------|
| `injection`, `prompt injection`, `untrusted input` | (uses `injection-scan` instruction) | Injection scanning is in `injection-scan.instructions.md` |
| `malicious`, `obfuscated`, `eval`, `dynamic load` | `malicious-code-detection` | Detect malicious code patterns |
| `supply-chain`, `dependency`, `lockfile`, `transitive` | `supply-chain-risk` | Supply-chain risk assessment |
| `secret`, `credential`, `api key`, `token` | `secrets-scan` | Scan for secret leakage |
| `citation`, `source`, `claim`, `external knowledge` | `source-citation-check` / `source-verification` | Verify cited sources |
| `rtc`, `return-to-context`, `reasoning` | (uses `rtc-reasoning` instruction) | RTC reasoning is in `rtc-reasoning.instructions.md` |
| `stub`, `placeholder`, `TODO`, `not implemented` | `stub-scan` | Detect stub/placeholder code left in the diff (Wave 24) |
| `red-team review`, `adversarial review` | `red-team-spec` | Adversarial review |

## Invocation Guidance

1. Run `secrets-scan` and `injection-scan` on every diff — non-negotiable.
2. Run `supply-chain-risk` whenever dependencies change.
3. Run `source-citation-check` when external claims appear in the diff or spec.

## Boundary

- Never approve a Gate without running the mandatory scans.
- Never silently downgrade a CRITICAL finding — escalate per `escalation-protocol`.
