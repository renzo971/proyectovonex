---
applyTo: "src/pages/**/*Search*/**,src/store/**/*search*/**"
---
# Search Results Page Pattern

This instruction describes how to implement a search results page following the established pattern in this project.

---

## Overview

A search results page is composed of six layers:

```
<FeatureSearchPage>                ← fetches list, owns reloadData, wraps with Cover loader
  ├── <BackLink />
  ├── <HeadingL /> + <FeatureSearchExportButton />
  ├── <Notify />
  ├── <FeatureSearchChips reloadData />       ← shown only when filters are active
  └── <Cover>
        ├── <FeatureSearchContent reloadData />   ← table + pagination
        ├── <EmptyState />                         ← shown when list is empty
        └── <CommonErrorState />
```

Each layer has a single responsibility.

---

## 1. Models

**Location**: `src/models/<feature>-search.ts` (extends the same file as the search form models)

Add the following classes and types to the existing models file.

### 1.1. Paging Model

```typescript
import { SorterType } from '@dap-ui/stratos';

export class FeatureSearchPagingModel {
  page = 0;
  size = 12;
  sortingField = FeatureSearchListColumn.SOME_DEFAULT_COLUMN;
  sortingOrder = SorterType.DESC;
}
```

**Rules**:
- `page` is 0-indexed (API-side)
- `size` is the default rows per page (typically 12)
- `sortingField` must be a value from the `FeatureSearchListColumn` enum
- `sortingOrder` defaults to `SorterType.DESC`

---

### 1.2. Column Enum

```typescript
export enum FeatureSearchListColumn {
  FIELD_A = 'fieldA',
  FIELD_B = 'fieldB',
  DATE_FIELD = 'dateField',
  // ... all displayable columns
}
```

**Rules**:
- Enum values must match the property names on `FeatureSearchListItem`
- Every column that can appear in the table must be represented
- Enum is used for both ordering/visibility management and sorting

---

### 1.3. List Item Model

```typescript
export class FeatureSearchListItem {
  itemId: string | null = null;
  fieldA: string | null = null;
  fieldB: string | null = null;
  dateField: string | null = null;
  numericField: number | null = null;
  booleanField = false;
  operations = new FeatureOperationsModel();
}
```

**Rules**:
- String fields initialize as `null` (nullable from API)
- Boolean flags initialize as `false`
- Numeric fields initialize as `null`
- Include an `operations` field if per-row actions depend on permissions

---

### 1.4. List Model

```typescript
export class FeatureSearchListModel {
  page = 0;
  pageSize = 0;
  totalCount = 0;
  lastUpdateTimestamp = '';
  items: FeatureSearchListItem[] = [];
}
```

---

### 1.5. Reloader Type

```typescript
export type FeatureSearchReloader = (
  newSearchData: FeatureSearchModel,
  newSearchPaging: FeatureSearchPagingModel,
) => Promise<void>;
```

**Rules**:
- Always define a named type alias for the reloader function signature
- This type is used as the prop type for all child components that trigger a reload (e.g., Chips, Content)

---

## 2. Folder Structure

All result-page files are placed alongside the search form in `src/pages/<feature>/`:

```
<feature>/
├── <FeatureName>SearchPage/
│   ├── <FeatureName>SearchPage.tsx
│   └── <FeatureName>SearchPage.test.tsx
├── <FeatureName>SearchContent/
│   ├── <FeatureName>SearchContent.tsx
│   ├── <FeatureName>SearchContent.hooks.tsx
│   └── <FeatureName>SearchContent.test.tsx
├── <FeatureName>SearchChips/
│   ├── <FeatureName>SearchChips/
│   │   ├── <FeatureName>SearchChips.tsx
│   │   └── <FeatureName>SearchChips.test.tsx
│   ├── <FeatureName>SearchChips<SectionA>/
│   │   ├── <FeatureName>SearchChips<SectionA>.tsx
│   │   └── <FeatureName>SearchChips<SectionA>.test.tsx
│   └── <FeatureName>SearchChips<SectionB>/
│       └── ...
├── <FeatureName>SearchActions/
│   ├── <FeatureName>SearchActions.tsx
│   ├── <FeatureName>SearchActions.hooks.tsx
│   └── <FeatureName>SearchActions.test.tsx
├── <FeatureName>SearchExportButton/
│   ├── <FeatureName>SearchExportButton.tsx
│   └── <FeatureName>SearchExportButton.test.tsx
└── <FeatureName>SearchManageButton/
    ├── <FeatureName>SearchManageButton.tsx
    └── <FeatureName>SearchManageButton.test.tsx
```

Every component file must have a corresponding `*.test.tsx` file.

---

## 3. Redux Slice

If the advanced search form is already implemented (see `advanced-search-form.instructions.md`), the existing slice must be **extended** with the additional state and reducers described below.

If the search form has **not** been implemented yet, create the slice from scratch at `src/store/<feature>-search/slice.ts` with the full state class, all reducers, `persistState`/`retrieveState` helpers, and the `getInitialState` migration logic described in this section.

**Full State class** (search form fields + results fields):

```typescript
const existentColumns = Object.values(FeatureSearchListColumn) as FeatureSearchListColumn[];

export class FeatureSearchState {
  searchData = new FeatureSearchModel();
  searchPaging = new FeatureSearchPagingModel();
  orderedColumns = [...existentColumns];
  visibleColumns = [...existentColumns];
}
```

**Reducers** (add to the existing slice, or include in the new slice):

```typescript
updateSearchPaging: (state, action: PayloadAction<FeatureSearchPagingModel>) => {
  state.searchPaging = action.payload;
  persistState(state);
},
updateOrderedColumns: (state, action: PayloadAction<FeatureSearchListColumn[]>) => {
  state.orderedColumns = action.payload;
  persistState(state);
},
updateVisibleColumns: (state, action: PayloadAction<FeatureSearchListColumn[]>) => {
  state.visibleColumns = action.payload;
  persistState(state);
},
```

**Column migration in `getInitialState`**:

When restoring state from `localStorage`, validate the saved columns against the current enum to handle newly added or removed columns. If building the slice from scratch, this function replaces the simpler `getInitialState` from the search form pattern:

