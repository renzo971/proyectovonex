---
applyTo: ".specify/cli/**,.specify/scripts/**,enterprise-sdd/CLI-DEPRECATIONS.md"
description: Detailed CLI deprecation workflow, example warning, and doctor integration
---

# CLI Deprecation Policy Detail

See [cli-deprecation-policy.instructions.md](cli-deprecation-policy.instructions.md) for the runtime contract.

## Example Warning

```text
[deprecation] sdd skill validate --legacy-mode
              replacement: --eval
              removal_version: 0.7.0
              migration: enterprise-sdd/CLI-DEPRECATIONS.md#skill-validate--legacy-mode
```

## Author Workflow

When deprecating a CLI surface:
1. Add the entry to the Active table in [CLI-DEPRECATIONS.md](../../CLI-DEPRECATIONS.md).
2. Wrap the parser or handler with `@deprecated(...)` from `sdd.utils.deprecation`.
3. Document the replacement in the relevant playbook section.
4. Add tests that assert the warning is emitted.

When the removal version is reached:
1. Move the entry from Active to Removed with the removal date and landed version.
2. Remove the parser hook and the deprecation wrapper.
3. Keep migration guidance available for adopters.

## Doctor Integration

`sdd doctor` scans `.specify/config.yaml` and committed shell or PowerShell scripts for deprecated flags listed in the Active table. Hits surface as a WARN row with the file, line, and migration link.
