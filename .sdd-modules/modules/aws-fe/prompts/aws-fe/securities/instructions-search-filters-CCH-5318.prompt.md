---
agent: neo
---

# Instructions Search Tab

**Request**: Implement the `InstructionsSearchTab` component for the Securities UI application.

## Reference
- API Documentation: swagger-def.yml
- Use the exported html from figma in `figma-templates/instructions-search-tab.html` for UI design reference, implement ONLY All filters section, avoiding Filters per category section
- Use Stratos Design System components and follow the design guidelines for consistency with the rest of the application
- Reference for filters taxonomy model: response from `GET /securities/private/v1/instructions/search/filters/taxonomy`
- Reference for filters model: request body of `POST /securities/private/v1/instructions/search`

## Implementation Steps

### 1. Models
- Create models based on the APIs defined in swagger-def.yml for the instructions search taxonomy and filters.

### 2. API Layer
- Create `src/api/InstructionsSearchAPI.ts` with `getInstructionsSearchTaxonomyAPI(csd)` calling `GET /securities/private/v1/instructions/search/filters/taxonomy`
- Create `src/api/InstructionsSearchAPI.test.ts` with unit tests
- Export from `src/api/index.ts`

### 3. Mock API
- Create `mock/api/instructions-search/instructions-search-taxonomy-get.mjs` returning taxonomy data
- Create `mock/api/instructions-search/instructions-search-taxonomy-get.response.json` with mock response based on swagger-def.yml examples

### 4. Create InstructionsSearchTab Component
- Location: `src/pages/home/InstructionsSearchTab/InstructionsSearchTab/`
- Uses `Cover` and `useCover` to load taxonomy via API
- Renders `InstructionsSearchForm` as content
- Renders `CommonErrorState` on error
- Create unit test file

### 5. Create InstructionsSearchForm Component
- Location: `src/pages/home/InstructionsSearchTab/InstructionsSearchForm/`
- Receives `searchTaxonomy` as prop
- Uses Redux slice (`selectInstructionsSearchState`, `updateSearchData`, `resetSearchData`) for form state
- Renders a title, a notify banner, and the form
- Includes a clear all filters button and a submit button
- For fields that involve searching (e.g. free-text lookup fields), use a `SearchTrigger` component paired with an `ActionMenu` for criteria selection, wrapped in a dedicated `InstructionsSearches` component — follow the **Filter form** scenario from the Stratos `SearchTrigger` guidelines (updates Redux state only, no data reload)
- Create unit test file

### 6. Update Routing
- Update `src/routes/homeRoutes.tsx` to render `InstructionsSearchTab` as the index route under the `INSTRUCTIONS_SEARCH` path instead of the placeholder `<div>`

### 7. Update i18n
- Add translations in `src/i18n/en.json` under a `instructionsSearchTab` key for: title, notify banner text, section headings, help texts
