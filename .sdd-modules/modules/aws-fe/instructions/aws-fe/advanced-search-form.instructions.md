---
applyTo: "src/pages/**/*Search*/**,src/store/**/*search*/**"
---
# Search Form Pattern

This instruction describes how to implement a multi-section search form following the established pattern in this project (reference implementation: `InstructionSearchTab` in settlement-ui).

---

## Overview

A search form is composed of five layers:

```
<FeatureTab>                     ← loads taxonomy, wraps with Cover loader
  └── <FeatureSearchForm>        ← orchestrates sections, owns Redux dispatch
        ├── <FeatureSearchSectionA handleChange />
        ├── <FeatureSearchSectionB handleChange />
        ├── ...
        └── <FeatureSearchSubmitButton />
```

Each layer has a single responsibility.

**⚠️ MANDATORY — `handleChange` Prop-Passing Pattern**:

The `handleChange` callback is the **only** mechanism for propagating field changes from section components back to Redux. It follows a strict top-down prop-passing flow:

1. **Defined once** in `<FeatureSearchForm>` — reads `searchData` from Redux, spreads it with the partial update, and dispatches `updateSearchData`.
2. **Passed as a prop** to every section component (`<FeatureSearchSectionA handleChange={handleChange} />`).
3. **Called directly** inside each section's `onChange` handlers (`onChange={fieldA => handleChange({ fieldA })}`).

**Never** create custom hook files (e.g., `useFeatureSearchForm.ts`, `useHandleChange.ts`) to abstract or wrap the `handleChange` logic. The pattern is intentionally simple — a plain callback prop — and must remain inline in the Form component.

---

## 1. Models

**Location**: `src/models/<feature>-search.ts`

Create a single file containing all model classes and types needed for the search form. The search form requires three core model components.

### 1.1. Search Option Model

Represents a single dropdown option with optional nested column configurations.

```typescript
import { EntryModel } from './core';

export class FeatureSearchOptionModel extends EntryModel {
  columns?: EntryModel[];
}
```

**Usage**: For dropdown fields that may have associated column configurations.

---

### 1.2. Search Model

Main model representing all search criteria fields. This is the form state.

```typescript
export class FeatureSearchModel {
  // Text/String fields
  textFieldA = '';
  textFieldB = '';
  referenceNumber = '';
  
  // Date range fields (ISO string format)
  dateFieldFrom = '';
  dateFieldTo = '';
  startDateFrom = '';
  startDateTo = '';
  
  // Dropdown fields (nullable option models)
  dropdownFieldA: FeatureSearchOptionModel | null = null;
  category: FeatureSearchOptionModel | null = null;
  status: FeatureSearchOptionModel | null = null;
  
  // Boolean fields
  flagA = false;
  flagB = false;
  
  // Numeric range fields (nullable for empty state)
  amountMin: number | null = null;
  amountMax: number | null = null;
  quantityMin: number | null = null;
  quantityMax: number | null = null;
}
```

**Field Type Guidelines**:
- **Text fields**: Initialize as empty strings (`= ''`) — use `TextField` in the UI **only when the Figma field has a generic free-text placeholder** (e.g., "Enter a value", "Type here")
- **Search fields**: Also stored as empty strings (`= ''`) in the model — use the `Search` component in the UI when applicable (see [stratos.instructions.md](stratos.instructions.md) for when to use `Search` vs `TextField`)
- **Date fields**: Initialize as empty strings (`= ''`), values are ISO date strings
- **Dropdown fields**: Initialize as `null` with type `FeatureSearchOptionModel | null`
- **Boolean fields**: Initialize as `false`
- **Numeric fields**: Initialize as `null` with type `number | null`
- **Numeric range fields**: Create paired fields (e.g., `quantityMin`/`quantityMax`, `amountFrom`/`amountTo`) - these MUST use `CommonRangeNumber` component in the UI

---

### 1.3. Search Taxonomy Model

Contains arrays of options for all dropdown fields in the search form.