```typescript
const getInitialState = (): FeatureSearchState => {
  const savedState = retrieveState();
  const newState = serializable(new FeatureSearchState());

  if (savedState) {
    if (!existentColumns.includes(savedState.searchPaging.sortingField)) {
      savedState.searchPaging.sortingField = newState.searchPaging.sortingField;
      savedState.searchPaging.sortingOrder = newState.searchPaging.sortingOrder;
    }

    const missingColumns = existentColumns.filter(c => !savedState.orderedColumns.includes(c));

    savedState.orderedColumns = savedState.orderedColumns
      .filter(c => existentColumns.includes(c))
      .concat(missingColumns);

    savedState.visibleColumns = savedState.visibleColumns
      .filter(c => existentColumns.includes(c))
      .concat(missingColumns);

    return savedState;
  }

  return newState;
};
```

---

## 4. Page Component (`<FeatureName>SearchPage`)

### Responsibilities
- Owns the `useCover` call and the `reloadData` function
- Passes `reloadData` to `<FeatureSearchChips>` and `<FeatureSearchContent>`
- Computes `hasChips` to conditionally render the chips section
- Renders the page title, export button, info banner, chips, and the covered content area
- Navigates back to `ROUTES.HOME` on back-link click and on empty state action

### Template

```tsx
import {
  BackLink, Breakpoint, Button, ButtonSize, ButtonVariant, Color, Cover,
  EmptyState, HeadingL, HorizontalFlex, isoToHuman, MediumTextM, Notify,
  NotifyVariant, RefreshIcon, Space, useCover, useRestoreScrollbar, VerticalFlex,
} from '@dap-ui/stratos';
import { getFeatureSearchListAPI } from 'api/FeatureSearchAPI';
import CommonErrorState from 'components/CommonErrorState/CommonErrorState';
import { useTranslate } from 'i18n';
import type { FeatureSearchReloader } from 'models';
import { FeatureSearchListModel } from 'models';
import type { FC } from 'react';
import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ROUTES } from 'routes/config';
import { selectCsd } from 'store/core/slice';
import { selectFeatureSearchState } from 'store/feature-search/slice';
import { useAppSelector } from 'store/types';
import FeatureSearchChips from '../FeatureSearchChips/FeatureSearchChips/FeatureSearchChips';
import FeatureSearchContent from '../FeatureSearchContent/FeatureSearchContent';
import FeatureSearchExportButton from '../FeatureSearchExportButton/FeatureSearchExportButton';
import FeatureSearchManageButton from '../FeatureSearchManageButton/FeatureSearchManageButton';

const FeatureSearchPage: FC = () => {
  const t = useTranslate();
  const restoreScrollbar = useRestoreScrollbar();
  const navigate = useNavigate();
  const [featureSearchList, setFeatureSearchList] = useState(new FeatureSearchListModel());
  const { searchData, searchPaging } = useAppSelector(selectFeatureSearchState);
  const csd = useAppSelector(selectCsd);

  const hasChips = Object.values(searchData).some((value) => {
    return [false, null, ''].includes(value) === false;
  });

  const { loading, reloadData, errorCode } = useCover<FeatureSearchReloader>(async(
    newSearchData,
    newSearchPaging,
  ) => {
    const list = await getFeatureSearchListAPI(newSearchData, newSearchPaging, csd);
    setFeatureSearchList(list);
  });

  useEffect(() => {
    reloadData(searchData, searchPaging);
  }, []);

  useEffect(() => {
    restoreScrollbar();
  }, [loading]);

  return (
    <VerticalFlex
      $gap={Space.V24}
      data-qa="search-results-page"
    >
      <BackLink
        label={t('common.backSearch')}
        onClick={() => navigate(ROUTES.HOME)}
      />

      <HorizontalFlex
        $breakpoint={Breakpoint.M}
        $gap={Space.V16}
      >
        <HeadingL
          $tone={Color.Neutral.V70}
          data-qa="search-results-title"
        >
          {t('featureSearchPage.title', undefined, { count: featureSearchList.totalCount })}
        </HeadingL>

        <FeatureSearchExportButton featureSearchList={featureSearchList} />
      </HorizontalFlex>

      <Notify
        text={t('featureSearchPage.notify')}
        variant={NotifyVariant.INFO}
        showMoreLabel={t('common.showMore')}
        showLessLabel={t('common.showLess')}
        qa="search-results-info-banner"
      />

      {hasChips && <FeatureSearchChips reloadData={reloadData} />}

      <VerticalFlex $gap={Space.V16}>
        <HorizontalFlex
          $gap={Space.V8}
          $justify="flex-end"
          $breakpoint={Breakpoint.L}
        >
          {featureSearchList.items.length > 0 && <FeatureSearchManageButton />}
        </HorizontalFlex>

        <Cover
          loading={loading}
          text={t('common.loading')}
          loaderTitle={t('common.loading')}
          content={
            <FeatureSearchContent
              featureSearchList={featureSearchList}
              reloadData={reloadData}
            />
          }
          emptyState={!featureSearchList.items.length && (
            <EmptyState
              title={t('common.noData')}
              description={t('common.noDataDescription')}
              actions={(
                <HorizontalFlex
                  $justify="center"
                  $breakpoint={Breakpoint.S}
                >
                  <Button
                    label={t('common.noDataButton')}
                    variant={ButtonVariant.GHOST}
                    onClick={() => navigate(ROUTES.HOME)}
                  />
                </HorizontalFlex>
              )}
            />
          )}
          errorState={errorCode && (
            <CommonErrorState
              code={errorCode}
              onReload={() => reloadData(searchData, searchPaging)}
            />
          )}
        />
      </VerticalFlex>
    </VerticalFlex>
  );
};

export default FeatureSearchPage;
```

**Rules**:
- `useCover` is typed with the `FeatureSearchReloader` type alias.
- The outer `Cover` wraps only the table + pagination area. The rest of the page (title, chips, etc.) is always visible.
- `hasChips` checks every `searchData` value against the "empty" set `[false, null, '']`.
- The `useEffect` for `reloadData` uses an empty dependency array intentionally (mount-only).
- `<FeatureSearchManageButton />` is rendered only when there are results.

---

## 5. Content Component (`<FeatureName>SearchContent`)

### Responsibilities
- Renders a sortable table via `TableScroller` / `TableHead` / `TableBody`
- Renders the `FullPagination` component below the table
- Page changes and rows-per-page changes both dispatch `updateSearchPaging` and call `reloadData`
- Delegates heading/row building to a dedicated hooks file

### Props interface

