---
name: 'compare-frameworks'
description: 'Compare a set of AI agent frameworks and produce a structured COMPARISON.md document'
argument-hint: 'List of ANALYSIS.md files to compare (e.g., FRAMEWORK-A-ANALYSIS.md, FRAMEWORK-B-ANALYSIS.md)'
agent: 'framework-comparator'
---

# Compare AI Agent Frameworks

## Goal

Produce a comprehensive `FRAMEWORK-COMPARISON-{NAME}.md` document that compares the given set of AI agent frameworks across structural, thematic, and strategic dimensions.

## Context

### Analysis documents to compare

```text
$ARGUMENTS
```

### Reference template

Use the comparison template from `templates/comparison-template.md` as the structural skeleton.

## Process

1. **Ingest** — Read every analysis document fully.
2. **Identify themes** — Select 10-14 thematic deep-dives based on the most differentiating dimensions.
3. **Write** — Generate Framework Profiles, Master Comparison Table, Thematic Deep-Dives, Cross-Framework Synthesis, and Strengths & Gaps.
4. **Validate** — Verify all sections present, master table covers all frameworks, each deep-dive has a "Key insight" paragraph.

## Output

A single Markdown file: `_evolution/FRAMEWORK-COMPARISON-{NAME}.md`.

## Rules

- Read every analysis document fully before writing.
- Be exhaustive in the Master Comparison Table (18+ dimensions).
- Use ✅/⚠️/❌ consistently.
- Be opinionated in insights — identify winners and trade-offs.