```typescript
export class FeatureSearchTaxonomyModel {
  dropdownFieldAOptions: FeatureSearchOptionModel[] = [];
  categories: FeatureSearchOptionModel[] = [];
  statuses: FeatureSearchOptionModel[] = [];
  currencies: FeatureSearchOptionModel[] = [];
  quantityTypes: FeatureSearchOptionModel[] = [];
}
```

**Rules**:
- One array property per dropdown field in `FeatureSearchModel`
- Property name should be plural form of the field name + "Options" or plural domain term
- Initialize as empty arrays

---

### Complete Model File Template

```typescript
import { EntryModel } from './core';

export class FeatureSearchOptionModel extends EntryModel {
  columns?: EntryModel[];
}

export class FeatureSearchModel {
  // Text/String fields
  textFieldA = '';
  textFieldB = '';
  referenceNumber = '';
  
  // Date range fields (ISO string format)
  dateFieldFrom = '';
  dateFieldTo = '';
  startDateFrom = '';
  startDateTo = '';
  
  // Dropdown fields (nullable option models)
  dropdownFieldA: FeatureSearchOptionModel | null = null;
  category: FeatureSearchOptionModel | null = null;
  status: FeatureSearchOptionModel | null = null;
  
  // Boolean fields
  flagA = false;
  flagB = false;
  
  // Numeric range fields (nullable for empty state)
  amountMin: number | null = null;
  amountMax: number | null = null;
  quantityMin: number | null = null;
  quantityMax: number | null = null;
}

export class FeatureSearchTaxonomyModel {
  dropdownFieldAOptions: FeatureSearchOptionModel[] = [];
  categories: FeatureSearchOptionModel[] = [];
  statuses: FeatureSearchOptionModel[] = [];
  currencies: FeatureSearchOptionModel[] = [];
  quantityTypes: FeatureSearchOptionModel[] = [];
}
```

---

### Model Naming Conventions

- **Feature prefix**: Always start with the feature name (e.g., `Instruction`, `Restriction`, `Settlement`)
- **Search suffix**: Add `Search` after the feature name for all search-related models
- **PascalCase**: Use PascalCase for all class and type names
- **Descriptive suffixes**: `Model` for data models, `OptionModel` for dropdown options

**Examples**:
- ✅ `InstructionSearchModel`, `RestrictionSearchTaxonomyModel`, `InstructionSearchOptionModel`
- ❌ `searchModel`, `InstructionSearch`, `SearchOptions`

---

## 2. Folder Structure

Create all files inside `src/pages/<feature>/<FeatureNameSearchTab>/`:

```
<FeatureNameSearchTab>/
├── <FeatureName>SearchDates/
│   ├── <FeatureName>SearchDates.tsx
│   └── <FeatureName>SearchDates.test.tsx
├── <FeatureName>SearchForm/
│   ├── <FeatureName>SearchForm.tsx
│   └── <FeatureName>SearchForm.test.tsx
├── <FeatureName>SearchIdentification/
│   ├── <FeatureName>SearchIdentification.tsx
│   └── <FeatureName>SearchIdentification.test.tsx
├── <FeatureName>SearchSubmitButton/
│   ├── <FeatureName>SearchSubmitButton.tsx
│   └── <FeatureName>SearchSubmitButton.test.tsx
└── <FeatureName>SearchTab/
    ├── <FeatureName>SearchTab.tsx
    └── <FeatureName>SearchTab.test.tsx
```

Add one subfolder per logical section of the form (e.g., Dates, Identification, Quantities, Status, Transaction).
Every component file must have a corresponding `*.test.tsx` file.

---

## 3. Redux Slice

**Location**: `src/store/<feature-name>-search/slice.ts`

### Responsibilities
- Defines typed state class with default values for search form data
- Persists state to `localStorage` on every mutation
- Restores state from `localStorage` on initialisation
- Exports typed action creators and a selector

### Template