```typescript
export interface FeatureSearchContentProps {
  featureSearchList: FeatureSearchListModel;
  reloadData: FeatureSearchReloader;
}
```

### Template

```tsx
import {
  FullPagination, FullPaginationVariant, TableBody, TableDensity,
  TableHead, TableScroller, VerticalFlex,
} from '@dap-ui/stratos';
import { useTranslate } from 'i18n';
import type { FeatureSearchListModel, FeatureSearchReloader } from 'models';
import { rowsPerPageItems } from 'models';
import type { FC } from 'react';
import { selectFeatureSearchState, updateSearchPaging } from 'store/feature-search/slice';
import { useAppDispatch, useAppSelector } from 'store/types';
import { useSearchTableHeadings, useSearchTableRows } from './FeatureSearchContent.hooks';

export interface FeatureSearchContentProps {
  featureSearchList: FeatureSearchListModel;
  reloadData: FeatureSearchReloader;
}

const FeatureSearchContent: FC<FeatureSearchContentProps> = ({
  featureSearchList,
  reloadData,
}) => {
  const t = useTranslate();
  const { searchData, searchPaging } = useAppSelector(selectFeatureSearchState);
  const dispatch = useAppDispatch();
  const headings = useSearchTableHeadings(reloadData);
  const rows = useSearchTableRows(featureSearchList);

  const handlePageChange = (newPage: number) => {
    const newSearchPaging = { ...searchPaging, page: newPage - 1 };
    dispatch(updateSearchPaging(newSearchPaging));
    reloadData(searchData, newSearchPaging);
  };

  const handleRowsPerPageChange = (size: number) => {
    const newSearchPaging = { ...searchPaging, size };
    dispatch(updateSearchPaging(newSearchPaging));
    reloadData(searchData, newSearchPaging);
  };

  return (
    <VerticalFlex>
      <TableScroller data-qa="search-results-table">
        <TableHead
          headings={headings}
          qa="search-results-table-head"
        />
        <TableBody
          density={TableDensity.LOW}
          rows={rows}
          qa="search-results-table-body"
        />
      </TableScroller>

      <FullPagination
        page={featureSearchList.page + 1}
        totalCount={featureSearchList.totalCount}
        rowsPerPage={featureSearchList.pageSize}
        rowsPerPageItems={rowsPerPageItems}
        rowsPerPageLabel={t('common.pagination.resultsPerPage')}
        rowsLabel={t('common.pagination.results')}
        ofLabel={t('common.pagination.of')}
        pagesLabel={t('common.pagination.pages')}
        previousButtonTitle={t('common.pagination.previous')}
        nextButtonTitle={t('common.pagination.next')}
        variant={FullPaginationVariant.TABLE}
        qa="search-results-pagination"
        onPageChange={handlePageChange}
        onRowsPerPageChange={handleRowsPerPageChange}
      />
    </VerticalFlex>
  );
};

export default FeatureSearchContent;
```

**Rules**:
- `page` passed to `FullPagination` is 1-indexed (`list.page + 1`); paging state is 0-indexed.
- Table headings and row building are always extracted to a `.hooks.tsx` file — never inline.

---

## 6. Content Hooks (`<FeatureName>SearchContent.hooks.tsx`)

### Responsibilities
- `useSearchTableHeadings`: Builds the `TableHeadingModel[]` array, including `Sorter` components for sortable columns and per-column widths
- `useSearchTableRows`: Maps `FeatureSearchListModel` items to `TableRowModel[]`, filtering by `visibleColumns` in `orderedColumns` order

### Template structure

```tsx
// Cell content map — pure function, not a hook
const getCellContent = (
  t: TranslateFunction,
  item: FeatureSearchListItem,
  column: FeatureSearchListColumn,
): ReactNode => {
  const cellMap: Record<FeatureSearchListColumn, ReactNode> = {
    [FeatureSearchListColumn.FIELD_A]: item.fieldA,
    [FeatureSearchListColumn.DATE_FIELD]: isoToHuman(item.dateField),
    [FeatureSearchListColumn.BOOLEAN_FIELD]: getBooleanTextLabel(t, item.booleanField),
    // ... all columns
  };
  return cellMap[column];
};

// Column pixel widths
const cellWidthMap: Record<FeatureSearchListColumn, number> = {
  [FeatureSearchListColumn.FIELD_A]: 120,
  [FeatureSearchListColumn.DATE_FIELD]: 160,
  // ...
};

// Hook: build table headings with sorting support
export const useSearchTableHeadings = (reloadData: FeatureSearchReloader): TableHeadingModel[] => {
  const t = useTranslate();
  const dispatch = useAppDispatch();
  const {
    orderedColumns,
    visibleColumns,
    searchData,
    searchPaging,
  } = useAppSelector(selectFeatureSearchState);
  const orderedVisibleColumns = orderedColumns.filter(c => visibleColumns.includes(c));

  // Declare only the columns that support sorting
  const sortableColumns: FeatureSearchListColumn[] = [
    FeatureSearchListColumn.SOME_DATE_COLUMN,
    // ... other sortable columns
  ];

  const handleSort = (sorting: SorterModel | undefined) => {
    const newSearchPaging = { ...searchPaging };

    if (sorting) {
      newSearchPaging.sortingField = orderedVisibleColumns[sorting.index];
      newSearchPaging.sortingOrder = sorting.value;
    } else {
      newSearchPaging.sortingOrder = SorterType.ASC;
    }

    dispatch(updateSearchPaging(newSearchPaging));
    reloadData(searchData, newSearchPaging);
  };

  const getSorter = (label: string, index: number) => (
    <HorizontalFlex>
      <Sorter
        label={label}
        columnIndex={index}
        sorting={{
          index: orderedVisibleColumns.indexOf(searchPaging.sortingField),
          value: searchPaging.sortingOrder,
        }}
        onSort={handleSort}
      />
    </HorizontalFlex>
  );

  const headings = orderedVisibleColumns.map((column, index) => {
    const label = t(`attributes.columns.${column}`);
    const hasSorting = sortableColumns.includes(column);

    return {
      content: hasSorting ? getSorter(label, index) : label,
      width: cellWidthMap[column],
    } as TableHeadingModel;
  });

  return [
    ...headings,
    {
      content: '',
      width: 92,
      sticky: 'right',
    },
  ];
};

// Hook: build table rows
export const useSearchTableRows = (
  featureSearchList: FeatureSearchListModel,
): TableRowModel[] => {
  const t = useTranslate();
  const {
    orderedColumns,
    visibleColumns,
  } = useAppSelector(selectFeatureSearchState);
  const orderedVisibleColumns = orderedColumns.filter(c => visibleColumns.includes(c));

  return featureSearchList.items.map((item, index) => {
    const cells: TableCellModel[] = [
      ...orderedVisibleColumns.map(column => ({
        content: getCellContent(t, item, column),
        width: cellWidthMap[column],
      })),
      {
        content: <FeatureSearchActions item={item} />,
        width: 92,
        sticky: 'right',
      } as TableCellModel,
    ];

    return {
      key: `row-${index + 1}`,
      cells,
    };
  });
};
```

