# Scripts Directory — Catalog

> **Last updated:** April 17, 2026

All scripts live in `.specify/scripts/`. Each `.sh` script has a `.ps1` counterpart for cross-platform parity unless noted.

## CLI-Mapped Scripts

These scripts are invoked by the Python CLI (`sdd <command>`) via command modules in `.specify/cli/sdd/commands/`.

| Script | CLI Command | Purpose |
|--------|-------------|---------|
| `init.sh` | `sdd init` | Initialize SDD framework in a project |
| `new-feature.sh` | `sdd new` | Create a new feature with spec scaffolding |
| `validate-gate.sh` | `sdd gate` | Validate quality gates 1–4 |
| `status.sh` | `sdd status` | Show feature status and progress |
| `analyze-consistency.sh` | `sdd analyze` | Check cross-artifact consistency |
| `generate-report.sh` | `sdd report` | Generate delivery report |
| `resume-feature.sh` | `sdd resume` | Resume a feature from checkpoint |
| `context-bridge.sh` | `sdd bridge` | Generate context bridge document |
| `module-install.sh` | `sdd module install` | Install an SDD module |
| `module-remove.sh` | `sdd module remove` | Remove an SDD module |
| `module-list.sh` | `sdd module list` | List installed modules |
| `generate-adapters.py` | `sdd adapters generate` | Generate IDE adapters from canonical source |
| `validate-command-taxonomy.sh` | `sdd skill validate-mapping` | Validate command taxonomy alignment |
| `tasks-to-issues.sh` | `sdd sync push` | Push tasks to issue tracker |
| `issues-to-tasks.sh` | `sdd sync pull` | Pull issues to tasks |
| `skill-list.sh` | `sdd skill list` | List available skills |
| `skill-validate.sh` | `sdd skill validate` | Validate skill files |
| `skill-run.sh` | `sdd skill run` | Run a curated skill |
| `extension-validate.sh` | `sdd extension validate` | Validate extension manifests |
| `extension-doctor.sh` | `sdd extension doctor` | Diagnose extension issues |
| `memory-status.sh` | `sdd memory status` | Show memory system status |
| `memory-sync.sh` | `sdd memory sync` | Synchronize memory files |
| `memory-doctor.sh` | `sdd memory doctor` | Diagnose memory system health |
| `autonomy-status.sh` | `sdd autonomy status` | Show autonomy execution status |
| `worktree-ship.sh` | `sdd worktree ship` | Ship a worktree (merge + cleanup) |
| `sdd` / `sdd.ps1` | — | CLI entry point scripts |

## Internal Scripts

These scripts are **not** directly exposed via CLI commands. They are invoked by other scripts in the chain and should not be called directly by users.

| Script | Called By | Purpose |
|--------|-----------|---------|
| `extension-resolve-conflicts.sh` | `extension-doctor.sh` | Resolve extension conflicts; invoked in `--dry-run` mode for diagnostics |
| `memory-index.sh` | `memory-status.sh`, `memory-sync.sh`, `init.sh` | Build/update `memory-index.md` for a feature |
| `worktree-create.sh` | `new-feature.sh` | Create git worktree for feature isolation |
| `autonomy-evidence.py` | `autonomy-status.sh`, `status.sh` | Sync autonomy cycle evidence; generate structured verdicts and progress ledger |

## Calling Chain

```
sdd <command> → Python CLI module → Shell script (CLI-mapped) → Shell/Python script (Internal)
```

Examples:
- `sdd new <id>` → `new-feature.sh` → `worktree-create.sh` (optional)
- `sdd memory status` → `memory-status.sh` → `memory-index.sh`
- `sdd extension doctor` → `extension-doctor.sh` → `extension-resolve-conflicts.sh --dry-run`
- `sdd autonomy status` → `autonomy-status.sh` → `autonomy-evidence.py`
