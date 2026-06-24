# sdd-docx-builder

Purpose: generate Word (.docx) documents from structured Markdown input using Python standard library only (via `zipfile` and XML manipulation).

## Input

A structured specification of the document to generate:

```yaml
title: "Feature Specification Report"
output: ".specify/specs/NNN/report.docx"
sections:
  - heading: "Executive Summary"
    level: 1
    body: "Markdown text content..."
  - heading: "Requirements"
    level: 1
    body: "..."
    table:
      headers: ["ID", "Description", "Status"]
      rows:
        - ["US-001", "User login", "✅"]
        - ["US-002", "Password reset", "🟡"]
  - heading: "Architecture"
    level: 1
    body: "..."
```

## Generation Approach

Use Python stdlib only — no `python-docx` or external libraries.

A `.docx` file is a ZIP archive containing XML files conforming to the Office Open XML (OOXML) standard. The minimal structure:

```
[Content_Types].xml
_rels/.rels
word/document.xml
word/_rels/document.xml.rels
word/styles.xml
```

### Supported Elements

- Headings (H1–H3), body text, bold/italic, tables, bullet lists, page breaks

### Limitations

No images, complex formatting, headers/footers. Output is functional; users may post-edit in Word.

## Execution Flow

1. Parse the structured input (YAML or JSON).
2. Build the XML document body from sections.
3. Generate supporting XML files (styles, content types, rels).
4. Package into a ZIP file with `.docx` extension.
5. Write to the specified output path.

## Output Contract

Produce a generation report with: format (DOCX), output path, section/table/page counts, status (SUCCESS / FAILED), and a content summary table.
