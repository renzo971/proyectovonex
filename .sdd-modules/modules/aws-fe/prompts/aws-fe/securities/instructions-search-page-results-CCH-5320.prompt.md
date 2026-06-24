---
agent: neo
---
### Instructions Search Results Page

**Request**: Implement the Instructions Search results page following the established search results pattern.

## Reference
- API Documentation: swagger-def.yml
- Pattern: Advanced search results
- UI Reference (results page layout): [result-page-index.html](../../figma-templates/result-page-index.html) -> actions is the last column in the table, this is a sticky column
- UI Reference (full table columns): [full-table-columns-index.html](../../figma-templates/full-table-columns-index.html)
- **API Endpoint**: POST `/securities/private/v1/instructions/search`

## Implementation Steps

Follow the checklist in `advanced-search-results.instructions.md`, applying it to the `Instructions` feature:

### 1. Update Models
- Create models based on the APIs defined in swagger-def.yml for the instructions search taxonomy and filters:
  - Add `InstructionsSearchListColumn` enum, `InstructionsSearchPagingModel`, `InstructionsSearchListItem`, `InstructionsSearchListModel`, and `InstructionsSearchReloader` type to `src/models/instructions-search.ts`

### 2. Update Redux Slice
- Extend `src/store/instructions-search/slice.ts` with `searchPaging`, `orderedColumns`, and `visibleColumns` state and reducers
- Add column migration logic to `getInitialState`

### 3. Create Page Components
- `src/pages/instructions-search/InstructionsSearchPage/` — main page with `useCover`, chips visibility, refresh button and covered content
- `src/pages/instructions-search/InstructionsSearchContent/` — table with `TableScroller`, `FullPagination`, and a `.hooks.tsx` file
- `src/pages/instructions-search/InstructionsSearchChips/InstructionsSearchChips/` — Accordion wrapper with `handleDelete`
- One `InstructionsSearchChips<Section>` component per search form section
- `src/pages/instructions-search/InstructionsSearchActions/` - HorizontalFlex with IconButtons with conditional rendering based on user operations 
- `src/pages/instructions-search/InstructionsSearchExportButton/` — export with 2000-row limit guard
- `src/pages/instructions-search/InstructionsSearchManageButton/` — column management via `CommonColumnsModal`

### 4. Update Routing
- Add `INSTRUCTIONS_SEARCH` route constant in `src/routes/config.ts`
- Register the page in the routes configuration

### 5. Add Mock API
- Add handler and response in `mock/api/instructions-search/`

### 6. Update i18n
- Add translations in `src/i18n/en.json` under `instructionsSearchPage`
