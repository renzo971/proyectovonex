---
agent: neo
---

# Securities Search Tab

**Request**: Implement the `SecuritiesSearchTab` component for the Securities UI application.

## Reference
- API Documentation: swagger-def.yml
- Use the exported html from figma in `figma-templates/securities-search-tab.html` for UI design reference, implement ONLY All filters section, avoiding Filters per category section
- Use Stratos Design System components and follow the design guidelines for consistency with the rest of the application
- Reference for filters taxonomy model: response from `GET /securities/private/v1/securities/search/filters/taxonomy`
- Reference for filters model: request body of `POST /securities/private/v1/user/securities/search`

## Implementation Steps

### 1. Models
- Create models based on the APIs defined in swagger-def.yml for the securities search taxonomy and filters.

### 2. API Layer
- Create `src/api/SecuritiesSearchAPI.ts` with `getSecuritiesSearchTaxonomyAPI(csd)` calling `GET /securities/private/v1/securities/search/filters/taxonomy`
- Create `src/api/SecuritiesSearchAPI.test.ts` with unit tests
- Export from `src/api/index.ts`

### 3. Mock API
- Create `mock/api/securities-search/securities-search-taxonomy-get.mjs` returning taxonomy data
- Create `mock/api/securities-search/securities-search-taxonomy-get.response.json` with mock response based on swagger-def.yml examples

### 4. Create SecuritiesSearchTab Component
- Location: `src/pages/home/SecuritiesSearchTab/SecuritiesSearchTab/`
- Uses `Cover` and `useCover` to load taxonomy via API
- Renders `SecuritiesSearchForm` as content
- Renders `CommonErrorState` on error
- Create unit test file

### 5. Create SecuritiesSearchForm Component
- Location: `src/pages/home/SecuritiesSearchTab/SecuritiesSearchForm/`
- Receives `searchTaxonomy` as prop
- Uses Redux slice (`selectSecuritiesSearchState`, `updateSearchData`, `resetSearchData`) for form state
- Renders a title, a notify banner, and the form
- Includes a clear all filters button and a submit button
- Create unit test file

### 6. Update Routing
- Update `src/routes/homeRoutes.tsx` to render `SecuritiesSearchTab` as the index route under the `SECURITIES_SEARCH` path instead of the placeholder `<div>`

### 7. Update i18n
- Add translations in `src/i18n/en.json` under a `securitiesSearchTab` key for: title, notify banner text, section headings, help texts