```typescript
import { serializable } from '@dap-ui/stratos';
import type { PayloadAction } from '@reduxjs/toolkit';
import { createSlice } from '@reduxjs/toolkit';
import { FeatureSearchModel } from 'models';
import type { RootState } from '../types';

export class FeatureSearchState {
  searchData = new FeatureSearchModel();
}

const STORAGE_KEY = 'featureSearch';

const persistState = (state: FeatureSearchState) => {
  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
};

const retrieveState = () => {
  try {
    const data = window.localStorage.getItem(STORAGE_KEY) || '';
    return JSON.parse(data) as FeatureSearchState;
  } catch {
    return null;
  }
};

const getInitialState = (): FeatureSearchState => {
  const savedState = retrieveState();
  
  if (savedState) {
    return savedState;
  }

  return serializable(new FeatureSearchState());
};

const slice = createSlice({
  name: 'featureSearch',
  initialState: getInitialState(),
  reducers: {
    updateSearchData: (state, action: PayloadAction<FeatureSearchModel>) => {
      state.searchData = action.payload;
      persistState(state);
    },
    resetSearchData: (state) => {
      state.searchData = serializable(new FeatureSearchModel());
      persistState(state);
    },
  },
});

export const { updateSearchData, resetSearchData } = slice.actions;

export const selectFeatureSearchState = (state: RootState) => state.featureSearch;

export default slice.reducer;
```

Register the reducer in `src/store/index.ts` and add the state type to `src/store/types.ts`.

---

## 4. Tab Component (`<FeatureName>SearchTab`)

### Responsibilities
- Loads taxonomy data on mount via `useCover`
- Passes taxonomy down to the form
- Delegates loading/error display to `Cover` + `CommonErrorState`

### Template

```tsx
import { Cover, useCover, useRestoreScrollbar } from '@dap-ui/stratos';
import { getFeatureSearchTaxonomyAPI } from 'api/FeatureSearchAPI';
import CommonErrorState from 'components/CommonErrorState/CommonErrorState';
import { useTranslate } from 'i18n';
import { FeatureSearchTaxonomyModel } from 'models';
import type { FC } from 'react';
import { useEffect, useState } from 'react';
import { selectCsd } from 'store/core/slice';
import { useAppSelector } from 'store/types';
import FeatureSearchForm from '../FeatureSearchForm/FeatureSearchForm';

const FeatureSearchTab: FC = () => {
  const t = useTranslate();
  const restoreScrollbar = useRestoreScrollbar();
  const csd = useAppSelector(selectCsd);
  const [taxonomy, setTaxonomy] = useState(new FeatureSearchTaxonomyModel());

  const { loading, reloadData, errorCode } = useCover(async() => {
    const data = await getFeatureSearchTaxonomyAPI(csd);
    setTaxonomy(data);
  });

  useEffect(() => {
    reloadData();
  }, []);

  useEffect(() => {
    restoreScrollbar();
  }, [loading]);

  return (
    <Cover
      loading={loading}
      text={t('common.loading')}
      loaderTitle={t('common.loading')}
      content={<FeatureSearchForm featureSearchTaxonomy={taxonomy} />}
      errorState={errorCode && (
        <CommonErrorState
          code={errorCode}
          onReload={() => reloadData()}
        />
      )}
    />
  );
};

export default FeatureSearchTab;
```

**Rules**:
- Never put search form fields directly in this component.
- The `useEffect` for `reloadData` uses an empty dependency array intentionally (mount-only).
- The `useEffect` for `restoreScrollbar` depends on `loading` to re-show the scrollbar after load.

---

## 5. Form Component (`<FeatureName>SearchForm`)

### Responsibilities
- Reads `searchData` from Redux via selector
- Defines the `handleChange` callback that dispatches `updateSearchData`
- Composes all section components
- Owns the Clear filters and Submit buttons row

### Props interface

```typescript
export interface FeatureSearchFormProps {
  featureSearchTaxonomy: FeatureSearchTaxonomyModel;
}
```

### Template

