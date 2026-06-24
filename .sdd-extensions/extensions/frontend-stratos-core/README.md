# Frontend Stratos Core Extension

> **Version:** 1.0.0
> **Type:** Tailored Frontend Extension
> **Required Module:** `std-fe`

## Overview

Shared UI baseline for Stratos design-system decisions, MFE decomposition, and component ambiguity handling. This is the base pack required by all other frontend extensions (`frontend-enterprise-search`, `frontend-dual-agent-review`).

## Contents

### Instructions
- `fe-stratos-design-tokens.instructions.md` — Stratos design token conventions and usage
- `fe-component-ambiguity-resolution.instructions.md` — Protocol for resolving component selection ambiguities
- `fe-frontend-architecture-mfe.instructions.md` — MFE decomposition and folder structure
- `fe-frontend-state-decision-tree.instructions.md` — State management decision tree (local vs store vs URL)

### Prompts
- `fe-scaffold-component.prompt.md` — Scaffold a new Stratos-based component
- `fe-design-review.prompt.md` — Review frontend implementation against design specs

### Templates
- `react-vite-vitest-setup.md` — Baseline project setup with React, Vite, and Vitest

## Installation

```bash
sdd extension install frontend-stratos-core
```

## Figma MCP Integration (Optional)

This extension supports opt-in Figma MCP server integration for AI-assisted design-to-code workflows.

### Setup

1. Obtain a Figma Personal Access Token from your Figma account settings
2. Set environment variables:
   ```bash
   export FIGMA_API_KEY=your-figma-api-key
   export FIGMA_PROJECT_ID=your-figma-project-id
   ```
3. Add the MCP server configuration to `.vscode/mcp.json` (see `templates/react-vite-vitest-setup.md` for the full configuration block)

### Capabilities

When configured, the Figma MCP server enables:
- **Design-to-component mapping** — agents can read Figma frames and map them to Stratos components
- **Token extraction** — extract color, spacing, and typography values from Figma designs
- **Layout inspection** — understand component hierarchy and spacing from Figma frames

### Requirements

- Figma Personal Access Token with read access to the target project
- MCP-compatible VS Code extension (e.g., GitHub Copilot with MCP support)
- Network access to Figma API

> **Note:** Figma integration is entirely opt-in and does not affect any other extension functionality. Projects without Figma configuration will work normally.
