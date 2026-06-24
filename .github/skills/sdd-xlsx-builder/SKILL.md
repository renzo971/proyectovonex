# sdd-xlsx-builder

Purpose: generate Excel (.xlsx) workbooks from structured input using Python standard library only (via `zipfile` and XML manipulation). Supports traceability matrix export.

## Input

A structured specification of the workbook to generate:

```yaml
title: "Traceability Matrix"
output: ".specify/specs/NNN/traceability.xlsx"
sheets:
  - name: "Requirements"
    columns: ["ID", "Description", "Priority", "Status"]
    rows:
      - ["US-001", "User login via SSO", "High", "Complete"]
      - ["US-002", "Password reset flow", "Medium", "In Progress"]
  - name: "Test Coverage"
    columns: ["Test Case", "Requirement", "Result", "Date"]
    rows:
      - ["TC-001", "US-001", "PASS", "2026-04-19"]
      - ["TC-002", "US-002", "FAIL", "2026-04-19"]
```

## Generation Approach

Use Python stdlib only — no `openpyxl` or external libraries.

An `.xlsx` file is a ZIP archive containing XML files conforming to the SpreadsheetML specification. The minimal structure:

```
[Content_Types].xml
_rels/.rels
xl/workbook.xml
xl/_rels/workbook.xml.rels
xl/worksheets/sheet1.xml
xl/sharedStrings.xml
xl/styles.xml
```

### Elements & Modes

- Supported: multiple sheets, string/number cells, bold headers, auto column widths, custom sheet names
- Traceability matrix mode: cross-reference text, coverage gap highlights, summary sheet
- Limitations: values only (no formulas), no formatting/charts/merging. Users may post-edit.

## Execution Flow

1. Parse the structured input (YAML or JSON).
2. Build shared strings table from all cell values.
3. Generate worksheet XML for each sheet.
4. Generate workbook XML with sheet references.
5. Generate styles XML with header bold style.
6. Package into a ZIP file with `.xlsx` extension.
7. Write to the specified output path.

## Output Contract

Produce a generation report with: format (XLSX), output path, sheet/row counts, status (SUCCESS / FAILED), and a sheet summary table.