```tsx
import {
  Breakpoint, Button, ButtonVariant, HeadingM,
  HorizontalFlex, HorizontalSeparator, Notify, NotifyVariant,
  Space, VerticalFlex,
} from '@dap-ui/stratos';
import { useTranslate } from 'i18n';
import type { FeatureSearchModel, FeatureSearchTaxonomyModel } from 'models';
import type { FC } from 'react';
import { resetSearchData, selectFeatureSearchState, updateSearchData } from 'store/feature-search/slice';
import { useAppDispatch, useAppSelector } from 'store/types';
import FeatureSearchSectionA from '../FeatureSearchSectionA/FeatureSearchSectionA';
import FeatureSearchSectionB from '../FeatureSearchSectionB/FeatureSearchSectionB';
import FeatureSearchSubmitButton from '../FeatureSearchSubmitButton/FeatureSearchSubmitButton';

export interface FeatureSearchFormProps {
  featureSearchTaxonomy: FeatureSearchTaxonomyModel;
}

const FeatureSearchForm: FC<FeatureSearchFormProps> = ({ featureSearchTaxonomy }) => {
  const t = useTranslate();
  const { searchData } = useAppSelector(selectFeatureSearchState);
  const dispatch = useAppDispatch();

  const handleChange = (update: Partial<FeatureSearchModel>) => {
    dispatch(updateSearchData({ ...searchData, ...update }));
  };

  return (
    <VerticalFlex $gap={Space.V24} data-qa="advanced-search-page">
      <HeadingM data-qa="advanced-search-title">
        {t('featureSearchTab.title')}
      </HeadingM>

      <Notify
        text={t('featureSearchTab.notify')}
        variant={NotifyVariant.INFO}
        showMoreLabel={t('common.showMore')}
        showLessLabel={t('common.showLess')}
        qa="advanced-search-info-banner"
      />

      <FeatureSearchSectionA handleChange={handleChange} />
      <HorizontalSeparator />
      <FeatureSearchSectionB
        featureSearchTaxonomy={featureSearchTaxonomy}
        handleChange={handleChange}
      />
      <HorizontalSeparator />

      <HorizontalFlex $gap={Space.V8} $justify="flex-end" $breakpoint={Breakpoint.L}>
        <Button
          label={t('common.clearAllFiltersButton')}
          variant={ButtonVariant.GHOST}
          qa="clear-all-filters"
          onClick={() => dispatch(resetSearchData())}
        />
        <FeatureSearchSubmitButton />
      </HorizontalFlex>
    </VerticalFlex>
  );
};

export default FeatureSearchForm;
```

**Rules**:
- `handleChange` must always spread `searchData` before the partial update so unrelated fields are preserved.
- **MANDATORY**: `handleChange` must be defined as a plain inline function inside the Form component and passed as a prop to every section component. **Never** extract it into a custom hook file (e.g., `useFeatureSearchForm.ts`, `useHandleChange.ts`). The Form component is the single owner of the dispatch logic.
- Sections that need taxonomy receive it as a prop; pure field sections only receive `handleChange`.
- Each section is separated by a `<HorizontalSeparator />`.
- The buttons row uses `$justify="flex-end"` and `$breakpoint={Breakpoint.L}`.

---

## 6. Section Components (e.g., `<FeatureName>SearchSectionA`)

### Responsibilities
- Reads `searchData` from Redux (same selector) to display current values
- Calls `handleChange` with a partial update on every field change
- Contains no dispatch logic of its own
- **Receives `handleChange` as a prop from the parent Form component** — never defines its own dispatch logic or wraps `handleChange` in a local hook

### Props interface

```typescript
export interface FeatureSearchSectionAProps {
  handleChange: (update: Partial<FeatureSearchModel>) => void;
  // Add featureSearchTaxonomy only when the section needs dropdown options
}
```

### Template (text field section)

```tsx
import { HeadingS, ResponsiveGrid, Space, TextField, VerticalFlex } from '@dap-ui/stratos';
import { useTranslate } from 'i18n';
import type { FeatureSearchModel } from 'models';
import type { FC } from 'react';
import { selectFeatureSearchState } from 'store/feature-search/slice';
import { useAppSelector } from 'store/types';

export interface FeatureSearchSectionAProps {
  handleChange: (update: Partial<FeatureSearchModel>) => void;
}

const FeatureSearchSectionA: FC<FeatureSearchSectionAProps> = ({ handleChange }) => {
  const t = useTranslate();
  const { searchData } = useAppSelector(selectFeatureSearchState);

  return (
    <VerticalFlex $gap={Space.V16}>
      <HeadingS>{t('featureSearchTab.sectionATitle')}</HeadingS>
      <ResponsiveGrid $l="repeat(4, 1fr)">
        <TextField
          value={searchData.fieldA}
          label={t('attributes.fields.fieldA')}
          placeholder={t('common.textPlaceholder')}
          qa="field-a"
          onChange={fieldA => handleChange({ fieldA })}
        />
      </ResponsiveGrid>
    </VerticalFlex>
  );
};

export default FeatureSearchSectionA;
```

