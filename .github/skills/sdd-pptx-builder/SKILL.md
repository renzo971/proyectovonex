# sdd-pptx-builder

Purpose: generate PowerPoint (.pptx) presentations from structured input using Python standard library only (via `zipfile` and XML manipulation). Supports gate summary presentations.

## Input

A structured specification of the presentation to generate:

```yaml
title: "Gate Review Summary"
output: ".specify/specs/NNN/gate-summary.pptx"
slides:
  - title: "Feature Overview"
    bullets:
      - "Feature: Order Management System"
      - "Status: Gate 3 — Implementation Complete"
      - "Sprint: 2026-Q2-S3"
  - title: "Requirements Coverage"
    bullets:
      - "5 User Stories — 100% implemented"
      - "12 Acceptance Criteria — 11 verified, 1 pending"
      - "3 Non-Functional Requirements — all met"
    table:
      headers: ["Metric", "Target", "Actual"]
      rows:
        - ["Test Coverage", "80%", "87%"]
        - ["p95 Latency", "<200ms", "145ms"]
  - title: "Open Items"
    bullets:
      - "AC-003.2 pending integration test environment"
      - "Security review scheduled for next sprint"
```

## Generation Approach

Use Python stdlib only — no `python-pptx` or external libraries.

A `.pptx` file is a ZIP archive containing XML files conforming to the PresentationML specification. The minimal structure:

```
[Content_Types].xml
_rels/.rels
ppt/presentation.xml
ppt/_rels/presentation.xml.rels
ppt/slides/slide1.xml
ppt/slides/_rels/slide1.xml.rels
ppt/slideLayouts/slideLayout1.xml
ppt/slideMasters/slideMaster1.xml
```

### Elements & Modes

- Supported: title slides, bullet points, tables, slide numbers
- Gate summary mode: auto-generates 5 slides (overview, coverage, metrics, risks, timeline)
- Limitations: No images, charts, animations, custom themes. Users may post-edit.

## Execution Flow

1. Parse the structured input (YAML or JSON).
2. Generate slide XML for each slide entry.
3. Generate presentation XML with slide references.
4. Generate minimal slide layout and slide master.
5. Package into a ZIP file with `.pptx` extension.
6. Write to the specified output path.

## Output Contract

Produce a generation report with: format (PPTX), output path, slide/table counts, status (SUCCESS / FAILED), and a slide summary table.
