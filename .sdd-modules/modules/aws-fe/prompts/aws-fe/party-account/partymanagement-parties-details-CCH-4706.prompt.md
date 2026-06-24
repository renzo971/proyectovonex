---
agent: neo
---
Request: Implement the parties detail feature as per the specifications below.

## Context
 - API Documentation: swagger-def.yml
 - Target APIs:
  GET /party-account/private/v1/party-management/parties/{id}/clients/{clientId}
 - Implement this design from Figma: 
 @https://www.figma.com/design/tf28uCZ71LAlnMr3FTaK0r/Acme FE-Account-Management?node-id=5147-12794&t=oMsKKCrZsMZzFC4d-4


## Implementation Checklist

### 1. Models
 - Create models for PartiesDetailModel inside models/parties-detail.ts

### 2. API Layer
 - Implement GET parties detail API
 - Add comprehensive API tests

### 3. Mock API Responses
 - Create mock endpoints for the API in mock/api/parties-detail/
 - Create JSON response files with realistic sample data

### 4. Translation
 - Add partiesDetail section with relevant labels and summary fields
 - Organize partiesDetail translations under partiesDetail.summary.*

### 5. Components
  - Implement PartiesDetailPage component
   - Use useCover pattern for data fetching
   - Use Paper component for layout with BackLink for navigation
   - Integrate header and content components

  - Implement PartiesDetailHeader component
   - Display Party BIC number using PaperHeader
   - Show summary information using Summary component
   - Include CloseButton for navigation
   
  - Implement PartiesDetailContent component
   - Render detail date information in tables

### 6. Routing
 - Create route definition for Parties Detail page

### 7. Key Requirements
 - Keep files under 300 lines
 - Ensure all iterated elements have unique keys
 - Add tests for every new file