**Rules**:
- Wrap the section in `<VerticalFlex $gap={Space.V16}>`.
- Use `<HeadingS>` for the section title.
- Use `<ResponsiveGrid $l="repeat(4, 1fr)">` for field layout (adjust column count as needed).
- Each `onChange` passes only the changed field key as a partial object: `fieldName => handleChange({ fieldName })`.
- Section components must NOT dispatch Redux actions directly.
- **MANDATORY — No hook files for `handleChange`**: Section components must receive `handleChange` as a prop from the parent Form component and call it directly in their `onChange` handlers. Do NOT create custom hook files (e.g., `useFeatureSearchSection.ts`) to wrap or re-export `handleChange`. All change-handling logic must stay as a plain prop-passing flow: Form → Section → field `onChange`.
- **MANDATORY**: For numeric range fields, you **MUST** use the `CommonRangeNumber` component (see section 6.1) when:
  - Field names are clearly related pairs: `min`/`max`, `from`/`to`, `start`/`end`, or similar naming patterns
  - Both fields have `number | null` type
  - The fields represent a range or interval (e.g., `settlementQuantityMin`/`settlementQuantityMax`, `amountFrom`/`amountTo`)
  - Do NOT create separate NumberField components for these paired fields

---

### 6.1. CommonRangeNumber Component

**Purpose**: Reusable component for numeric range input fields (min/max, from/to).

**Location**: `src/components/CommonRangeNumber/CommonRangeNumber.tsx`

**⚠️ MANDATORY USAGE**: This component **MUST** be used whenever you have:
- Two related numeric fields representing a range
- Field name patterns like: `fieldNameMin`/`fieldNameMax`, `fieldNameFrom`/`fieldNameTo`, `startFieldName`/`endFieldName`
- Both fields typed as `number | null` in the search model
- Examples: `settlementQuantityMin`/`settlementQuantityMax`, `amountFrom`/`amountTo`, `dateRangeStart`/`dateRangeEnd`

**Do NOT** create separate `NumberField` components for paired range fields. Always use `CommonRangeNumber` instead.

---

If your project doesn't have this component, create it with the following implementation:

```tsx
import { Breakpoint, HorizontalFlex, Label, NumberField, Space, VerticalFlex } from '@dap-ui/stratos';
import { useTranslate } from 'i18n';
import type { FC } from 'react';

export class CommonRangeNumberValue {
  min: number | null = null;
  max: number | null = null;
}

export interface CommonRangeNumberProps {
  value: CommonRangeNumberValue;
  label: string;
  integers?: number;
  decimals?: number;
  qa?: string;
  onChange: (value: CommonRangeNumberValue) => void;
}

const CommonRangeNumber: FC<CommonRangeNumberProps> = ({
  value,
  label,
  integers,
  decimals,
  qa,
  onChange,
}) => {
  const t = useTranslate();

  const {
    min,
    max,
  } = value;

  return (
    <VerticalFlex $gap={Space.V4}>
      <Label
        content={label}
        qa={qa}
      />

      <HorizontalFlex
        $gapX={Space.V16}
        $gapY={Space.V8}
        $breakpoint={Breakpoint.S}
      >
        <NumberField
          value={min}
          integers={integers}
          decimals={decimals}
          placeholder={t('common.min')}
          qa={qa ? `${qa}-min` : undefined}
          onChange={newValue => onChange({ min: newValue, max })}
        />

        <NumberField
          value={max}
          integers={integers}
          decimals={decimals}
          placeholder={t('common.max')}
          qa={qa ? `${qa}-max` : undefined}
          onChange={newValue => onChange({ min, max: newValue })}
        />
      </HorizontalFlex>
    </VerticalFlex>
  );
};

export default CommonRangeNumber;
```

