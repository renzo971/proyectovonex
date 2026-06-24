---
agent: neo
---
Request: Implement the export parties list to CSV button ("Export list (.csv)") in the PartiesTab component.

## Context
 - API Documentation: swagger-def.yml
 - Target API: POST /party-account/private/v1/party-management/parties/export
 - Current Page: PartiesTab component (src/pages/parties/PartiesTab/)
 - Reference Implementation: settlement project InstructionSearchExportButton component

## Implementation Checklist

### 1. API Layer (src/api/PartiesAPI.ts)
 - Add sendPostForBlob function to ApiClient.ts (if not exists)
 - Implement exportPartiesAPI function using sendPostForBlob
 - Parameters: searchFilters, sortingField, sortingOrder, csd
 - Request body: { searchFilters }
 - Query params: sortingField, sortingOrder, csd
 - Return BlobResponse with blob and fileName
 - Add comprehensive API tests

### 2. Mock API (mock/api/parties/parties-export-post.mjs)
 - Create POST endpoint matching settlement pattern
 - Set headers: Access-Control-Expose-Headers, Content-Disposition
 - Return status 200
 - Filename: "exportedParties.csv"

### 3. Translations (src/i18n/en.json)
 - Add to partiesList section:
   - exportButton: "Export list (.csv)"
   - exportSuccess: "Parties exported successfully."
 - Use common.genericErrorText for errors (no custom exportError)

### 4. Components
 - Create PartiesExportButton component (src/pages/parties/PartiesExportButton/)
   - Separate component for export button
   - Single Button with secondary variant
   - Implement handleConfirm with toast notifications
   - Use downloadBlob from @dap-ui/stratos
   - Error handling uses common.genericErrorText
   
 - Update PartiesTab component
   - Import and render PartiesExportButton
   - Pass partiesList as prop
   - Position above filters

### 5. CSV Export
 - Backend generates CSV with all party columns
 - Frontend only downloads via blob
 - Filename from Content-Disposition header

### 6. Testing
 - Add PartiesExportButton.test.tsx with render test
 - Update PartiesAPI.test.ts with export test
 - Mock Stratos Button component

### 7. Key Requirements
 - Export respects current search filters and sorting
 - Show progress toast during export (common.loading)
 - Show success toast on completion (partiesList.exportSuccess)
 - Show error toast with common.genericErrorText if fails
 - Download uses Stratos downloadBlob utility