**Rules**:
- `getCellContent` and `cellWidthMap` are module-level constants/functions — not hooks.
- Date fields must use `isoToHuman(value)` from `@dap-ui/stratos`.
- Boolean fields must use `getBooleanTextLabel(t, value)` from `helpers`.
- `orderedVisibleColumns` is computed once per hook by filtering `orderedColumns` to those present in `visibleColumns`.
- Only columns listed in `sortableColumns` get a `Sorter` component; others render a plain label string.
- `Sorter` uses the multi-column API: `columnIndex` (position in `orderedVisibleColumns`), `sorting` (shared `{ index, value }` object), and `onSort` (receives `SorterModel | undefined`). Do **not** use the single-column `type`/`onChange` API.
- `handleSort` updates `sortingField` by looking up the column at `sorting.index` in `orderedVisibleColumns`; when `sorting` is `undefined` it resets order to `SorterType.ASC`. It does **not** reset `page` to `0`.
- Headings use the `content` property (not `label` or `key`).
- A trailing sticky actions heading (`sticky: 'right'`, `width: 92`, empty `content`) is always appended.
- Each row key is index-based (`row-${index + 1}`), not `item.itemId`.
- The actions cell uses `sticky: 'right'`, `width: 92`, and must be cast as `TableCellModel`.
- Translation key for column labels uses `attributes.columns.${column}` (not `attributes.fields.${column}`).

---

## 7. Chips Component (`<FeatureName>SearchChips`)

### Responsibilities
- Wraps all chip section components inside an `<Accordion>` (collapsible, expanded by default)
- Defines `handleDelete` that merges a partial update into `searchData`, dispatches `updateSearchData`, and calls `reloadData`
- Passes `handleDelete` to each chip section component

### Template

```tsx
import type { AccordionItem } from '@dap-ui/stratos';
import { Accordion, HeadingS, HorizontalFlex, Space } from '@dap-ui/stratos';
import { useTranslate } from 'i18n';
import type { FeatureSearchModel, FeatureSearchReloader } from 'models';
import type { FC } from 'react';
import { useState } from 'react';
import { selectFeatureSearchState, updateSearchData } from 'store/feature-search/slice';
import { useAppDispatch, useAppSelector } from 'store/types';
import FeatureSearchChipsSectionA from '../FeatureSearchChipsSectionA/FeatureSearchChipsSectionA';

export interface FeatureSearchChipsProps {
  reloadData: FeatureSearchReloader;
}

const FeatureSearchChips: FC<FeatureSearchChipsProps> = ({ reloadData }) => {
  const t = useTranslate();
  const { searchData, searchPaging } = useAppSelector(selectFeatureSearchState);
  const dispatch = useAppDispatch();
  const [expandedItems, setExpandedItems] = useState<number[]>([1]);
  const title = t('common.appliedFiltersTitle');

  const handleDelete = (update: Partial<FeatureSearchModel>) => {
    const newSearchData = { ...searchData, ...update };
    dispatch(updateSearchData(newSearchData));
    reloadData(newSearchData, searchPaging);
  };

  const items: AccordionItem[] = [{
    expanded: expandedItems.includes(0),
    title: (
      <HeadingS
        title={title}
        data-qa="applied-filters-title"
      >
        {title}
      </HeadingS>
    ),
    content: (
      <HorizontalFlex
        $gap={Space.V8}
        $wrap
      >
        <FeatureSearchChipsSectionA handleDelete={handleDelete} />
      </HorizontalFlex>
    ),
  }];

  const handleChange = (index: number) => {
    setExpandedItems(prev =>
      prev.includes(index) ? prev.filter(i => i !== index) : [...prev, index],
    );
  };

  return (
    <Accordion
      items={items}
      onChange={handleChange}
      qa="applied-filters-section"
    />
  );
};

export default FeatureSearchChips;
```

**Rules**:
- The accordion starts collapsed (`[1]` in initial state); `expanded: expandedItems.includes(0)` evaluates to `false` on mount. The first click expands it.
- `handleDelete` spreads the full `searchData` before the partial update, then dispatches and reloads.
- Chip sections are organized to mirror the search form sections (same grouping by Identification, Dates, Transaction, etc.).

---

## 8. Chips Section Components (e.g., `<FeatureName>SearchChipsSectionA`)

### Responsibilities
- Reads `searchData` from Redux
- Renders one `<FilterChip>` per active (non-empty) field
- Calls `handleDelete` with the field reset to its empty value on chip deletion

### Props interface

```typescript
export interface FeatureSearchChipsSectionAProps {
  handleDelete: (update: Partial<FeatureSearchModel>) => void;
}
```

### Template

```tsx
import { FilterChip } from '@dap-ui/stratos';
import { useTranslate } from 'i18n';
import type { FeatureSearchModel } from 'models';
import type { FC } from 'react';
import { selectFeatureSearchState } from 'store/feature-search/slice';
import { useAppSelector } from 'store/types';

export interface FeatureSearchChipsSectionAProps {
  handleDelete: (update: Partial<FeatureSearchModel>) => void;
}

const FeatureSearchChipsSectionA: FC<FeatureSearchChipsSectionAProps> = ({ handleDelete }) => {
  const t = useTranslate();
  const { searchData } = useAppSelector(selectFeatureSearchState);

  return (
    <>
      {searchData.textFieldA !== '' && (
        <FilterChip
          label={t('attributes.fields.textFieldA')}
          value={searchData.textFieldA}
          deleteTitle={t('common.deleteButton')}
          onDelete={() => handleDelete({ textFieldA: '' })}
        />
      )}

      {searchData.dropdownField !== null && (
        <FilterChip
          label={t('attributes.fields.dropdownField')}
          value={searchData.dropdownField.label}
          deleteTitle={t('common.deleteButton')}
          onDelete={() => handleDelete({ dropdownField: null })}
        />
      )}

      {searchData.booleanFlag && (
        <FilterChip
          label={t('attributes.fields.booleanFlag')}
          value={t('common.yes')}
          deleteTitle={t('common.deleteButton')}
          onDelete={() => handleDelete({ booleanFlag: false })}
        />
      )}
    </>
  );
};

export default FeatureSearchChipsSectionA;
```