**Props**:
- `value`: Object with `min` and `max` (both `number | null`)
- `label`: Field label text
- `integers`: Maximum number of integer digits (optional)
- `decimals`: Maximum number of decimal digits (optional)
- `qa`: Data-qa attribute for testing (optional)
- `onChange`: Callback receiving the updated `CommonRangeNumberValue`

**Usage in Section Component**:

```tsx
import { HeadingS, ResponsiveGrid, Select, Space, VerticalFlex } from '@dap-ui/stratos';
import CommonRangeNumber from 'components/CommonRangeNumber/CommonRangeNumber';
import { useTranslate } from 'i18n';
import type { FeatureSearchModel, FeatureSearchTaxonomyModel } from 'models';
import type { FC } from 'react';
import { selectFeatureSearchState } from 'store/feature-search/slice';
import { useAppSelector } from 'store/types';

export interface FeatureSearchQuantitiesProps {
  featureSearchTaxonomy: FeatureSearchTaxonomyModel;
  handleChange: (update: Partial<FeatureSearchModel>) => void;
}

const FeatureSearchQuantities: FC<FeatureSearchQuantitiesProps> = ({
  featureSearchTaxonomy,
  handleChange,
}) => {
  const t = useTranslate();
  const { searchData } = useAppSelector(selectFeatureSearchState);

  const { quantityTypes } = featureSearchTaxonomy;

  return (
    <VerticalFlex $gap={Space.V16}>
      <HeadingS>
        {t('featureSearchTab.quantitiesAndAmountsTitle')}
      </HeadingS>

      <ResponsiveGrid $l="repeat(4, 1fr)">
        <CommonRangeNumber
          value={{
            min: searchData.settlementQuantityMin,
            max: searchData.settlementQuantityMax,
          }}
          label={t('attributes.fields.settlementQuantity')}
          decimals={14}
          onChange={({ min, max }) => handleChange({
            settlementQuantityMin: min,
            settlementQuantityMax: max,
          })}
        />

        <Select
          value={searchData.quantityType?.value || ''}
          label={t('attributes.fields.quantityType')}
          options={quantityTypes}
          placeholder={t('common.selectPlaceholder')}
          emptyLabel={t('common.noData')}
          filterPlaceholder={t('common.searchPlaceholder')}
          onChange={value => {
            const quantityType = quantityTypes.find(o => o.value === value) || null;
            handleChange({ quantityType });
          }}
        />
      </ResponsiveGrid>
    </VerticalFlex>
  );
};

export default FeatureSearchQuantities;
```

**Key Points**:
- The component handles both `min` and `max` in a single `onChange` callback
- Pass both values to `handleChange` as a single partial update
- Use `decimals` prop for precision control (e.g., `decimals={14}` for quantities)
- Use `integers` prop to limit integer digits if needed

---

## 7. Submit Button Component (`<FeatureName>SearchSubmitButton`)

### Responsibilities
- Reads `searchData` and user permissions from Redux
- Disables itself when all fields are empty or the user lacks permission
- Navigates to the results route on click

### Template

```tsx
import { Button, SearchIcon } from '@dap-ui/stratos';
import { useTranslate } from 'i18n';
import type { FC } from 'react';
import { useNavigate } from 'react-router-dom';
import { ROUTES } from 'routes/config';
import { selectUser } from 'store/core/slice';
import { selectFeatureSearchState } from 'store/feature-search/slice';
import { useAppSelector } from 'store/types';

const FeatureSearchSubmitButton: FC = () => {
  const t = useTranslate();
  const navigate = useNavigate();
  const { searchData } = useAppSelector(selectFeatureSearchState);
  const userOperations = useAppSelector(selectUser).operations;

  const areFieldsEmpty = Object.values(searchData).every(value =>
    [false, null, ''].includes(value),
  );
  const disabled = !userOperations.canView || areFieldsEmpty;

  return (
    <Button
      label={t('common.searchButton')}
      leftIcon={SearchIcon}
      disabled={disabled}
      qa="search"
      onClick={() => navigate(ROUTES.FEATURE_SEARCH)}
    />
  );
};

export default FeatureSearchSubmitButton;
```

