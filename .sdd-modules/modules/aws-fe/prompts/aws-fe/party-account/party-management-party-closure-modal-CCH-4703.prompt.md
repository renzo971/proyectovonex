---
agent: neo
---
Request: Implement the parties closing modal feature for the Party Management section.

## Context
 - API Documentation: swagger-def.yml
 - Target APIs: 
   - POST /private/v1/party-management/parties/{id}/clients/{clientId}/close?csd=
 - Figma Design: https://www.figma.com/design/tf28uCZ71LAlnMr3FTaK0r/Acme FE-Account-Management?node-id=5138-18949&t=K0Ctn2wMVyylsYzZ-4
 - Reference Implementation: TechnicalAddresses feature

## Implementation Checklist

### 1. Models
 - Create model for the Party Closure Request
 - Create model for the Party Closure Response

### 2. API Layer
 - Implement endpoint method
 - Add comprehensive API tests

### 3. Mock API Responses
 - Create mock endpoint
 - Create JSON response files with realistic sample data
 - Include multiple CSD clients and all status types

### 4. Redux Store

### 5. Translation
 - Adds translation for party closure modal texts, buttons, and error messages

### 6. Components
 - Implement the modal with:
   - DatePicker for closure date, defaulting to today, not allowing past dates
 - Add comprehensive tests for all components

### 7. Routing

### 8. Key Requirements
 - Follow patterns from TechnicalAddresses implementation
 - Do NOT use cacheData
 - Keep files under 300 lines
 - Ensure all iterated elements have unique keys
 - Add tests for every new file