**Reset values by field type**:
- String fields → `''`
- Dropdown fields → `null`
- Boolean fields → `false`
- Numeric fields → `null`

**`FilterChip` `value` by field type**:
- String fields → the string value directly
- Dropdown fields → `option.label`
- Date range pairs → display as `"from → to"` or render two separate chips
- Boolean flags → `t('common.yes')` (only shown when `true`)

---

## 9. Actions Component (`<FeatureName>SearchActions`)

### Responsibilities
- Renders per-row actions inside a `HorizontalFlex`: always includes a "See details" navigation button, plus additional action buttons depending on the Figma design
- All action buttons are conditionally rendered using `item.operations` flags provided by the API
- Modal state (`isCancellationOpen`, `isDeleteOpen`, etc.) is managed locally with `useState`
- **Follow the Figma design**: render specific `IconButton`s (pencil, trash, etc.) when Figma shows explicit icons; use `ActionMenu` with a three-dots trigger only when Figma shows a more-options menu

### Variant A — Specific action buttons (pencil / trash)

Use this variant when Figma shows explicit action icon buttons (e.g. edit pencil, trash bin / cancel) directly in the row. **Only render what the Figma design shows** — do not add a "See details" button unless Figma explicitly includes it.

Icon names in `@dap-ui/stratos`:
- **Edit / pencil** → `EditIcon`
- **Delete / trash bin / cancel** → `DeleteIcon`

```tsx
import {
  ButtonSize, DeleteIcon, EditIcon, HorizontalFlex, IconButton, Space,
} from '@dap-ui/stratos';
import { useTranslate } from 'i18n';
import type { FeatureSearchListItem } from 'models';
import type { FC } from 'react';
import { useState } from 'react';

export interface FeatureSearchActionsProps {
  item: FeatureSearchListItem;
}

const FeatureSearchActions: FC<FeatureSearchActionsProps> = ({ item }) => {
  const t = useTranslate();
  const [isDeleteOpen, setDeleteOpen] = useState(false);

  return (
    <HorizontalFlex
      $gap={Space.V4}
      $justify="flex-end"
    >
      {item.operations.canEdit && (
        <IconButton
          icon={EditIcon}
          title={t('common.editButton')}
          size={ButtonSize.XS}
          qa="edit-item"
          onClick={() => {}}
        />
      )}

      {item.operations.canDelete && (
        <IconButton
          icon={DeleteIcon}
          title={t('common.deleteButton')}
          size={ButtonSize.XS}
          qa="delete-item"
          onClick={() => setDeleteOpen(true)}
        />
      )}

      {isDeleteOpen && (
        <CommonFeatureDeletionModal
          itemId={item.itemId ?? ''}
          setConfirmOpen={setDeleteOpen}
        />
      )}
    </HorizontalFlex>
  );
};

export default FeatureSearchActions;
```

### Variant B — More options menu (three-dots button)

Use this variant when Figma shows a `MoreVerticalIcon` trigger that opens a dropdown of actions. Build the options list in a dedicated `.hooks.tsx` file.

```tsx
import {
  ActionMenu, ArrowRightIcon, Button, ButtonSize, ButtonVariant, FieldVariant,
  HorizontalFlex, IconButton, MoreVerticalIcon, PopoverSize, Space,
} from '@dap-ui/stratos';
import { useTranslate } from 'i18n';
import type { FeatureSearchListItem } from 'models';
import type { FC } from 'react';
import { useState } from 'react';
import { generatePath, useNavigate } from 'react-router-dom';
import { ROUTES } from 'routes/config';
import { selectUser } from 'store/core/slice';
import { useAppSelector } from 'store/types';
import { useMoreOptions } from './FeatureSearchActions.hooks';

export interface FeatureSearchActionsProps {
  item: FeatureSearchListItem;
}

const FeatureSearchActions: FC<FeatureSearchActionsProps> = ({ item }) => {
  const t = useTranslate();
  const navigate = useNavigate();
  const [isCancellationOpen, setCancellationOpen] = useState(false);
  const moreOptions = useMoreOptions(item, setCancellationOpen);
  const userOperations = useAppSelector(selectUser).operations;

  const showMoreOptions = userOperations.canCreate && !!moreOptions.length;

  const detailPath = generatePath(ROUTES.FEATURE_DETAIL, {
    itemId: item.itemId ?? '',
  });

  return (
    <HorizontalFlex
      $gap={Space.V4}
      $justify="flex-end"
    >
      {showMoreOptions && (
        <ActionMenu
          options={moreOptions}
          variant={FieldVariant.COMPACT}
          size={PopoverSize.XS}
          getTrigger={({ open, updateOpen }) => (
            <IconButton
              icon={MoreVerticalIcon}
              title={t('featureSearchPage.moreButton.title')}
              size={ButtonSize.XS}
              qa="see-more-options"
              onClick={() => updateOpen(!open)}
            />
          )}
        />
      )}

      <Button
        label={t('common.seeDetails')}
        rightIcon={ArrowRightIcon}
        variant={ButtonVariant.GHOST}
        size={ButtonSize.XS}
        qa="see-details"
        onClick={() => navigate(detailPath)}
      />

      {isCancellationOpen && (
        <CommonFeatureCancellationModal
          itemId={item.itemId ?? ''}
          setConfirmOpen={setCancellationOpen}
        />
      )}
    </HorizontalFlex>
  );
};

export default FeatureSearchActions;
```

### Actions Hooks (`<FeatureName>SearchActions.hooks.tsx`)

Required only for Variant B. Each option is pushed to the array only when the corresponding `item.operations` flag is `true`.

