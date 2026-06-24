---
applyTo: "src/pages/**/*Search*/**,src/store/**/*search*/**"
---
# Advanced Search Results Pattern

## Purpose

Implement search results pages with consistent pagination, sorting, and error handling using Stratos components.

## Architecture

```
<FeatureSearchPage>                ← fetches list, owns reloadData
  ├── <BackLink />
  ├── <HeadingL /> + <ExportButton />
  ├── <Notify />                   ← success/error notifications
  ├── <FeatureSearchChips />       ← active filter chips
  └── <Cover>
        ├── <FeatureSearchContent />   ← table + pagination
        ├── <EmptyState />
        └── <CommonErrorState />
```

## Models

### Paging Model

```typescript
import { SorterType } from '@dap-ui/stratos';

export class FeatureSearchPagingModel {
  page = 0;          // 0-indexed (API-side)
  size = 12;         // default page size
  sortingField = FeatureSearchListColumn.DEFAULT_COLUMN;
  sortingOrder = SorterType.DESC;
}
```

### List Column Enum

```typescript
export enum FeatureSearchListColumn {
  COLUMN_A = 'columnA',
  COLUMN_B = 'columnB',
  STATUS = 'status',
  DATE = 'date',
}
```

## Result Table

Use Stratos `Table` component with the following pattern:

```tsx
const columns: TableColumn<FeatureSearchResultItem>[] = [
  {
    key: FeatureSearchListColumn.COLUMN_A,
    label: t('feature.columns.columnA'),
    sortable: true,
    render: (item) => <RegularTextM>{item.columnA}</RegularTextM>,
  },
  {
    key: FeatureSearchListColumn.STATUS,
    label: t('feature.columns.status'),
    sortable: true,
    render: (item) => <FeatureStatusBadge status={item.status} />,
  },
];
```

## Pagination

Use Stratos `Pagination` component:

```tsx
<Pagination
  currentPage={paging.page + 1}  // UI is 1-indexed, API is 0-indexed
  totalPages={totalPages}
  onPageChange={(page) => handlePageChange(page - 1)}
  pageSize={paging.size}
  onPageSizeChange={handlePageSizeChange}
/>
```

## Filter Chips

Display active search criteria as removable chips:

```tsx
<ChipGroup>
  {searchData.category && (
    <Chip
      label={`Category: ${searchData.category.label}`}
      onRemove={() => handleChange({ category: null })}
    />
  )}
</ChipGroup>
```

Chips are shown only when at least one filter is active.

## Loading and Error States

```tsx
<Cover loading={isLoading} error={error}>
  {data?.items.length === 0 ? (
    <EmptyState message={t('feature.search.noResults')} />
  ) : (
    <FeatureSearchContent data={data} paging={paging} />
  )}
</Cover>
```

## Export Button

Optional export functionality:

```tsx
<Button
  label={t('feature.search.export')}
  variant={ButtonVariant.SECONDARY}
  leftIcon={<DownloadIcon size={IconSize.V18} />}
  onClick={handleExport}
  disabled={!hasResults}
/>
```

## File Organization

```
<FeatureSearchPage>/
├── <Feature>SearchPage.tsx          ← main page, fetches data
├── <Feature>SearchContent/
│   ├── <Feature>SearchContent.tsx   ← table + pagination
│   └── <Feature>SearchContent.test.tsx
├── <Feature>SearchChips/
│   ├── <Feature>SearchChips.tsx
│   └── <Feature>SearchChips.test.tsx
└── <Feature>SearchExportButton/
    ├── <Feature>SearchExportButton.tsx
    └── <Feature>SearchExportButton.test.tsx
```

## Testing

- Table renders correct columns and data
- Sorting triggers correct paging update
- Pagination navigation updates page correctly
- Chip removal clears the corresponding filter
- Empty state shown when no results
- Error state shown on API failure
