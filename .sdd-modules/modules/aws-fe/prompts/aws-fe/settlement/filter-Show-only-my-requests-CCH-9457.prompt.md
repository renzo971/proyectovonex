---
agent: neo
---
### CCH-9457: Settlement Instructions Requests - Replace the author search by "Show only my requests" filter

**Request**: Remove the author search and add "Show only my requests" filter

## Reference implementation
See `/party-account-ui/src/pages/party-requests/PartyRequestsFilters/`:
- PartyRequestsFilters.tsx
- PartyRequestsFilters.hooks.tsx

## Deliverables
- Find the "Search for:" dropdown in the Instructions Requests and delete the Author value.
- Add the "Show only my request" FilterChip in InstractionRequestsFilters, referencing the "party-account-ui" project in PartyRequestsFilters with all its properties.
- Find the "Search for:" dropdown in the Restrictions Requests and delete the Author value.
- Add the "Show only my request" FilterChip in RestrictionRequestsFilters, referencing the "party-account-ui" project in PartyRequestsFilters with all its properties.
- Add the missing translations.