```tsx
import type { ActionMenuOption } from '@dap-ui/stratos';
import { useTranslate } from 'i18n';
import type { FeatureSearchListItem } from 'models';
import type { Dispatch, SetStateAction } from 'react';
import { useNavigate } from 'react-router-dom';

export const useMoreOptions = (
  item: FeatureSearchListItem,
  setCancellationOpen: Dispatch<SetStateAction<boolean>>,
): ActionMenuOption[] => {
  const t = useTranslate();
  const navigate = useNavigate();
  const moreOptions: ActionMenuOption[] = [];

  if (item.operations.canCancel) {
    moreOptions.push({
      label: t('featureSearchPage.moreButton.cancel'),
      onClick: () => setCancellationOpen(true),
    });
  }

  return moreOptions;
};
```

**Rules**:
- **Always follow the Figma design** — render only the buttons/icons that appear in the design. Do not add extra buttons (e.g. "See details") unless Figma explicitly shows them.
- **Spacing**: The `HorizontalFlex` wrapper must always use `$gap={Space.V4}` (4 px) and `$justify="flex-end"` (right-aligned) — matching the Figma table cell layout. Do not use `$justify="center"` or a larger gap.
- Choose Variant A when Figma shows explicit icon buttons (edit pencil, trash bin, etc.) directly in the row; choose Variant B when Figma shows a three-dots `MoreVerticalIcon` trigger.
- In both variants, every action button is gated by an `item.operations` flag from the API response.
- For Variant A, use `EditIcon` for edit/pencil actions and `DeleteIcon` for delete/trash/cancel actions — these are the correct icon names in `@dap-ui/stratos`. Do not use `PencilIcon` or `TrashIcon`.
- For Variant A, each `IconButton` is rendered directly inside `HorizontalFlex`, conditionally rendered with the corresponding `item.operations` flag. No `.hooks.tsx` file is needed.
- For Variant B, the `useMoreOptions` hook is required; options are added only when the corresponding `item.operations` flag is `true`.
- Modal open-state is always owned by the `Actions` component, not the hook.
- The hook receives setter functions as parameters; it does not own state.

---

## 10. Export Button (`<FeatureName>SearchExportButton`)

### Responsibilities
- Reads `searchData`, `searchPaging`, `orderedColumns`, and `visibleColumns` from Redux
- Disables itself when `totalCount > 2000` (export limit)
- Calls the export API, downloads the blob, and shows progress/success/error toasts
- Renders an `InformationIcon` tooltip explaining the export limit

### Template

```tsx
import {
  Button, ButtonSize, ButtonVariant, Color, downloadBlob, HorizontalFlex,
  IconSize, InformationIcon, Space, ToastContext, Tooltip,
} from '@dap-ui/stratos';
import { exportFeatureListAPI } from 'api/FeatureSearchAPI';
import type { AxiosError } from 'axios';
import { useTranslate } from 'i18n';
import type { FeatureSearchListModel } from 'models';
import type { FC } from 'react';
import { useContext } from 'react';
import { selectCsd } from 'store/core/slice';
import { selectFeatureSearchState } from 'store/feature-search/slice';
import { useAppSelector } from 'store/types';

export interface FeatureSearchExportButtonProps {
  featureSearchList: FeatureSearchListModel;
}

const FeatureSearchExportButton: FC<FeatureSearchExportButtonProps> = ({ featureSearchList }) => {
  const t = useTranslate();
  const { showProgressToast, showSuccessToast, showErrorToast } = useContext(ToastContext);
  const { searchData, searchPaging, orderedColumns, visibleColumns } = useAppSelector(selectFeatureSearchState);
  const csd = useAppSelector(selectCsd);

  const disabled = featureSearchList.totalCount > 2000;
  const orderedVisibleColumns = orderedColumns.filter(c => visibleColumns.includes(c));

  const handleConfirm = async() => {
    try {
      showProgressToast(t('common.loading'));
      const { blob, fileName } = await exportFeatureListAPI(searchData, orderedVisibleColumns, searchPaging, csd);
      downloadBlob(blob, fileName!);
      showSuccessToast(t('common.exportSuccess'));
    } catch (error) {
      const errorResponse = (error as AxiosError)?.response;
      const errorMessage = t(`apiErrors.${errorResponse?.status}`, t('common.genericErrorText'));
      showErrorToast(errorMessage);
    }
  };

  return (
    <HorizontalFlex $gap={Space.V8}>
      <Button
        label={t('common.exportButton')}
        variant={ButtonVariant.SECONDARY}
        size={ButtonSize.M}
        disabled={disabled}
        qa="export-list"
        onClick={handleConfirm}
      />

      <Tooltip
        content={t('common.exportTooltipText')}
        title={t('common.exportButton')}
      >
        <InformationIcon
          size={IconSize.V16}
          tone={Color.Teal.V30}
        />
      </Tooltip>
    </HorizontalFlex>
  );
};

export default FeatureSearchExportButton;
```

**Rules**:
- The export limit (2000) is a magic number — extract to a named constant if used elsewhere.
- Only columns that are both `orderedColumns` and `visibleColumns` are exported.
- Always use `try/catch` with `showErrorToast`; never swallow the error silently.

---

## 11. Manage Columns Button (`<FeatureName>SearchManageButton`)

### Responsibilities
- Opens `CommonColumnsModal` to let the user reorder and show/hide columns
- On apply, dispatches `updateOrderedColumns` and `updateVisibleColumns`

### Template

```tsx
import { Button, ButtonVariant, ViewColumnIcon } from '@dap-ui/stratos';
import type { CommonColumnsModalApply } from 'components/CommonColumnsModal/CommonColumnsModal';
import CommonColumnsModal from 'components/CommonColumnsModal/CommonColumnsModal';
import { useTranslate } from 'i18n';
import type { FeatureSearchListColumn } from 'models';
import type { FC } from 'react';
import { useState } from 'react';
import { selectFeatureSearchState, updateOrderedColumns, updateVisibleColumns } from 'store/feature-search/slice';
import { useAppDispatch, useAppSelector } from 'store/types';

const FeatureSearchManageButton: FC = () => {
  const t = useTranslate();
  const [open, setOpen] = useState(false);
  const { orderedColumns, visibleColumns } = useAppSelector(selectFeatureSearchState);
  const dispatch = useAppDispatch();

  const handleApply: CommonColumnsModalApply = (orderedList, visibleList) => {
    dispatch(updateOrderedColumns(orderedList as FeatureSearchListColumn[]));
    dispatch(updateVisibleColumns(visibleList as FeatureSearchListColumn[]));
  };

  return (
    <>
      <Button
        label={t('common.manageColumnsButton')}
        leftIcon={ViewColumnIcon}
        variant={ButtonVariant.SECONDARY}
        onClick={() => setOpen(true)}
      />

      {open && (
        <CommonColumnsModal
          orderedColumns={orderedColumns}
          visibleColumns={visibleColumns}
          onApply={handleApply}
          onClose={() => setOpen(false)}
        />
      )}
    </>
  );
};

export default FeatureSearchManageButton;
```