---

## 8. Testing

### General rules
- Mock the outermost Stratos layout component used in each component (typically `VerticalFlex` or `Cover`) to avoid rendering the full component tree.
- Use `renderWithProviders` so Redux state is available.
- Pass `vi.fn()` for `handleChange` props.
- Assert with `expect(screen.getByText('MockedComponentText'))` — no `.toBeInTheDocument()` needed.

### Form component test

```tsx
import { screen } from '@testing-library/react';
import { FeatureSearchTaxonomyModel } from 'models';
import { renderWithProviders } from 'TestTools';
import FeatureSearchForm from './FeatureSearchForm';

vi.mock('@dap-ui/stratos', async(original) => ({
  ...(await original()),
  VerticalFlex: () => <div>VerticalFlex</div>,
}));

describe('FeatureSearchForm', () => {
  it('should be rendered', () => {
    renderWithProviders((
      <FeatureSearchForm featureSearchTaxonomy={new FeatureSearchTaxonomyModel()} />
    ));
    expect(screen.getAllByText('VerticalFlex'));
  });
});
```

### Section component test

```tsx
import { screen } from '@testing-library/react';
import { renderWithProviders } from 'TestTools';
import FeatureSearchSectionA from './FeatureSearchSectionA';

vi.mock('@dap-ui/stratos', async(original) => ({
  ...(await original()),
  VerticalFlex: () => <div>VerticalFlex</div>,
}));

describe('FeatureSearchSectionA', () => {
  it('should be rendered', () => {
    renderWithProviders((
      <FeatureSearchSectionA handleChange={vi.fn()} />
    ));
    expect(screen.getByText('VerticalFlex'));
  });
});
```

### CommonRangeNumber component test

**Location**: `src/components/CommonRangeNumber/CommonRangeNumber.test.tsx`

```tsx
import { screen } from '@testing-library/react';
import { render } from 'TestTools';
import CommonRangeNumber, { CommonRangeNumberValue } from './CommonRangeNumber';

vi.mock('@dap-ui/stratos', async(original) => ({
  ...(await original()),
  VerticalFlex: () => <div>VerticalFlex</div>,
}));

describe('CommonRangeNumber', () => {
  it('should be rendered', () => {
    const value = new CommonRangeNumberValue();
    render((
      <CommonRangeNumber
        value={value}
        label="Test Label"
        onChange={vi.fn()}
      />
    ));
    expect(screen.getByText('VerticalFlex'));
  });
});
```

---

## 9. Checklist for a New Search Form

- [ ] Search form models created in `src/models/<feature>-search.ts` (Option, Search, Taxonomy)
- [ ] Redux slice created in `src/store/<feature>-search/slice.ts`
- [ ] Slice registered in `src/store/index.ts` and type added to `src/store/types.ts`
- [ ] `CommonRangeNumber` component created in `src/components/CommonRangeNumber/` (if not already exists)
- [ ] `<FeatureName>SearchTab` component created (taxonomy loading + Cover wrapper)
- [ ] `<FeatureName>SearchForm` component created (handleChange + section composition)
- [ ] One subfolder per form section created with component + test file
- [ ] `<FeatureName>SearchSubmitButton` created with disabled-when-empty logic
- [ ] All taxonomy-dependent sections receive taxonomy as prop; pure text sections receive only `handleChange`
- [ ] **MANDATORY**: `handleChange` is defined inline in the Form component and passed as a prop to all sections — no custom hook files (e.g., `useFeatureSearchForm.ts`) created for change handling
- [ ] **MANDATORY**: All numeric range fields (min/max, from/to) use `CommonRangeNumber` component (no separate NumberField components)
- [ ] **MANDATORY**: All Figma fields with a "Search" placeholder or magnifying glass icon use the `Search` component — NOT `TextField` (see [stratos.instructions.md](stratos.instructions.md))
- [ ] Mock API handler added in `mock/api/<feature>-search/`
- [ ] i18n keys added to `src/i18n/en.json` (including `common.min` and `common.max` for range fields)
- [ ] All `data-qa` attributes present on interactive elements
