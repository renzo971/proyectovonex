# Jira Cloud REST API v3 — Endpoint Map

> Reference card for Jira Cloud REST v3 endpoints used by the `jira-rest-ops` skill.
> Base URL pattern: `{JIRA_BASE_URL}/rest/api/3{path}`
> Authentication: Basic auth with `{JIRA_USER_EMAIL}:{JIRA_API_TOKEN}` (Base64-encoded)

---

## Issue Operations

| Operation | Method | Path | Required Fields | Notes |
|-----------|:------:|------|----------------|-------|
| Get issue | GET | `/issue/{key}` | `key` (path) | Returns full issue detail with fields |
| Create issue | POST | `/issue` | `fields.project.key`, `fields.summary`, `fields.issuetype.name` | Requires confirmation |
| Update issue | PUT | `/issue/{key}` | `key` (path), `fields` (body) | Partial update — only send changed fields |
| Delete issue | DELETE | `/issue/{key}` | `key` (path) | ⚠️ Irreversible — not in standard SDD workflow |
| Get issue transitions | GET | `/issue/{key}/transitions` | `key` (path) | Run before transitioning |
| Transition issue | POST | `/issue/{key}/transitions` | `key` (path), `transition.id` | Get transition IDs first |
| Add comment | POST | `/issue/{key}/comment` | `key` (path), `body` (ADF format) | Requires confirmation |
| Get comments | GET | `/issue/{key}/comment` | `key` (path) | |
| Get issue changelog | GET | `/issue/{key}/changelog` | `key` (path) | Audit trail |
| Link issues | POST | `/issueLink` | `type.name`, `inwardIssue.key`, `outwardIssue.key` | |

---

## Search Operations

| Operation | Method | Path | Notes |
|-----------|:------:|------|-------|
| Search with JQL | GET | `/search?jql={JQL}&maxResults={N}&fields={fields}` | URL-encode JQL. Default maxResults=50. |
| Count issues (JQL) | GET | `/search?jql={JQL}&maxResults=0` | Returns `total` count without data |

### Common JQL Templates

```
# All open issues in project
project = MYPROJ AND statusCategory != Done ORDER BY created DESC

# Issues assigned to current user
assignee = currentUser() AND status != Done

# Issues updated in last 7 days
project = MYPROJ AND updated >= -7d ORDER BY updated DESC

# Issues linked to a specific sprint
project = MYPROJ AND sprint in openSprints()

# Issues by label
project = MYPROJ AND labels = "wave-19"
```

---

## Project Operations

| Operation | Method | Path | Notes |
|-----------|:------:|------|-------|
| List all projects | GET | `/project` | Returns summary list |
| Get project detail | GET | `/project/{projectKeyOrId}` | |
| Get project components | GET | `/project/{projectKeyOrId}/components` | |
| Get project versions | GET | `/project/{projectKeyOrId}/versions` | |

---

## Sprint / Board Operations (Jira Software only)

| Operation | Method | Path | Notes |
|-----------|:------:|------|-------|
| Get board sprints | GET | `/agile/1.0/board/{boardId}/sprint` | Note: uses `/agile/1.0/` prefix |
| Get sprint issues | GET | `/agile/1.0/sprint/{sprintId}/issue` | Note: uses `/agile/1.0/` prefix |

---

## User Operations

| Operation | Method | Path | Notes |
|-----------|:------:|------|-------|
| Get current user | GET | `/myself` | Use for smoke check / auth test |
| Search users | GET | `/user/search?query={term}` | For finding assignee account IDs |

---

## Response Shapes

### Issue Object (simplified)

```json
{
  "id": "10001",
  "key": "PROJ-42",
  "fields": {
    "summary": "Issue title",
    "status": { "name": "In Progress" },
    "assignee": { "displayName": "Alice Smith", "emailAddress": "alice@example.com" },
    "priority": { "name": "High" },
    "issuetype": { "name": "Story" },
    "labels": ["tag1", "tag2"],
    "description": { ... },
    "created": "2026-04-24T10:00:00.000+0000",
    "updated": "2026-04-24T12:00:00.000+0000"
  }
}
```

### Transition Object

```json
{
  "id": "21",
  "name": "In Progress",
  "to": { "name": "In Progress" }
}
```

### Search Response (simplified)

```json
{
  "total": 42,
  "maxResults": 50,
  "startAt": 0,
  "issues": [ ... ]
}
```

---

## Common HTTP Status Codes

| Code | Meaning | Common Cause |
|------|---------|-------------|
| 200 | OK | Request succeeded |
| 201 | Created | Issue/resource created |
| 204 | No Content | Update/delete succeeded |
| 400 | Bad Request | Invalid JQL, missing fields, malformed payload |
| 401 | Unauthorized | Invalid `JIRA_API_TOKEN` or `JIRA_USER_EMAIL` |
| 403 | Forbidden | User lacks project/issue permissions |
| 404 | Not Found | Issue key does not exist or user cannot see it |
| 429 | Rate Limited | Retry after `Retry-After` header value |

---

## Security Notes

- **Never** log or print `JIRA_API_TOKEN` — use env var validation only.
- Use **read-first** defaults: GET operations before any POST/PUT.
- For sensitive projects, prefer the MCP Atlassian adapter when available — this file is a **fallback** only.
- Token scope: use a least-privilege API token scoped to the required projects.
