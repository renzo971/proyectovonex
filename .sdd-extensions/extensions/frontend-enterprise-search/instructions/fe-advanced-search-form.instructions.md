---
applyTo: "src/pages/**/*Search*/**,src/store/**/*search*/**"
---
# Advanced Search Form Pattern

## Purpose

Implement multi-section search forms with consistent structure across any React frontend project using Stratos components.

## Architecture

A search form is composed of five layers:

```
<FeatureTab>                     ← loads taxonomy, wraps with Cover loader
  └── <FeatureSearchForm>        ← orchestrates sections, owns Redux/Zustand dispatch
        ├── <FeatureSearchSectionA handleChange />
        ├── <FeatureSearchSectionB handleChange />
        ├── ...
        └── <FeatureSearchSubmitButton />
```

Each layer has a single responsibility.

## handleChange Contract

The `handleChange` callback is the **only** mechanism for propagating field changes from section components back to state.

1. **Defined once** in `<FeatureSearchForm>` — reads search data from state, spreads with partial update, dispatches
2. **Passed as a prop** to every section component
3. **Called directly** inside each section's `onChange` handlers

**Never** create custom hook files to abstract the `handleChange` logic. Keep it as a plain callback prop.

## Models

### Search Model

Single class containing all search criteria fields:

```typescript
export class FeatureSearchModel {
  // Text fields — initialize as empty string
  textFieldA = '';
  referenceNumber = '';

  // Date range — ISO strings, initialize as empty string
  dateFrom = '';
  dateTo = '';

  // Dropdowns — nullable option models
  category: FeatureSearchOptionModel | null = null;
  status: FeatureSearchOptionModel | null = null;

  // Booleans — initialize as false
  flagA = false;

  // Numeric ranges — nullable
  amountMin: number | null = null;
  amountMax: number | null = null;
}
```

### Taxonomy Model

Arrays of options for all dropdown fields:

```typescript
export class FeatureSearchTaxonomyModel {
  categories: FeatureSearchOptionModel[] = [];
  statuses: FeatureSearchOptionModel[] = [];
}
```

### Naming Convention

- Feature prefix + `Search` suffix: `InstructionSearchModel`, `SettlementSearchTaxonomyModel`
- Option model: `FeatureSearchOptionModel` extending base `EntryModel`

## Form Structure

### File Organization

```
<FeatureSearchTab>/
├── <Feature>SearchForm/
│   ├── <Feature>SearchForm.tsx        ← orchestrator
│   └── <Feature>SearchForm.test.tsx
├── <Feature>SearchDates/
│   ├── <Feature>SearchDates.tsx       ← date range section
│   └── <Feature>SearchDates.test.tsx
├── <Feature>SearchIdentification/
│   ├── <Feature>SearchIdentification.tsx  ← text/id section
│   └── <Feature>SearchIdentification.test.tsx
└── <Feature>SearchSubmitButton/
    ├── <Feature>SearchSubmitButton.tsx
    └── <Feature>SearchSubmitButton.test.tsx
```

### Section Component Pattern

Each section receives `handleChange` and `searchData`:

```tsx
interface FeatureSearchSectionProps {
  handleChange: (partial: Partial<FeatureSearchModel>) => void;
  searchData: FeatureSearchModel;
  taxonomy: FeatureSearchTaxonomyModel;
}

const FeatureSearchDates: FC<FeatureSearchSectionProps> = ({
  handleChange, searchData
}) => (
  <ResponsiveGrid $l="repeat(2, 1fr)" $gap={Space.V16}>
    <DatePicker
      label="From"
      value={searchData.dateFrom}
      onChange={(dateFrom) => handleChange({ dateFrom })}
    />
    <DatePicker
      label="To"
      value={searchData.dateTo}
      onChange={(dateTo) => handleChange({ dateTo })}
    />
  </ResponsiveGrid>
);
```

### Submit Button

Submit button dispatches the search action and closes the form:

```tsx
const FeatureSearchSubmitButton: FC<{ onSubmit: () => void }> = ({ onSubmit }) => (
  <Button
    label="Search"
    variant={ButtonVariant.PRIMARY}
    onClick={onSubmit}
    qa="search-submit"
  />
);
```

## State Management

Search criteria state should use:
- **Zustand store** when search criteria must persist across navigation (list ↔ detail)
- **Local state** when form resets on every navigation
- **URL params** when search must be shareable/bookmarkable

See `fe-frontend-state-decision-tree.instructions.md` for the full decision tree.

## Testing

Each section component gets its own test file:
- Render test: all expected fields present
- Change test: `handleChange` called with correct partial on user input
- Edge case: empty/null values handled correctly
