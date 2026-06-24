# jira-rest-ops

Purpose: execute Jira Cloud REST API operations safely using explicit REST endpoints, token-env guardrails, and read-first defaults — as a fallback when MCP adapters are unavailable or restricted.

## When to Use

- MCP Atlassian adapter is unavailable, restricted by firewall, or temporarily degraded
- Operator needs a reproducible, team-shareable Jira operation that does not depend on IDE/MCP tool availability
- Performing bulk read operations (issue search, sprint listing, project enumeration) outside an IDE context
- Executing a controlled write operation (create issue, update status, transition) with explicit human confirmation step

## Input

- `JIRA_BASE_URL` — Jira Cloud base URL (e.g., `https://your-org.atlassian.net`)
- `JIRA_API_TOKEN` — API token from Atlassian account settings (must be set as env var, never hardcoded)
- `JIRA_USER_EMAIL` — Email associated with the API token
- Operation parameters: issue key, project key, JQL query, status transition ID, issue fields

## Safety Defaults

| Default | Value | Override? |
|---------|-------|:---------:|
| Read operations require no confirmation | Always safe to execute | No |
| Write operations (create, update, transition) | Require explicit operator confirmation before execution | Yes — with stakeholder acknowledgment |
| Token source | `$JIRA_API_TOKEN` environment variable ONLY | No |
| Max search results | 50 per request | Yes — operator can specify |
| Timeout | 30 seconds per request | Yes |

## Execution Flow

### For Read Operations (GET)

1. Verify `JIRA_BASE_URL`, `JIRA_API_TOKEN`, and `JIRA_USER_EMAIL` are set in the environment. Exit with diagnostic if any are missing.
2. Construct the REST endpoint from the Jira endpoint map (`jira-endpoint-map-template.md`).
3. Execute the request using the `scripts/jira-rest.sh` helper (or PowerShell equivalent).
4. Parse the JSON response and extract the relevant fields.
5. Output a clean summary table, not raw JSON.

### For Write Operations (POST, PUT, transition)

1. Verify environment variables (same as above).
2. Present the full request payload to the operator BEFORE executing. Request confirmation.
3. If operator confirms, execute the request.
4. Log the request summary (method, endpoint, key fields — NOT the token) to the session output.
5. Verify the operation succeeded by re-fetching the affected resource.
6. Output a confirmation summary.

## Common REST Operations Reference

| Operation | Method | Endpoint | Notes |
|-----------|:------:|----------|-------|
| Get issue | GET | `/rest/api/3/issue/{key}` | Returns full issue detail |
| Search issues (JQL) | GET | `/rest/api/3/search?jql=...&maxResults=50` | URL-encode the JQL string |
| List projects | GET | `/rest/api/3/project` | Returns all accessible projects |
| Create issue | POST | `/rest/api/3/issue` | Requires confirmation |
| Transition issue | POST | `/rest/api/3/issue/{key}/transitions` | Requires transition ID; get IDs first |
| Get transitions | GET | `/rest/api/3/issue/{key}/transitions` | Use before transitioning |
| Update issue fields | PUT | `/rest/api/3/issue/{key}` | Requires confirmation |
| Add comment | POST | `/rest/api/3/issue/{key}/comment` | Requires confirmation |

See `jira-endpoint-map-template.md` for the full reference card.

## Output Contract

Produce a summary with: operation type/endpoint/timestamp, result status and HTTP code, data summary (table or key-value pairs, no raw JSON), and any issues found.

## Common Rationalizations

| Rationalization | Rebuttal |
|---|---|
| "I'll hardcode the token for now" | Hardcoded tokens leak into VCS and are flagged by secrets-scan. Use `$JIRA_API_TOKEN` env var. |
| "It's just a status transition, no confirmation needed" | Unconfirmed transitions can trigger downstream automations and violate SLA tracking. Follow the write confirmation step. |
| "MCP is down — I'll skip the Jira update" | Delayed updates introduce traceability gaps at Gate 4. Use this REST fallback immediately. |
| "The JQL is complex — I'll eyeball the board" | Manual inspection is not reproducible or citable. Construct the JQL query via the endpoint map. |
