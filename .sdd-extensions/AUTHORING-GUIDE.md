# Tailored Extension Authoring Guide

This guide defines the Wave 11 conventions for tailored frontend extensions.

## Required Conventions

1. Use `sdd-extension-` prefix for extension names.
2. Use `type: tailored-frontend` for tailored frontend extensions.
3. Choose a `namespacePrefix` — a lowercase identifier for your domain (e.g. `fe`, `aws-fe`, `charts`, `forms`). Built-in prefixes are `fe` and `aws-fe`; any lowercase alphanumeric string is valid.
4. Place prompts under namespace folders:
   - `prompts/<namespacePrefix>/...`
   - Example: `prompts/fe/...`, `prompts/aws-fe/...`
5. Name instruction files with namespace prefix:
   - `<namespacePrefix>-*.instructions.md`
   - Example: `fe-*.instructions.md`, `aws-fe-*.instructions.md`
6. Choose a `domainCategory` — a short label for the extension's domain. Built-in values: `stratos`, `search`, `review`. Open to custom values (e.g. `charts`, `forms`, `accessibility`).
7. Do not patch immutable core agents:
   - architect, analysis, requirement-analyst, software-engineer, test-engineer, review, constitution
8. Use additive layering only in this order:
   - module -> extension -> preset

## Validation Commands

```bash
sdd extension validate .sdd-extensions/extensions/sdd-extension-tailored-dummy-fe --format tailored
sdd extension doctor .sdd-extensions/extensions/sdd-extension-tailored-dummy-fe
```

## Conflict Checks

Use the resolver in dry-run mode to review install plan and fail-fast conflicts:

```bash
./.specify/scripts/extension-resolve-conflicts.sh .sdd-extensions/extensions/sdd-extension-tailored-dummy-fe --dry-run
```

## Compatibility Matrix

`compatibilityMatrix` supports these optional arrays:

- `requiredModules`
- `blockedModules`
- `requiredPresets`
- `blockedPresets`

The validator compares these with installed modules and active preset configuration.
