---
mode: agent
description: "Scaffold a complete search feature with form, results table, and status badge"
---
# Scaffold Enterprise Search Feature

You are scaffolding a complete enterprise search feature for a React frontend using Stratos components.

## Instructions

Read before generating:
- `fe-advanced-search-form.instructions.md` for the search form architecture
- `fe-advanced-search-results.instructions.md` for the results page architecture
- `fe-item-status-badge.instructions.md` for the status badge pattern
- `fe-stratos-design-tokens.instructions.md` for Stratos token usage
- `fe-frontend-state-decision-tree.instructions.md` for state placement

## Input

Provide:
1. **Feature name** (e.g., "Instruction", "Settlement", "Security")
2. **Search criteria fields** — list of: name, type (text/date/dropdown/boolean/numeric-range), label
3. **Result table columns** — list of: key, label, sortable (yes/no), render type (text/badge/date/link)
4. **Status values** — list of statuses with their color mapping (if applicable)

## Output

Generate the following file structure:

```
src/models/<feature>-search.ts              ← SearchModel, TaxonomyModel, PagingModel, OptionModel
src/pages/<feature>-search/
├── <Feature>SearchTab/
│   ├── <Feature>SearchForm/
│   │   ├── <Feature>SearchForm.tsx
│   │   └── <Feature>SearchForm.test.tsx
│   ├── <Feature>SearchDates/               ← if date fields exist
│   │   ├── <Feature>SearchDates.tsx
│   │   └── <Feature>SearchDates.test.tsx
│   ├── <Feature>SearchIdentification/      ← text/id section
│   │   ├── <Feature>SearchIdentification.tsx
│   │   └── <Feature>SearchIdentification.test.tsx
│   └── <Feature>SearchSubmitButton/
│       ├── <Feature>SearchSubmitButton.tsx
│       └── <Feature>SearchSubmitButton.test.tsx
├── <Feature>SearchPage/
│   ├── <Feature>SearchPage.tsx
│   └── <Feature>SearchContent/
│       ├── <Feature>SearchContent.tsx
│       └── <Feature>SearchContent.test.tsx
├── <Feature>SearchChips/
│   ├── <Feature>SearchChips.tsx
│   └── <Feature>SearchChips.test.tsx
└── <Feature>StatusBadge/                   ← if status column
    ├── <Feature>StatusBadge.tsx
    └── <Feature>StatusBadge.test.tsx
```

## Constraints

- Follow the `handleChange` prop-passing pattern (no custom hooks for form plumbing)
- Use Stratos design tokens for all spacing/colors
- Use Stratos `Badge` with a `colorMap` for status rendering
- Pagination: UI is 1-indexed, API is 0-indexed
- Every component gets its own test file