### `CommonColumnsModal` implementation

If `src/components/CommonColumnsModal/CommonColumnsModal.tsx` does not exist, create it with the following implementation:

```tsx
import type { TableHeadingModel, TableRowModel } from '@dap-ui/stratos';
import {
  ArrowDownIcon,
  ArrowUpIcon,
  BoldTextM,
  Breakpoint,
  Button,
  ButtonSize,
  ButtonVariant,
  HorizontalFlex,
  IconButton,
  MediumTextM,
  Modal,
  RegularTextM,
  Space,
  Switch,
  TableBody,
  TableHead,
  TableScroller,
  VerticalFlex,
} from '@dap-ui/stratos';
import { useTranslate } from 'i18n';
import type { FC } from 'react';
import { useState } from 'react';

export type CommonColumnsModalApply = (
  orderedList: string[],
  visibleList: string[]
) => void;

export interface CommonColumnsModalProps {
  orderedColumns: string[];
  visibleColumns: string[];
  onApply: CommonColumnsModalApply;
  onClose: () => void;
}

const CommonColumnsModal: FC<CommonColumnsModalProps> = ({
  orderedColumns,
  visibleColumns,
  onApply,
  onClose,
}) => {
  const t = useTranslate();
  const [orderedList, setOrderedList] = useState(orderedColumns);
  const [visibleList, setVisibleList] = useState(visibleColumns);

  const hiddenColumns = orderedColumns.length - visibleColumns.length;

  const handleSort = (index: number, direction: -1 | 1) => {
    setOrderedList(oldValue => {
      const newValue = oldValue.filter((_, i) => i !== index);
      const column = oldValue[index];
      newValue.splice(index + direction, 0, column);
      return newValue;
    });
  };

  const handleVisibility = (column: string, index: number, value: boolean) => {
    setVisibleList(oldValue => {
      const newValue = oldValue.filter(c => c !== column);
      if (value) {
        newValue.splice(index, 0, column);
      }
      return newValue;
    });
  };

  const headings: TableHeadingModel[] = [
    {
      content: t('common.column'),
    },
    {
      content: t('common.hideShow'),
      width: 90,
      align: 'flex-end',
    },
    {
      content: t('common.move'),
      width: 90,
      align: 'center',
    },
  ];

  const rows = orderedList.map((item, index) => {
    const isDisabled = [
      visibleList.includes(item),
      visibleList.length < 2,
    ].every(Boolean);

    return ({
      key: `row-${index + 1}`,
      cells: [
        {
          content: t(`attributes.columns.${item}`),
        },
        {
          content: (
            <Switch
              value={visibleList.includes(item)}
              onChange={value => handleVisibility(item, index, value)}
              disabled={isDisabled}
            />
          ),
          width: 90,
          align: 'flex-end',
        },
        {
          content: (
            <HorizontalFlex
              $gap={Space.V4}
              $justify="center"
            >
              <IconButton
                icon={ArrowUpIcon}
                title={t('common.moveUp')}
                size={ButtonSize.S}
                disabled={index === 0}
                onClick={() => handleSort(index, -1)}
              />

              <IconButton
                icon={ArrowDownIcon}
                title={t('common.moveDown')}
                size={ButtonSize.S}
                disabled={index === orderedList.length - 1}
                onClick={() => handleSort(index, 1)}
              />
            </HorizontalFlex>
          ),
          width: 90,
        },
      ],
    } as TableRowModel);
  });

  return (
    <Modal
      title={t('common.columnsModal.title')}
      body={
        <VerticalFlex $gap={Space.V24}>
          <RegularTextM>
            {t('common.columnsModal.body')}
          </RegularTextM>

          <TableScroller role="table">
            <TableHead headings={headings} />
            <TableBody rows={rows} />
          </TableScroller>
        </VerticalFlex>
      }
      footer={
        <VerticalFlex>
          <HorizontalFlex
            $gap={Space.V2}
            $breakpoint={Breakpoint.S}
          >
            <MediumTextM>
              {t('common.columnsModal.totalColumns')}
            </MediumTextM>

            <BoldTextM>
              {orderedColumns.length},
            </BoldTextM>

            <MediumTextM>
              {t('common.columnsModal.hiddenColumns')}
            </MediumTextM>

            <BoldTextM>
              {hiddenColumns},
            </BoldTextM>

            <MediumTextM>
              {t('common.columnsModal.visibleColumns')}
            </MediumTextM>

            <BoldTextM>
              {visibleColumns.length}
            </BoldTextM>
          </HorizontalFlex>

          <HorizontalFlex
            $gap={Space.V8}
            $justify="flex-end"
            $breakpoint={Breakpoint.S}
          >
            <Button
              label={t('common.cancelButton')}
              variant={ButtonVariant.GHOST}
              onClick={onClose}
            />

            <Button
              label={t('common.applyButton')}
              onClick={() => {
                onApply(orderedList, visibleList);
                onClose();
              }}
            />
          </HorizontalFlex>
        </VerticalFlex>
      }
      closeTitle={t('common.closeButton')}
      onClose={onClose}
    />
  );
};

export default CommonColumnsModal;
```

**Rules**:
- `orderedList` and `visibleList` are local state initialized from props — changes are not dispatched until the user clicks Apply.
- A column switch is `disabled` only when it is visible AND it is the last visible column (`visibleList.length < 2`), preventing the user from hiding all columns.
- `handleSort` splices the column at `index + direction` to move it up (`-1`) or down (`+1`).
- `handleVisibility` removes the column from `visibleList` and re-inserts it at the same `index` position when toggled on.
- The footer displays counts using the original `orderedColumns.length` (not `orderedList.length`) for total, so the count reflects the full set regardless of reordering in the modal session.
- Clicking Apply calls `onApply(orderedList, visibleList)` then `onClose()` — the parent is responsible for dispatching the Redux updates.

---

## 12. Testing

