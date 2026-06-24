# SDD User Modules

User Modules add domain-specific technical knowledge to Enterprise SDD without
modifying core agents, gates, or scripts.

## What's a Module?

A self-contained package of instruction files, guidance documents, setup templates,
prompts, and constitution article templates — all tailored to a specific technology
stack or architectural pattern.

## Installed Modules

See `registry.json` for the list of installed modules.

Current module package folders under `.sdd-modules/modules/`:
- `core-be`
- `std-fe`
- `aws-fe`
- `sdd-evolution`

## Available Modules

The repository currently includes these module packages under `.sdd-modules/modules/`:

| Module | Main Purpose |
|--------|--------------|
| `core-be` | Backend/domain patterns for Java 21, Quarkus, DDD, Kafka, and PostgreSQL |
| `std-fe` | Frontend microfrontend patterns for React 19, Vite, and Stratos |
| `aws-fe` | Frontend workflows for React, Redux Toolkit, Stratos, and prompt-driven implementation journeys |
| `sdd-evolution` | Meta-evolution: analyse external frameworks, harvest features, plan SDD improvements, design new modules/extensions |

Typical usage:

```bash
sdd module list
sdd module install core-be
sdd module install std-fe
sdd module install aws-fe
```

## Commands

| Command | Description |
|---------|-------------|
| `sdd module install <name>` | Install a module from `.sdd-modules/modules/<name>/` |
| `sdd module remove <name>` | Remove a module and its files |
| `sdd module update <name>` | Update module files to latest version |
| `sdd module list` | List installed modules |

Use the Python CLI as primary interface. Shell/PowerShell scripts remain available under `.specify/scripts/` for low-level automation.

Note: `sdd module update <name>` is available in the command surface; use it only when your workflow requires in-place module refresh.

## Module Directory Structure

```
.sdd-modules/
├── registry.json          # Tracks installed modules
├── README.md              # This file
└── modules/               # Module packages (each in its own directory)
    └── <module-name>/
        ├── module.json                        # Module manifest (required)
        ├── instructions/                      # Instruction files (with applyTo globs)
        ├── guidances/                         # Guidance documents
        ├── prompts/                           # Prompt files
        ├── setup/                             # Setup templates
        ├── constitution-articles/             # Constitution article templates
        ├── agent-patches/                     # Agent modification patches
        └── copilot-instructions-supplement.md # Appended to copilot-instructions.md
```

    Nested folders under `instructions/`, `prompts/`, `guidances/`, and `setup/` are supported and preserved during install/remove.

## Module Manifest (`module.json`)

```json
{
  "name": "my-module",
  "version": "1.0.0",
  "description": "Description of what this module provides",
  "author": "Author Name",
  "files": {
    "instructions": ["instruction-a.instructions.md"],
    "guidances": [],
    "prompts": [],
    "setup": [],
    "constitutionArticles": [],
    "agentPatches": []
  },
  "placeholders": {},
  "agentContributions": {
    "tool-overlays": [],
    "agents": []
  }
}
```

### `agentContributions` — Agent Composition (optional)

Modules can contribute to the agent composition system via the `agentContributions` key.
This is processed by `compose-agents.py` whenever a module is installed or removed, producing
an `agents-composed.json` that is the effective agent set used by all adapter generation scripts.

**`tool-overlays`** — Add tools to an existing core agent:
```json
"tool-overlays": [
  {
    "target-agent": "requirement-analyst",
    "add-tools": ["githubRepo", "mcp-atlassian/jira_get_issue"]
  }
]
```
Use this when your module provides an MCP server or integration that enhances a core agent's capabilities.
Tools are deduplicated — if the tool is already present, it is silently skipped.

**`agents`** — Contribute entirely new agents:
```json
"agents": [
  {
    "name": "My Module Agent",
    "slug": "my-module-agent",
    "description": "What this agent does.",
    "tools": ["read", "edit", "search"],
    "model-tier": "standard",
    "phase": "meta",
    "instructions": [".sdd-modules/modules/my-module/instructions/my-module.instructions.md"],
    "handoffs": []
  }
]
```
The agent's `.agent.md` file (human-readable, for VS Code Copilot) should still live in the
module's `agents/` directory. The `agentContributions.agents` entry is the machine-readable
source used for adapter generation.

**Agent patches vs. agent contributions:**
| | Agent Patches (`agent-patches/*.patch.md`) | Agent Contributions (`agentContributions`) |
|---|---|---|
| Purpose | Add domain behavior/knowledge to instruction profiles | Add tools, new agents, or handoffs to the canonical definition |
| Applied by | Human review (manual merge into agent body) | `compose-agents.py` (automatic, at install/remove time) |
| Schema | Markdown guidance file | JSON in `module.json` |
| Example | "Use Kafka naming for topics" | Add `mcp-atlassian/jira_get_issue` tool to requirement-analyst |

## Creating a Module

See the module manifest format in ENTERPRISE-SDD-EVOLUTION.md §10.3.

For step-by-step usage guidance of the current modules, see PLAYBOOK.md §User Modules.

## Recommended Module + Pack Bundles

Modules provide domain knowledge; extension packs add SDD lifecycle integration. Choose the right bundle for your project:

### Which modules and packs do I need?

```
Is your project backend Java/Quarkus?
├── YES → Install: core-be
│         (No frontend packs needed)
│
└── NO → Is it a React/Stratos frontend?
    ├── YES → Install: std-fe
    │         Pack: frontend-stratos-core (always)
    │
    │         Does it have advanced search features?
    │         ├── YES → Also pack: frontend-enterprise-search
    │         └── NO → Skip
    │
    │         Do you want dual-agent generate+review?
    │         ├── YES → Also install: aws-fe module
    │         │         Also pack: frontend-dual-agent-review
    │         └── NO → Skip
    │
    └── NO → Is it a full-stack project?
        └── YES → Install: core-be + std-fe
                  Pack: frontend-stratos-core (minimum)
```

### Bundle Quick Reference

| Project Type | Modules | Extension Packs |
|-------------|---------|-----------------|
| Backend API (Java/Quarkus) | `core-be` | None |
| React MFE (basic) | `std-fe` | `frontend-stratos-core` |
| React MFE (with search) | `std-fe` | `frontend-stratos-core` + `frontend-enterprise-search` |
| React MFE (with review) | `std-fe` + `aws-fe` | `frontend-stratos-core` + `frontend-dual-agent-review` |
| React MFE (full stack) | `std-fe` + `aws-fe` | All 3 frontend packs |
| Full-stack (BE + FE) | `core-be` + `std-fe` | `frontend-stratos-core` (minimum) |

See PLAYBOOK.md §Frontend Tailored Packs for installation order and usage.
