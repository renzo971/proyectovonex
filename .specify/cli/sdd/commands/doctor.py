"""`sdd doctor` — validate framework installation integrity."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from sdd.utils.config import find_repo_root
from sdd.utils import output


INSTRUCTION_MAX_LINES = 50


def add_doctor_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "doctor",
        help="validate SDD framework installation integrity",
        description=(
            "Check that all expected agent files, instructions, skills, templates, "
            "and modules exist and are well-formed. Outputs PASS/WARN/FAIL per category."
        ),
    )
    p.add_argument(
        "--description-length",
        dest="description_length",
        action="store_true",
        default=False,
        help="run only the frontmatter description-length check (Wave 23 §23.A.20)",
    )
    p.add_argument(
        "--context",
        dest="context",
        action="store_true",
        default=False,
        help="shorthand for `sdd bridge --context-check` (Wave 23 §23.A.24)",
    )
    p.add_argument(
        "--suggest-upgrade",
        dest="suggest_upgrade",
        action="store_true",
        default=False,
        help="hint to upgrade install profile when phase activity exceeds tier (Wave 23 §23.A.18)",
    )
    p.add_argument(
        "--artifact-integrity",
        dest="artifact_integrity",
        action="store_true",
        default=False,
        help="run only the artifact-integrity drift scan (Wave 23 §23.B.6)",
    )
    p.add_argument(
        "--ci-action-pin",
        dest="ci_action_pin",
        action="store_true",
        default=False,
        help="run only the CI action SHA-pin check (Wave 23 §23.B.12)",
    )
    p.add_argument(
        "--strict",
        dest="strict",
        action="store_true",
        default=False,
        help="promote drift/policy WARN findings to ERROR (Wave 23 §23.B.6)",
    )
    p.add_argument(
        "--policy-compliance",
        dest="policy_compliance",
        action="store_true",
        default=False,
        help="audit installed modules against .sdd-modules/policy.yaml (Wave 26 §25 #1 A.10)",
    )
    p.add_argument(
        "--policy-preflight",
        dest="policy_preflight",
        action="store_true",
        default=False,
        help="resolve policy chain and validate schema without changing anything (Wave 26 §25 #1 A.12)",
    )
    p.add_argument(
        "--format",
        dest="format",
        choices=["text", "sarif"],
        default="text",
        help="output format for focused checks (Wave 26 §25 #1 A.11; SARIF emitted for --policy-compliance)",
    )
    p.add_argument(
        "--atomic-write-discipline",
        dest="atomic_write_discipline",
        action="store_true",
        default=False,
        help="scan the CLI tree for raw write_text/write_bytes/json.dump call sites (Wave 26 §B.7)",
    )
    p.add_argument(
        "--memory-index",
        dest="memory_index",
        action="store_true",
        default=False,
        help="rebuild and validate the derived memory index is disposable (Wave 27 §26 #1 A.3)",
    )
    p.add_argument(
        "--registry-audit",
        dest="registry_audit",
        action="store_true",
        default=False,
        help="flag on-disk modules/skills/extensions with no registry.json entry (Wave 27 §26 #3 A.12)",
    )
    p.add_argument(
        "--activation-discipline",
        dest="activation_discipline",
        action="store_true",
        default=False,
        help="assert every agent file declares an ordered mandatory-startup-files block (Wave 27 §26 #5 B.6)",
    )
    from sdd.io import add_json_flags
    add_json_flags(p)


def run_doctor(args: argparse.Namespace) -> int:
    from sdd.io import wrap_envelope
    return wrap_envelope(args, "doctor", lambda: _run_doctor_inner(args))


def _run_doctor_inner(args: argparse.Namespace) -> int:
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    # Wave 23 §23.A.20/§23.A.24/§23.A.18/§23.B.6/§23.B.12 — focused single-check entry points.
    if getattr(args, "description_length", False):
        return _run_description_length_check(repo_root)
    if getattr(args, "context", False):
        return _run_context_shorthand(repo_root)
    if getattr(args, "suggest_upgrade", False):
        return _run_suggest_upgrade(repo_root)
    if getattr(args, "artifact_integrity", False):
        return _run_artifact_integrity_check(repo_root, strict=getattr(args, "strict", False))
    if getattr(args, "ci_action_pin", False):
        return _run_ci_action_pin_check(repo_root)
    if getattr(args, "policy_preflight", False):
        return _run_policy_preflight(repo_root)
    if getattr(args, "policy_compliance", False):
        return _run_policy_compliance(
            repo_root,
            strict=getattr(args, "strict", False),
            output_format=getattr(args, "format", "text"),
        )
    if getattr(args, "atomic_write_discipline", False):
        return _run_atomic_write_discipline(repo_root)
    if getattr(args, "memory_index", False):
        return _run_memory_index_check(repo_root)
    if getattr(args, "registry_audit", False):
        return _run_registry_audit(
            repo_root,
            strict=getattr(args, "strict", False),
            output_format=getattr(args, "format", "text"),
        )
    if getattr(args, "activation_discipline", False):
        return _run_activation_discipline_check(repo_root)

    github = repo_root / ".github"
    specify = repo_root / ".specify"
    results: list[tuple[str, str, str]] = []  # (category, status, detail)

    # 1. Agent check
    agents_dir = github / "agents"
    if agents_dir.exists():
        agents = list(agents_dir.glob("*.agent.md"))
        if agents:
            results.append(("Agents", "PASS", f"{len(agents)} agent files found"))
        else:
            results.append(("Agents", "WARN", "Agents directory exists but no .agent.md files found"))
    else:
        results.append(("Agents", "FAIL", f"Missing directory: {agents_dir.relative_to(repo_root)}"))

    # 2. Instruction check
    instructions_dir = github / "instructions"
    if instructions_dir.exists():
        instructions = list(instructions_dir.glob("*.instructions.md"))
        if instructions:
            results.append(("Instructions", "PASS", f"{len(instructions)} instruction files found"))
            oversized: list[tuple[str, int]] = []
            for instruction in instructions:
                try:
                    line_count = len(instruction.read_text(encoding="utf-8").splitlines())
                except OSError:
                    continue
                if line_count > INSTRUCTION_MAX_LINES:
                    oversized.append((instruction.name, line_count))

            if oversized:
                oversized_sorted = sorted(oversized, key=lambda x: x[0])
                preview = ", ".join(f"{name} ({count})" for name, count in oversized_sorted[:5])
                extra = "" if len(oversized_sorted) <= 5 else f" +{len(oversized_sorted) - 5} more"
                results.append((
                    "Instruction Size",
                    "WARN",
                    f"{len(oversized_sorted)} instruction files exceed {INSTRUCTION_MAX_LINES} lines: {preview}{extra}",
                ))
            else:
                results.append((
                    "Instruction Size",
                    "PASS",
                    f"All instruction files are <= {INSTRUCTION_MAX_LINES} lines",
                ))
        else:
            results.append(("Instructions", "WARN", "Instructions directory exists but no files found"))
    else:
        results.append(("Instructions", "FAIL", f"Missing directory: {instructions_dir.relative_to(repo_root)}"))

    # 3. Skill check
    skills_github = github / "skills"
    skills_specify = specify / "skills"
    skill_count = 0
    if skills_github.exists():
        skill_count += sum(1 for d in skills_github.iterdir() if d.is_dir() and (d / "SKILL.md").exists())
    if skills_specify.exists():
        skill_count += sum(1 for d in skills_specify.iterdir() if d.is_dir() and (d / "SKILL.md").exists())
    if skill_count > 0:
        results.append(("Skills", "PASS", f"{skill_count} skills with SKILL.md found"))
    elif skills_github.exists() or skills_specify.exists():
        results.append(("Skills", "WARN", "Skills directory exists but no SKILL.md files found"))
    else:
        results.append(("Skills", "WARN", "No skills directory found"))

    # 4. Template check
    template_dir = specify / "templates"
    if template_dir.exists():
        templates = list(template_dir.glob("*.md"))
        if templates:
            results.append(("Templates", "PASS", f"{len(templates)} template files found"))
        else:
            results.append(("Templates", "WARN", "Templates directory exists but no .md files found"))
    else:
        results.append(("Templates", "FAIL", f"Missing directory: {template_dir.relative_to(repo_root)}"))

    # 5. CLI version check
    pyproject = repo_root / "pyproject.toml"
    if pyproject.exists():
        results.append(("CLI Version", "PASS", f"pyproject.toml found"))
    else:
        results.append(("CLI Version", "WARN", "pyproject.toml not found — CLI may not be installed"))

    # 6. Module check
    modules_dir = repo_root / ".sdd-modules" / "modules"
    if modules_dir.exists():
        modules = [d for d in modules_dir.iterdir() if d.is_dir()]
        if modules:
            results.append(("Modules", "PASS", f"{len(modules)} modules found"))
        else:
            results.append(("Modules", "WARN", "Modules directory exists but no modules found"))
    else:
        results.append(("Modules", "WARN", "No modules directory found"))

    # 6b. Module integrity (Wave 20 §20.C.6) — hash drift check on installed modules.
    try:
        from sdd.utils import module_integrity

        verify_results = module_integrity.verify_all(repo_root)
        drift_rows: list[tuple[str, str, str]] = []
        clean = 0
        skipped = 0
        for vr in verify_results:
            if not vr.has_baseline:
                skipped += 1
                continue
            if vr.is_clean:
                clean += 1
                continue
            for d in vr.file_drifts:
                if d.actual is None:
                    drift_rows.append(("Module Integrity", "WARN",
                                       f"{vr.module}: file missing {d.path}"))
                else:
                    drift_rows.append(("Module Integrity", "WARN",
                                       f"{vr.module}: drift {d.path} ({d.expected[:8]} → {d.actual[:8]})"))
            if (vr.expected_manifest_sha256 and vr.actual_manifest_sha256
                    and vr.expected_manifest_sha256 != vr.actual_manifest_sha256
                    and not vr.file_drifts):
                drift_rows.append(("Module Integrity", "WARN",
                                   f"{vr.module}: manifest sha256 drift"))
        if verify_results:
            if drift_rows:
                results.extend(drift_rows)
            elif clean > 0:
                results.append(("Module Integrity", "PASS",
                                f"{clean} module(s) hash-clean ({skipped} without baseline)"))
            elif skipped > 0:
                results.append(("Module Integrity", "WARN",
                                f"No modules have a hash baseline yet ({skipped} module(s))"))
    except Exception as exc:  # noqa: BLE001 — doctor must never crash
        results.append(("Module Integrity", "WARN", f"check skipped: {exc}"))

    # 6c. Deprecated CLI flags (Wave 20 §20.C.10) — scan config + scripts.
    try:
        from sdd.utils import deprecation

        deprecated_hits = deprecation.scan_repo_for_deprecated_usage(repo_root)
        if deprecated_hits:
            for hit in deprecated_hits:
                results.append((
                    "CLI Deprecations",
                    "WARN",
                    f"{hit.flag} used in {hit.path}:{hit.line_no} (replacement: {hit.replacement})",
                ))
        else:
            results.append(("CLI Deprecations", "PASS",
                            "No deprecated CLI flags detected in committed scripts/config"))
    except Exception as exc:  # noqa: BLE001
        results.append(("CLI Deprecations", "WARN", f"check skipped: {exc}"))

    # 6d. Past-gate deprecated artifacts (Wave 27 §26 #8 C.10).
    try:
        from sdd.utils import deprecation as _dep
        from sdd.commands.init import _version_reached, _CURRENT_VERSION

        catalog = _dep.load_active_catalog(repo_root)
        past_gate = [e for e in catalog if _version_reached(e.removal_version, _CURRENT_VERSION)]
        if past_gate:
            for entry in past_gate:
                results.append((
                    "Past-Gate Deprecations",
                    "WARN",
                    f"'{entry.flag}' reached removal gate {entry.removal_version} "
                    f"(current {_CURRENT_VERSION}) — run `sdd init --upgrade` to migrate",
                ))
        else:
            results.append(("Past-Gate Deprecations", "PASS",
                            "No past-gate deprecated artifacts detected"))
    except Exception as exc:  # noqa: BLE001
        results.append(("Past-Gate Deprecations", "WARN", f"check skipped: {exc}"))

    # 7. Schema check
    schema_dir = specify / "schemas"
    if schema_dir.exists():
        schemas = list(schema_dir.glob("*.json"))
        valid = 0
        invalid = 0
        for s in schemas:
            try:
                json.loads(s.read_text(encoding="utf-8"))
                valid += 1
            except (json.JSONDecodeError, OSError):
                invalid += 1
                results.append(("Schemas", "FAIL", f"Invalid JSON: {s.name}"))
        if invalid == 0 and valid > 0:
            results.append(("Schemas", "PASS", f"{valid} valid JSON schemas"))
    else:
        results.append(("Schemas", "WARN", "No schemas directory found"))

    # 8. Wave 23 §23.A.20 — frontmatter description-length check
    try:
        warn_finds, err_finds = _scan_descriptions(repo_root)
        if err_finds:
            for path, n, _ in err_finds[:5]:
                results.append((
                    "Description Length",
                    "FAIL",
                    f"{path.relative_to(repo_root)} description is {n} chars (> {_DESC_ERROR_CHARS})",
                ))
            if len(err_finds) > 5:
                results.append((
                    "Description Length",
                    "FAIL",
                    f"+{len(err_finds) - 5} more ERROR-level finding(s)",
                ))
        if warn_finds:
            preview = ", ".join(p.name for p, _, _ in warn_finds[:5])
            extra = "" if len(warn_finds) <= 5 else f" +{len(warn_finds) - 5} more"
            results.append((
                "Description Length",
                "WARN",
                f"{len(warn_finds)} description(s) > {_DESC_WARN_CHARS} chars: {preview}{extra}",
            ))
        if not warn_finds and not err_finds:
            results.append(("Description Length", "PASS", "all descriptions within budget"))
    except Exception as exc:  # noqa: BLE001
        results.append(("Description Length", "WARN", f"check skipped: {exc}"))

    # 9. Wave 23 §23.B.3 — implementation agents must list constitution.md
    #    in their `mandatory-startup-files` frontmatter list.
    try:
        missing_startup = _scan_mandatory_startup(repo_root)
        strict = bool(getattr(args, "strict", False))
        level = "FAIL" if strict else "WARN"
        if not missing_startup:
            results.append((
                "Mandatory Startup",
                "PASS",
                "implementation agents list constitution.md in mandatory-startup-files",
            ))
        else:
            for agent_path in missing_startup[:5]:
                results.append((
                    "Mandatory Startup",
                    level,
                    f"{agent_path.relative_to(repo_root)} missing constitution.md from mandatory-startup-files",
                ))
            if len(missing_startup) > 5:
                results.append((
                    "Mandatory Startup",
                    level,
                    f"+{len(missing_startup) - 5} more agent(s)",
                ))
    except Exception as exc:  # noqa: BLE001
        results.append(("Mandatory Startup", "WARN", f"check skipped: {exc}"))

    # 10. Wave 23 §23.B.6 — artifact integrity drift scan.
    try:
        from sdd.utils import artifact_integrity

        drifts = artifact_integrity.verify_all(repo_root)
        strict = bool(getattr(args, "strict", False))
        level = "FAIL" if strict else "WARN"
        if not drifts:
            ledger = artifact_integrity.load_ledger(repo_root)
            if ledger:
                results.append((
                    "Artifact Integrity",
                    "PASS",
                    f"{len(ledger)} tracked artifact(s) match recorded SHA-256",
                ))
            else:
                results.append((
                    "Artifact Integrity",
                    "PASS",
                    "no artifacts tracked yet (ledger empty)",
                ))
        else:
            for d in drifts[:5]:
                if d.actual_sha256 is None:
                    results.append(("Artifact Integrity", level, f"missing on disk: {d.artifact}"))
                else:
                    results.append((
                        "Artifact Integrity",
                        level,
                        f"drift detected: {d.artifact} ({d.expected_sha256[:8]}→{d.actual_sha256[:8]})",
                    ))
            if len(drifts) > 5:
                results.append(("Artifact Integrity", level, f"+{len(drifts) - 5} more drift entries"))
    except Exception as exc:  # noqa: BLE001
        results.append(("Artifact Integrity", "WARN", f"check skipped: {exc}"))

    # 11. Wave 23 §23.B.12 — CI action SHA-pin scan.
    try:
        from sdd.utils import ci_pin_scan

        unpinned = ci_pin_scan.scan(repo_root)
        if not unpinned:
            results.append(("CI Action Pin", "PASS", "all `uses:` references SHA-pinned"))
        else:
            for u in unpinned[:5]:
                results.append((
                    "CI Action Pin",
                    "FAIL",
                    f"{u.path}:{u.line_no} unpinned reference `{u.reference}`",
                ))
            if len(unpinned) > 5:
                results.append(("CI Action Pin", "FAIL", f"+{len(unpinned) - 5} more unpinned reference(s)"))
    except Exception as exc:  # noqa: BLE001
        results.append(("CI Action Pin", "WARN", f"check skipped: {exc}"))

    # Print results
    print("\nSDD Doctor — Framework Health Check\n")
    has_fail = False
    for category, status, detail in results:
        marker = {"PASS": "✅", "WARN": "⚠️", "FAIL": "❌"}.get(status, "?")
        print(f"  {marker} {status:<4}  {category:<15} {detail}")
        if status == "FAIL":
            has_fail = True

    print()
    if has_fail:
        output.error("Framework health check found FAIL conditions — see above")
        return 1
    else:
        output.success("Framework health check passed")
        return 0


# =====================================================================
# Wave 23 §23.A — focused-flag helpers
# =====================================================================


_DESC_WARN_CHARS = 100
_DESC_ERROR_CHARS = 200


def _scan_descriptions(repo_root: Path) -> tuple[list[tuple[Path, int, str]], list[tuple[Path, int, str]]]:
    """Wave 23 §23.A.20 — return (warn_findings, error_findings).

    Each finding is (file_path, char_count, description_excerpt).
    """
    import re

    warn_findings: list[tuple[Path, int, str]] = []
    error_findings: list[tuple[Path, int, str]] = []

    targets: list[Path] = []
    for sub in (".github/agents", ".github/instructions", ".github/prompts"):
        d = repo_root / sub
        if d.exists():
            targets.extend(d.rglob("*.md"))
    skills_dir = repo_root / ".github" / "skills"
    if skills_dir.exists():
        targets.extend(skills_dir.rglob("SKILL.md"))

    fm_re = re.compile(r"^---\n(.*?)\n---", re.DOTALL)
    desc_re = re.compile(r'^description\s*:\s*(.+?)\s*$', re.MULTILINE)

    for path in targets:
        try:
            text = path.read_text(encoding="utf-8")
        except Exception:
            continue
        m = fm_re.match(text)
        if not m:
            continue
        body = m.group(1)
        d = desc_re.search(body)
        if not d:
            continue
        desc = d.group(1).strip().strip('"').strip("'")
        n = len(desc)
        if n > _DESC_ERROR_CHARS:
            error_findings.append((path, n, desc[:80]))
        elif n > _DESC_WARN_CHARS:
            warn_findings.append((path, n, desc[:80]))
    return warn_findings, error_findings


def _run_description_length_check(repo_root: Path) -> int:
    """Wave 23 §23.A.20 — focused description-length scanner."""
    warn, err = _scan_descriptions(repo_root)
    print("Wave 23 §23.A.20 — Frontmatter description-length check")
    print("=" * 72)
    print(f"WARN  threshold: > {_DESC_WARN_CHARS} chars")
    print(f"ERROR threshold: > {_DESC_ERROR_CHARS} chars")
    print()
    if not warn and not err:
        output.success("All frontmatter descriptions within budget.")
        return 0
    for path, n, desc in err:
        print(f"  ❌ ERROR ({n} chars) {path.relative_to(repo_root)}")
        print(f"     description: {desc}...")
    for path, n, desc in warn:
        print(f"  ⚠️  WARN  ({n} chars) {path.relative_to(repo_root)}")
        print(f"     description: {desc}...")
    print()
    if err:
        output.error(f"{len(err)} ERROR-level finding(s); {len(warn)} WARN-level.")
        return 1
    output.warn(f"{len(warn)} WARN-level finding(s); 0 ERROR.")
    return 0


def _run_context_shorthand(repo_root: Path) -> int:
    """Wave 23 §23.A.24 — alias for `sdd bridge --context-check`."""
    import argparse as _ap

    from sdd.commands.bridge import run_bridge

    ns = _ap.Namespace(
        feature_id=None,
        phase=None,
        explain=False,
        context_check=True,
        model=None,
        no_record_hits=True,
    )
    return run_bridge(ns)


def _run_suggest_upgrade(repo_root: Path) -> int:
    """Wave 23 §23.A.18 — recommend upgrading the install profile when needed."""
    import json as _json

    profile_path = repo_root / ".specify" / "install-profile.json"
    if not profile_path.exists():
        output.warn("No install-profile.json — assuming legacy/full install. Nothing to suggest.")
        return 0
    try:
        prof = _json.loads(profile_path.read_text(encoding="utf-8"))
    except Exception as exc:
        output.error(f"Could not read install-profile.json: {exc}")
        return 2

    tier = int(prof.get("tier", 0))
    label = prof.get("profile", "?")

    # Look at .specify/specs/*/state.json (or phase-ledger) for recent activity.
    specs_dir = repo_root / ".specify" / "specs"
    max_phase = 0
    if specs_dir.exists():
        for spec in specs_dir.iterdir():
            state = spec / "state.json"
            if state.exists():
                try:
                    s = _json.loads(state.read_text(encoding="utf-8"))
                    p = int(str(s.get("phase", "0")).split(".")[0])
                    if p > max_phase:
                        max_phase = p
                except Exception:
                    continue

    print(f"Wave 23 §23.A.18 — Install profile: {label} (tier {tier}); max active phase: {max_phase}")
    if tier == 1 and max_phase >= 2:
        output.warn("Active feature reached Phase 2+; consider running `sdd init --upgrade`.")
        return 0
    if tier == 2 and max_phase >= 4:
        output.warn("Active feature reached Phase 4+; consider running `sdd init --full`.")
        return 0
    output.success("Install profile is sufficient for current phase activity.")
    return 0


# =====================================================================
# Wave 23 §23.B — focused-flag helpers
# =====================================================================


# Implementation agents that MUST list constitution.md in their
# `mandatory-startup-files` frontmatter. Wave 23 §23.B.3.
_IMPLEMENTATION_AGENTS = ("software-engineer",)


def _scan_mandatory_startup(repo_root: Path) -> list[Path]:
    """Wave 23 §23.B.3 — return implementation agents missing constitution.md
    from their `mandatory-startup-files` frontmatter list."""
    import re

    agents_dir = repo_root / ".github" / "agents"
    missing: list[Path] = []
    if not agents_dir.exists():
        return missing
    fm_re = re.compile(r"^---\n(.*?)\n---", re.DOTALL)
    for stem in _IMPLEMENTATION_AGENTS:
        candidates = list(agents_dir.glob(f"{stem}.agent.md"))
        if not candidates:
            continue
        path = candidates[0]
        try:
            text = path.read_text(encoding="utf-8")
        except OSError:
            missing.append(path)
            continue
        m = fm_re.match(text)
        if not m:
            missing.append(path)
            continue
        block = m.group(1)
        # Look for `mandatory-startup-files:` followed by a list containing constitution.md
        if "mandatory-startup-files" not in block:
            missing.append(path)
            continue
        if ".specify/memory/constitution.md" not in block:
            missing.append(path)
    return missing


def _run_artifact_integrity_check(repo_root: Path, *, strict: bool) -> int:
    """Wave 23 §23.B.6 — focused artifact-integrity scan."""
    from sdd.utils import artifact_integrity

    drifts = artifact_integrity.verify_all(repo_root)
    ledger = artifact_integrity.load_ledger(repo_root)
    print("Wave 23 §23.B.6 — Artifact-integrity drift check")
    print("=" * 72)
    print(f"Tracked artifacts: {len(ledger)} (strict={strict})")
    print()
    if not drifts:
        if ledger:
            output.success(f"All {len(ledger)} tracked artifact(s) match recorded SHA-256.")
        else:
            output.success("Ledger empty — no artifacts tracked yet.")
        return 0
    for d in drifts:
        if d.actual_sha256 is None:
            print(f"  ❌ MISSING  {d.artifact}")
            print(f"     recorded sha256: {d.expected_sha256}")
        else:
            print(f"  ⚠️  DRIFT   {d.artifact}")
            print(f"     recorded: {d.expected_sha256}")
            print(f"     actual:   {d.actual_sha256}")
        print(f"     phase: {d.phase}  written-by: {d.written_by}  written-at: {d.written_at}")
    print()
    msg = f"{len(drifts)} drift entrie(s) detected."
    if strict:
        output.error(msg)
        return 1
    output.warn(msg + " (re-run with --strict to ERROR)")
    return 0


def _run_ci_action_pin_check(repo_root: Path) -> int:
    """Wave 23 §23.B.12 — focused CI action SHA-pin scan."""
    from sdd.utils import ci_pin_scan

    unpinned = ci_pin_scan.scan(repo_root)
    print("Wave 23 §23.B.12 — CI action SHA-pin check")
    print("=" * 72)
    if not unpinned:
        output.success("All `uses:` references are SHA-pinned (40-char commit hash).")
        return 0
    for u in unpinned:
        print(f"  ❌ UNPINNED  {u.path}:{u.line_no}")
        print(f"     reference: {u.reference}")
    print()
    output.error(
        f"{len(unpinned)} unpinned `uses:` reference(s); pin to a 40-char SHA "
        f"(see ci-security.instructions.md)."
    )
    return 1


# ---------------------------------------------------------------------------
# Wave 26 §25 #1 — A.10 / A.11 / A.12 — Policy compliance & preflight
# ---------------------------------------------------------------------------


def _run_policy_preflight(repo_root: Path) -> int:
    """A.12 — resolve `extends:` chain + schema-validate the project policy."""
    from sdd.policy import (
        PolicyError,
        PolicyResolutionError,
        load_policy,
        locate_policy_file,
    )

    policy_file = locate_policy_file(repo_root)
    if policy_file is None:
        output.info("No .sdd-modules/policy.yaml present (default-permissive). Nothing to preflight.")
        return 0

    try:
        policy = load_policy(policy_file)
    except PolicyResolutionError as exc:
        output.error(f"Policy resolution failed: {exc}")
        return 1
    except PolicyError as exc:
        output.error(f"Policy validation failed: {exc}")
        return 1

    chain = " → ".join(str(p.relative_to(repo_root) if p.is_relative_to(repo_root) else p)
                        for p in policy.source_chain)
    output.success(f"Policy preflight OK ({len(policy.source_chain)} file(s) in chain): {chain}")
    return 0


def _run_policy_compliance(repo_root: Path, *, strict: bool, output_format: str) -> int:
    """A.10/A.11 — audit installed modules against the project policy."""
    from sdd.policy import (
        PolicyError,
        PolicyResolutionError,
        load_policy,
        locate_policy_file,
    )
    from sdd.policy.gate import read_module_capabilities

    policy_file = locate_policy_file(repo_root)
    if policy_file is None:
        if output_format == "sarif":
            print(json.dumps(_sarif_envelope([]), indent=2))
        else:
            output.info("No .sdd-modules/policy.yaml — skipping policy compliance check.")
        return 0

    try:
        policy = load_policy(policy_file)
    except (PolicyError, PolicyResolutionError) as exc:
        output.error(f"Policy load failed: {exc}")
        return 2

    registry_path = repo_root / ".sdd-modules" / "registry.json"
    findings: list[dict] = []
    if registry_path.exists():
        try:
            registry = json.loads(registry_path.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError) as exc:
            output.error(f"Could not read registry.json: {exc}")
            return 2
        installed = registry.get("modules", {})
        for module_id in installed:
            module_dir = repo_root / ".sdd-modules" / "modules" / module_id
            caps = read_module_capabilities(module_dir) if module_dir.exists() else []
            allowed, reason = policy.is_allowed(
                "modules", module_id, manifest_capabilities=caps
            )
            if not allowed:
                findings.append({
                    "rule_id": "sdd-policy-compliance-drift",
                    "category": "modules",
                    "identifier": module_id,
                    "reason": reason,
                    "level": "error" if strict else "warning",
                })

    if output_format == "sarif":
        print(json.dumps(_sarif_envelope(findings), indent=2))
        return 1 if findings and strict else 0

    if not findings:
        output.success("Policy compliance: all installed modules are allowed by the current policy.")
        return 0

    label = "ERROR" if strict else "WARN"
    output.error(f"Policy compliance: {len(findings)} drift finding(s) ({label}):")
    for f in findings:
        print(f"  - [{f['level'].upper()}] {f['category']}/{f['identifier']}: {f['reason']}")
    return 1 if strict else 0


def _sarif_envelope(findings: list[dict]) -> dict:
    """Wrap policy-compliance findings in a minimal SARIF 2.1.0 envelope."""
    return {
        "version": "2.1.0",
        "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
        "runs": [
            {
                "tool": {
                    "driver": {
                        "name": "sdd-doctor",
                        "informationUri": "https://enterprise-sdd.dev/",
                        "rules": [
                            {
                                "id": "sdd-policy-compliance-drift",
                                "name": "PolicyComplianceDrift",
                                "shortDescription": {"text": "Installed artifact violates project policy."},
                                "helpUri": "https://enterprise-sdd.dev/playbook#module-extension-governance",
                                "defaultConfiguration": {"level": "warning"},
                            }
                        ],
                    }
                },
                "results": [
                    {
                        "ruleId": f["rule_id"],
                        "level": f["level"],
                        "message": {"text": f["reason"]},
                        "properties": {
                            "category": f["category"],
                            "identifier": f["identifier"],
                        },
                    }
                    for f in findings
                ],
            }
        ],
    }


# =====================================================================
# Wave 27 §26 #1 A.3 — derived memory index disposability check
# =====================================================================


def _run_memory_index_check(repo_root: Path) -> int:
    """Prove the derived index is disposable: build twice → identical entries.

    INFO-only: never blocks. Rebuilds `.index.json` from canonical markdown.
    """
    from sdd.utils import memory_index

    first = memory_index.build_index(repo_root)
    memory_index.write_index(repo_root)
    second = memory_index.build_index(repo_root)

    def _stable(idx: dict) -> list:
        return sorted(
            (e["id"], e["fingerprint"], e["duplicate_of"]) for e in idx.get("entries", [])
        )

    identical = _stable(first) == _stable(second)
    entries = second.get("entries", [])
    dup_count = sum(1 for e in entries if e.get("duplicate_of"))

    print("Wave 27 §26 #1 A.3 — derived memory index")
    print("=" * 78)
    print(f"{'Index file':<22}: {memory_index.INDEX_FILE}")
    print(f"{'Entries':<22}: {len(entries)}")
    print(f"{'Duplicates':<22}: {dup_count}")
    status = "PASS" if identical else "WARN"
    detail = "delete → rebuild is identical" if identical else "rebuild was NOT identical"
    print(f"{'Disposable guarantee':<22}: {status} ({detail})")
    print()
    output.info("Index is derived/disposable; markdown stays canonical (Constraint #9).")
    return 0


# =====================================================================
# Wave 27 §26 #3 A.12/A.13 — unmanaged-artifact registry audit
# =====================================================================


def _run_activation_discipline_check(repo_root: Path) -> int:
    """Wave 27 §26 #5 B.6 — assert every agent declares an ordered mandatory-startup-files block.

    Passes when every .agent.md in .github/agents/ contains a `mandatory-startup-files:`
    YAML key with at least one entry. Agents that only list instructions are flagged WARN
    (the field is the machine-readable activation contract). INFO-only; never blocks
    the overall doctor run.
    """
    agents_dir = repo_root / ".github" / "agents"
    if not agents_dir.exists():
        output.warn("No .github/agents/ directory — activation-discipline check skipped.")
        return 0

    import re as _re

    _FM_RE = _re.compile(r"^---\n(.*?)\n---", _re.DOTALL)
    _STARTUP_KEY = "mandatory-startup-files:"

    agents = sorted(agents_dir.glob("*.agent.md"))
    if not agents:
        output.warn("No .agent.md files found — activation-discipline check skipped.")
        return 0

    missing: list[str] = []
    for a in agents:
        text = a.read_text(encoding="utf-8")
        m = _FM_RE.match(text)
        frontmatter = m.group(1) if m else text[:2000]
        if _STARTUP_KEY not in frontmatter:
            missing.append(a.name)

    print("Wave 27 §26 #5 B.6 — activation-discipline check")
    print("=" * 78)
    if not missing:
        output.success(
            f"All {len(agents)} agent(s) declare `mandatory-startup-files:` "
            f"(agent-activation-discipline satisfied)."
        )
        return 0

    for name in missing:
        output.warn(f"  MISSING mandatory-startup-files: {name}")
    print()
    output.info(
        f"{len(missing)} of {len(agents)} agent(s) lack a `mandatory-startup-files:` block. "
        "Add the key per `.github/instructions/agent-activation-discipline.instructions.md`."
    )
    return 0


def _run_registry_audit(repo_root: Path, *, strict: bool, output_format: str) -> int:
    """Flag on-disk modules/skills/extensions absent from registry.json.

    A.12 — enumerate managed roots; report UNMANAGED for unregistered artifacts.
    A.13 — `--strict` fails closed; `--format sarif` emits `sdd-unmanaged-artifact`.
    """
    from sdd.utils import module_integrity

    registry = module_integrity.load_registry(repo_root)
    registered_modules = {
        e.get("name") for e in registry.get("installedModules", []) or []
    }
    registered_skills = {
        e.get("name") for e in registry.get("installedSkills", []) or []
    }
    registered_extensions = {
        e.get("name") for e in registry.get("installedExtensions", []) or []
    }

    findings: list[dict] = []

    modules_dir = repo_root / ".sdd-modules" / "modules"
    if modules_dir.exists():
        for d in sorted(p for p in modules_dir.iterdir() if p.is_dir()):
            if d.name not in registered_modules:
                findings.append({
                    "category": "modules",
                    "identifier": d.name,
                    "path": str(d.relative_to(repo_root)),
                })

    for skills_root in (repo_root / ".github" / "skills", repo_root / ".specify" / "skills"):
        if not skills_root.exists():
            continue
        for d in sorted(p for p in skills_root.iterdir() if p.is_dir()):
            if not (d / "SKILL.md").exists():
                continue
            if d.name not in registered_skills:
                findings.append({
                    "category": "skills",
                    "identifier": d.name,
                    "path": str(d.relative_to(repo_root)),
                })

    extensions_dir = repo_root / ".sdd-extensions"
    if extensions_dir.exists():
        for d in sorted(p for p in extensions_dir.iterdir() if p.is_dir()):
            if d.name not in registered_extensions:
                findings.append({
                    "category": "extensions",
                    "identifier": d.name,
                    "path": str(d.relative_to(repo_root)),
                })

    if output_format == "sarif":
        print(json.dumps(_registry_audit_sarif(findings, strict=strict), indent=2))
        return 1 if findings and strict else 0

    print("Wave 27 §26 #3 A.12 — unmanaged-artifact registry audit")
    print("=" * 78)
    if not findings:
        output.success("All on-disk modules/skills/extensions are registered.")
        return 0

    label = "ERROR" if strict else "WARN"
    output.error(f"{len(findings)} UNMANAGED artifact(s) ({label}):")
    for f in findings:
        print(f"  - [{label}] {f['category']}/{f['identifier']}: {f['path']}")
    print()
    output.info("Run `sdd module adopt <path>` or `sdd skill adopt <path>` to bring under control.")
    return 1 if strict else 0


def _registry_audit_sarif(findings: list[dict], *, strict: bool) -> dict:
    """Wrap unmanaged-artifact findings in a minimal SARIF 2.1.0 envelope (A.13)."""
    level = "error" if strict else "warning"
    return {
        "version": "2.1.0",
        "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
        "runs": [
            {
                "tool": {
                    "driver": {
                        "name": "sdd-doctor",
                        "informationUri": "https://enterprise-sdd.dev/",
                        "rules": [
                            {
                                "id": "sdd-unmanaged-artifact",
                                "name": "UnmanagedArtifact",
                                "shortDescription": {
                                    "text": "On-disk artifact under a managed root has no registry.json entry."
                                },
                                "helpUri": "https://enterprise-sdd.dev/playbook#module-extension-governance",
                                "defaultConfiguration": {"level": "warning"},
                            }
                        ],
                    }
                },
                "results": [
                    {
                        "ruleId": "sdd-unmanaged-artifact",
                        "level": level,
                        "message": {
                            "text": f"Unmanaged {f['category']} '{f['identifier']}' at {f['path']}"
                        },
                        "locations": [
                            {
                                "physicalLocation": {
                                    "artifactLocation": {"uri": f["path"]}
                                }
                            }
                        ],
                        "properties": {
                            "category": f["category"],
                            "identifier": f["identifier"],
                        },
                    }
                    for f in findings
                ],
            }
        ],
    }


# =====================================================================
# Wave 26 §B.7 — atomic-write discipline scanner
# =====================================================================

_ATOMIC_PATTERN = (
    r"\.write_text\("
    r"|\.write_bytes\("
    r"|json\.dump\(open\("
)


def _run_atomic_write_discipline(repo_root: Path) -> int:
    """Wave 26 §B.7 — surface raw artifact-write call sites in the CLI tree.

    Mirrors the `lint-atomic-writes` GitHub workflow (Wave 26 §B.5) so that
    contributors can reproduce the gate locally. Honors
    `_audit/atomic-write-allowlist.txt` (substring match, `#` comments).
    """
    import re

    cli_root = repo_root / ".specify" / "cli" / "sdd"
    allowlist_path = repo_root / "_audit" / "atomic-write-allowlist.txt"
    allow_substrings: list[str] = []
    if allowlist_path.exists():
        for raw in allowlist_path.read_text(encoding="utf-8").splitlines():
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            allow_substrings.append(line)

    pattern = re.compile(_ATOMIC_PATTERN)
    violations: list[tuple[Path, int, str]] = []
    if cli_root.exists():
        for py in cli_root.rglob("*.py"):
            try:
                lines = py.read_text(encoding="utf-8").splitlines()
            except Exception:
                continue
            for idx, text in enumerate(lines, start=1):
                if pattern.search(text):
                    rel = py.relative_to(repo_root)
                    formatted = f"{rel}:{idx}:{text.strip()}"
                    if any(sub in formatted for sub in allow_substrings):
                        continue
                    violations.append((rel, idx, text.strip()))

    print("Wave 26 §B.7 — Atomic write discipline")
    print("=" * 72)
    if not violations:
        output.success("No raw write_text/write_bytes/json.dump call sites in CLI tree.")
        return 0
    for rel, line_no, snippet in violations[:25]:
        print(f"  ❌ {rel}:{line_no}  {snippet}")
    if len(violations) > 25:
        print(f"  ... +{len(violations) - 25} more violation(s)")
    output.error(
        f"{len(violations)} raw artifact-write call site(s); migrate to sdd.io.atomic_write_*"
    )
    return 1