### General rules
- Mock the outermost Stratos layout component used in each component (typically `VerticalFlex` or `Cover`) to avoid rendering the full component tree.
- For the `SearchPage`, also mock `useCover` to control its return value in tests.
- Use `renderWithProviders` so Redux state is available.
- Assert with `expect(screen.getByText('MockedComponentText'))` — no `.toBeInTheDocument()` needed.

### Page component test

```tsx
import { useCover } from '@dap-ui/stratos';
import { screen } from '@testing-library/react';
import { renderWithProviders } from 'TestTools';
import FeatureSearchPage from './FeatureSearchPage';

vi.mock('@dap-ui/stratos', async(original) => ({
  ...(await original()),
  Cover: () => <div>Cover</div>,
  useCover: vi.fn(),
}));

describe('FeatureSearchPage', () => {
  const mockUseCover = vi.mocked(useCover);

  beforeEach(() => {
    mockUseCover.mockReturnValue({
      loading: false,
      reloadData: vi.fn(),
      errorCode: 0,
    });
  });

  it('should be rendered', () => {
    renderWithProviders(<FeatureSearchPage />);
    expect(screen.getByText('Cover'));
  });
});
```

### Content component test

```tsx
import { screen } from '@testing-library/react';
import { FeatureSearchListModel } from 'models';
import { renderWithProviders } from 'TestTools';
import FeatureSearchContent from './FeatureSearchContent';

vi.mock('@dap-ui/stratos', async(original) => ({
  ...(await original()),
  VerticalFlex: () => <div>VerticalFlex</div>,
}));

describe('FeatureSearchContent', () => {
  it('should be rendered', () => {
    renderWithProviders((
      <FeatureSearchContent
        featureSearchList={new FeatureSearchListModel()}
        reloadData={vi.fn()}
      />
    ));
    expect(screen.getByText('VerticalFlex'));
  });
});
```

### Chips component test

```tsx
import { screen } from '@testing-library/react';
import { renderWithProviders } from 'TestTools';
import FeatureSearchChips from './FeatureSearchChips';

vi.mock('@dap-ui/stratos', async(original) => ({
  ...(await original()),
  Accordion: () => <div>Accordion</div>,
}));

describe('FeatureSearchChips', () => {
  it('should be rendered', () => {
    renderWithProviders(<FeatureSearchChips reloadData={vi.fn()} />);
    expect(screen.getByText('Accordion'));
  });
});
```

### Chips section component test

Each `<FeatureName>SearchChips<Section>` component must:
- Mock `@dap-ui/stratos` to replace `FilterChip` with a simple `<div>`
- Mock the store slice to replace the selector with a `vi.fn()`
- Use `beforeEach` to set a non-empty `searchData` value that triggers at least one `FilterChip` to render
- Assert with `screen.getByText('FilterChip')` (synchronous) — never `findByText`

```tsx
import { screen } from '@testing-library/react';
import { FeatureSearchModel } from 'models';
import { FeatureSearchState, selectFeatureSearchState } from 'store/feature-search/slice';
import { renderWithProviders } from 'TestTools';
import FeatureSearchChipsSectionA from './FeatureSearchChipsSectionA';

vi.mock('@dap-ui/stratos', async(original) => ({
  ...(await original()),
  FilterChip: () => <div>FilterChip</div>,
}));

vi.mock('store/feature-search/slice', async(original) => ({
  ...(await original()),
  selectFeatureSearchState: vi.fn(),
}));

describe('FeatureSearchChipsSectionA', () => {
  const mockSelectFeatureSearchState = vi.mocked(selectFeatureSearchState);

  beforeEach(() => {
    mockSelectFeatureSearchState.mockReturnValue({
      ...new FeatureSearchState(),
      searchData: {
        ...new FeatureSearchModel(),
        // Set a field that is always rendered by this section
        someField: 'test-value',
      },
    });
  });

  it('should be rendered', () => {
    renderWithProviders((
      <FeatureSearchChipsSectionA
        handleDelete={vi.fn()}
      />
    ));

    expect(screen.getByText('FilterChip'));
  });
});
```

**Rules**:
- Pick the simplest field type for the seed value: prefer a `string` field (set to a non-empty string), then a `boolean` flag (set to `true`), then a nullable option (set to `{ value: 'test', label: 'Test' }`).
- The seeded field must be one that this specific section component renders — check the component source to confirm.
- Always spread `new FeatureSearchState()` and `new FeatureSearchModel()` to preserve all other default values.

---

## 13. Checklist for a New Search Results Page

- [ ] `FeatureSearchListColumn` enum added to `src/models/<feature>-search.ts`
- [ ] `FeatureSearchPagingModel`, `FeatureSearchListItem`, `FeatureSearchListModel`, and `FeatureSearchReloader` type added to models file
- [ ] Redux slice extended with `searchPaging`, `orderedColumns`, `visibleColumns` state and reducers
- [ ] Column migration logic added to `getInitialState` in the slice
- [ ] `<FeatureName>SearchPage` created with `useCover`, chips visibility logic, refresh button, and covered content
- [ ] `<FeatureName>SearchContent` created with `TableScroller` + `FullPagination`
- [ ] `<FeatureName>SearchContent.hooks.tsx` created with `useSearchTableHeadings` and `useSearchTableRows`
- [ ] `getCellContent` function covers every `FeatureSearchListColumn` value
- [ ] `cellWidthMap` defines a pixel width for every `FeatureSearchListColumn` value
- [ ] `<FeatureName>SearchChips` container created (Accordion + `handleDelete`)
- [ ] One `<FeatureName>SearchChips<Section>` component per form section, mirroring the search form sections
- [ ] `<FeatureName>SearchActions` created with details navigation and optional action menu
- [ ] `<FeatureName>SearchActions.hooks.tsx` created with `useMoreOptions`
- [ ] `<FeatureName>SearchExportButton` created with 2000-row limit guard and toast feedback
- [ ] `<FeatureName>SearchManageButton` created using `CommonColumnsModal`
- [ ] Route constant added in `src/routes/config.ts` for the results page
- [ ] Mock API handler added in `mock/api/<feature>-search/` for the list and export endpoints
- [ ] i18n keys added for `featureSearchPage.title`, `featureSearchPage.notify`, and `featureSearchPage.moreButton.*`
- [ ] All `data-qa` attributes present on all interactive elements and container wrappers
- [ ] All component files have a corresponding `*.test.tsx` file