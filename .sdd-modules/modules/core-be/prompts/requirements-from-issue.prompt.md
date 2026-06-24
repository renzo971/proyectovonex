---
description: Capture requirements from a Jira issue or Confluence page using MCP tools
mode: agent
---

**Import requirements** from an existing Jira issue or Confluence page.

> **Prerequisite:** Provide the Jira issue key (e.g., `PROJ-123`) or Confluence page title/URL. The agent will read the issue/page directly via MCP integration.

Invoke `@requirement-analyst` with MCP-Atlassian tools:

1. **From Jira issue:**
   ```
   @requirement-analyst read Jira issue PROJ-123 and capture requirements
   ```
   The agent will use `mcp-atlassian/jira_get_issue` to fetch the issue,
   then transform it into structured user stories with acceptance criteria.

2. **From Confluence page:**
   ```
   @requirement-analyst read Confluence page "Feature Spec" and capture requirements
   ```
   The agent will use `mcp-atlassian/confluence_get_page` to fetch the content,
   then extract and formalize requirements.

3. **Teaching Mode** (for junior POs/FAs):
   ```
   @requirement-analyst help me write requirements for PROJ-123 (Teaching Mode)
   ```
   The agent will mentor through the requirement-writing process.
