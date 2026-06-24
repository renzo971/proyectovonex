# Std-FE Module

> Tailored frontend guidance for Convergence microfrontends, sourced from the FE framework bundle stored in this monorepo.

## What This Module Provides

The `std-fe` module installs the FE framework knowledge into Enterprise SDD projects without duplicating the original source files inside the module package.

### Contents Summary

| Category | Count | Description |
|----------|:-----:|-------------|
| **Instructions** | 5 | FE architecture, general coding, Stratos, Stratos UI agent, and E2E testing |
| **Setup Templates** | 1 | Copilot test instructions reference template |
| **Agent Patches** | 1 | `Severus` behavior profile for feature generation |
| **Copilot Supplement** | 1 | Module-specific guidance and installed instruction references |

## Installation

```bash
sdd module install std-fe
```

## Installed Targets

- Instructions are copied to `.github/instructions/fe/`
- The test guidance template is copied to `.specify/templates/setup/std-fe-copilot-test-instructions.setup.md`
- The copilot supplement is appended to `.github/copilot-instructions.md`

## Manual Review

- Review `agent-patches/agent-severus-generator.patch.md` before adapting any FE-specific custom agent.
- The module package was extracted from `_tailored-framework-FE/_framework-FE/` and is now self-contained inside `.sdd-modules/modules/std-fe/`.

## Removal

```bash
sdd module remove std-fe
```

Removal works with nested paths because the module installer records the full installed file list.
