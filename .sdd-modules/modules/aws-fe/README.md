# Acme FE Module

> Tailored frontend pack for Acme FE applications, including reusable instructions, prompt bundles, setup references, and agent patches.

## What This Module Provides

The `aws-fe` module packages the reusable parts of `_tailored-framework-Acme FE/_framework-aws-fe/` into an Enterprise SDD module.

### Contents Summary

| Category | Count | Description |
|----------|:-----:|-------------|
| **Instructions** | 9 | React, TypeScript, architecture, mock API, Stratos, and advanced-search patterns |
| **Prompts** | 46 | Namespaced prompt bundles under `aws-fe/` for settlement, securities, party-account, and scaffolding workflows |
| **Setup Templates** | 2 | Project guidelines and unit-test guidelines setup references |
| **Agent Patches** | 2 | `Neo` generator profile and `Smith` reviewer profile |
| **Copilot Supplement** | 1 | Summary of the installed instruction and prompt namespaces |

## Installation

```bash
sdd module install aws-fe
```

## Installed Targets

- Instructions are copied to `.github/instructions/aws-fe/`
- Prompts are copied to `.github/prompts/aws-fe/`
- Setup templates are copied to `.specify/templates/setup/`
- The copilot supplement is appended to `.github/copilot-instructions.md`

## Manual Review

- `agent-patches/agent-neo-generator.patch.md` captures the Acme FE generator behavior profile.
- `agent-patches/agent-smith-reviewer.patch.md` captures the Acme FE review profile.
- `setup/project-guidelines.setup.md` and `setup/unit-tests.setup.md` should be reviewed before using the prompt bundles broadly in a target project.

## Removal

```bash
sdd module remove aws-fe
```

Nested prompt and instruction paths are tracked fully in the module registry, so removal is safe even for namespaced files.