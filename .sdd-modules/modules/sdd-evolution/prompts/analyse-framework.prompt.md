---
name: 'analyse-framework'
description: 'Analyse an AI agent framework and produce a structured ANALYSIS.md document'
argument-hint: 'Path to the framework directory to analyse (e.g., ./my-framework/)'
agent: 'framework-analyst'
---

# Analyse AI Agent Framework

## Goal

Produce a comprehensive `{FRAMEWORK-NAME}-ANALYSIS.md` document that dissects the given AI agent framework's architecture, components, workflows, and trade-offs.

## Context

### Framework to analyse

```text
$ARGUMENTS
```

### Reference template

Use the analysis template from `templates/analysis-template.md` as the structural skeleton. Every section in the template must appear in the output.

## Process

1. **Discovery** — Read every file in the framework directory. Do not skip or summarise from filenames alone.
2. **Classify** — Assign each file to a category (Agent, Instruction, Prompt, Skill, Plugin, Config, Guide, Template, Example).
3. **Analyse** — Extract insights for each template section.
4. **Write** — Generate the complete document following the template structure.
5. **Validate** — Verify every section is present, component catalog is complete, and Mermaid diagrams are valid.

## Output

A single Markdown file: `_evolution/{FRAMEWORK-NAME}-ANALYSIS.md`.

## Rules

- Read every file before writing. Never infer content from filenames.
- Be exhaustive in the Component Catalog.
- Be analytical, not promotional.
- Use Mermaid diagrams for architecture and workflow visualisations.
