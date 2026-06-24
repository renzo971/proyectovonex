---
applyTo: ".specify/cli/**,.specify/scripts/**,enterprise-sdd/CLI-DEPRECATIONS.md"
---

# CLI Deprecation Policy

Deprecations are additive, versioned, and machine-readable.

## Lifecycle Contract

| Stage | Behavior |
|-------|----------|
| **Active** | Flag works silently. |
| **Deprecated** | Flag still works and emits a structured warning. |
| **Removed** | Parser rejects the flag and the entry moves to `Removed`. |

Deprecation MUST span at least two minor versions before removal. Patch releases never remove deprecated flags.

## Required Warning Fields

Every deprecation warning MUST include:
- `replacement` field
- `removal_version` field
- `migration` field

Human-readable labels: Replacement, Removal version, and Migration link.

Catalog every deprecation in [CLI-DEPRECATIONS.md](../../CLI-DEPRECATIONS.md) before merging and emit warnings through `@deprecated(...)` or `emit_deprecation_warning()`.

## Boundary Rules

- **Always Do:** catalogue the change, emit the standard warning, and point to the migration link.
- **Ask First:** same-release removals or deprecations with no replacement.
- **Never Do:** remove silently, omit required fields, or emit ad-hoc deprecation text.

See [cli-deprecation-policy-detail.instructions.md](cli-deprecation-policy-detail.instructions.md) for author workflow, example warning, removal workflow, and doctor integration detail.
