"""Skill behavioral evaluation harness — reads `.sdd-eval.yaml` manifests
alongside curated SDD skills, applies declarative assertions against fixture
transcripts (or live model output, when an adapter is wired), and renders a
structured `SKILL-EVAL-REPORT.md` under `.specify/reports/`.

Wave 20 §20 — Phase B (B.2, B.3).

The runner is intentionally adapter-agnostic: when a fixture supplies a
`transcript:` path, the assertions run against that file (offline mode); when
absent, the fixture is reported as SKIP rather than failed, so adopters can add
fixtures incrementally without breaking the gate.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

import yaml


SUPPORTED_ASSERTIONS = {
    "contains_section",
    "contains_field",
    "contains_text",
    "forbids_text",
    "min_lines",
    "matches_regex",
}


@dataclass
class AssertionResult:
    type: str
    value: object
    passed: bool
    rationale: str = ""
    detail: str = ""


@dataclass
class FixtureResult:
    name: str
    description: str
    status: str  # "PASS" | "FAIL" | "SKIP"
    assertions: list[AssertionResult] = field(default_factory=list)
    skip_reason: str = ""


@dataclass
class SkillEvalResult:
    skill: str
    description: str
    pass_threshold: float
    fixtures: list[FixtureResult] = field(default_factory=list)

    @property
    def pass_rate(self) -> float:
        executed = [f for f in self.fixtures if f.status != "SKIP"]
        if not executed:
            return 1.0
        passed = sum(1 for f in executed if f.status == "PASS")
        return passed / len(executed)

    @property
    def threshold_met(self) -> bool:
        return self.pass_rate >= self.pass_threshold


def find_eval_manifest(skill_id: str, repo_root: Path) -> Path | None:
    """Locate `.sdd-eval.yaml` under `.github/skills/<skill>/` or
    `.specify/skills/<skill>/`. Returns None when absent (skip, do not fail)."""
    for base in (repo_root / ".github" / "skills", repo_root / ".specify" / "skills"):
        candidate = base / skill_id / ".sdd-eval.yaml"
        if candidate.is_file():
            return candidate
    return None


def _apply_assertion(content: str, spec: dict[str, object]) -> AssertionResult:
    atype = str(spec.get("type", ""))
    value = spec.get("value")
    rationale = str(spec.get("rationale", ""))
    if atype not in SUPPORTED_ASSERTIONS:
        return AssertionResult(
            type=atype, value=value, passed=False, rationale=rationale,
            detail=f"unsupported assertion type: {atype}",
        )
    if atype == "contains_section":
        needle = str(value).strip()
        passed = bool(re.search(rf"(?m)^#{{1,6}}\s+.*\b{re.escape(needle)}\b", content))
        return AssertionResult(atype, value, passed, rationale,
                               "" if passed else f"section heading containing '{needle}' not found")
    if atype == "contains_field":
        needle = str(value).strip()
        passed = bool(re.search(rf"\*\*{re.escape(needle)}:\*\*", content))
        return AssertionResult(atype, value, passed, rationale,
                               "" if passed else f"field '**{needle}:**' not found")
    if atype == "contains_text":
        needle = str(value)
        passed = needle in content
        return AssertionResult(atype, value, passed, rationale,
                               "" if passed else f"substring not found")
    if atype == "forbids_text":
        needle = str(value)
        passed = needle.lower() not in content.lower()
        return AssertionResult(atype, value, passed, rationale,
                               "" if passed else f"forbidden substring '{needle}' present")
    if atype == "min_lines":
        try:
            threshold = int(value)  # type: ignore[arg-type]
        except (TypeError, ValueError):
            return AssertionResult(atype, value, False, rationale,
                                   detail=f"min_lines value must be an integer, got {value!r}")
        actual = len(content.splitlines())
        passed = actual >= threshold
        return AssertionResult(atype, value, passed, rationale,
                               "" if passed else f"line count {actual} < {threshold}")
    # matches_regex
    pattern = str(value)
    try:
        passed = bool(re.search(pattern, content))
    except re.error as exc:
        return AssertionResult(atype, value, False, rationale,
                               detail=f"invalid regex: {exc}")
    return AssertionResult(atype, value, passed, rationale,
                           "" if passed else f"regex '{pattern}' did not match")


def _resolve_fixture_input(fixture: dict[str, object], manifest_path: Path) -> tuple[str | None, str]:
    """Return (content, skip_reason). content is None when fixture should be skipped."""
    transcript = fixture.get("transcript")
    if transcript:
        path = (manifest_path.parent / str(transcript)).resolve()
        if not path.is_file():
            return None, f"transcript not found: {path}"
        return path.read_text(encoding="utf-8"), ""
    # No transcript and no live adapter wired — skip rather than fail
    return None, "no transcript supplied and no live adapter is configured"


def run_eval(skill_id: str, repo_root: Path) -> SkillEvalResult | None:
    """Run evaluation manifest for one skill. Returns None when no manifest exists
    (caller should treat as SKIP, not FAIL)."""
    manifest_path = find_eval_manifest(skill_id, repo_root)
    if manifest_path is None:
        return None
    raw = yaml.safe_load(manifest_path.read_text(encoding="utf-8")) or {}
    if not isinstance(raw, dict):
        raise ValueError(f"{manifest_path}: top-level YAML document must be a mapping")
    declared_skill = str(raw.get("skill", ""))
    if declared_skill != skill_id:
        raise ValueError(
            f"{manifest_path}: 'skill' field is '{declared_skill}', expected '{skill_id}'"
        )
    description = str(raw.get("description", ""))
    pass_threshold = float(raw.get("pass_threshold", 1.0))
    fixtures_raw = raw.get("fixtures") or []
    if not isinstance(fixtures_raw, list):
        raise ValueError(f"{manifest_path}: 'fixtures' must be a list")
    result = SkillEvalResult(skill=skill_id, description=description, pass_threshold=pass_threshold)
    for fix in fixtures_raw:
        if not isinstance(fix, dict):
            continue
        name = str(fix.get("name", "<unnamed>"))
        fdesc = str(fix.get("description", ""))
        content, skip_reason = _resolve_fixture_input(fix, manifest_path)
        if content is None:
            result.fixtures.append(FixtureResult(name=name, description=fdesc,
                                                  status="SKIP", skip_reason=skip_reason))
            continue
        assertions_raw = fix.get("assertions") or []
        assertion_results: list[AssertionResult] = []
        for a in assertions_raw:
            if isinstance(a, dict):
                assertion_results.append(_apply_assertion(content, a))
        all_passed = all(ar.passed for ar in assertion_results) and bool(assertion_results)
        status = "PASS" if all_passed else "FAIL"
        result.fixtures.append(FixtureResult(name=name, description=fdesc,
                                              status=status, assertions=assertion_results))
    return result


def render_report(results: Iterable[SkillEvalResult]) -> str:
    """Render a structured Markdown report for one or more skill evaluations."""
    lines: list[str] = []
    lines.append("# Skill Evaluation Report")
    lines.append("")
    lines.append(f"Generated: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')}")
    lines.append("")
    overall_pass = True
    for r in results:
        lines.append(f"## Skill: `{r.skill}`")
        if r.description:
            lines.append(f"_{r.description}_")
        lines.append("")
        lines.append("| Fixture | Status | Assertions | Notes |")
        lines.append("|---------|:------:|:----------:|-------|")
        for f in r.fixtures:
            assertion_summary = "—"
            note = ""
            if f.status == "SKIP":
                note = f.skip_reason
            else:
                passed = sum(1 for a in f.assertions if a.passed)
                total = len(f.assertions)
                assertion_summary = f"{passed}/{total}"
                failures = [a for a in f.assertions if not a.passed]
                if failures:
                    note = "; ".join(
                        f"{a.type}({a.value!s}): {a.detail}".strip()
                        for a in failures
                    )
            lines.append(f"| `{f.name}` | {f.status} | {assertion_summary} | {note} |")
        lines.append("")
        lines.append(
            f"**Pass-rate:** {r.pass_rate:.0%} · **Threshold:** {r.pass_threshold:.0%} · "
            f"**Threshold met:** {'yes' if r.threshold_met else 'no'}"
        )
        lines.append("")
        if not r.threshold_met:
            overall_pass = False
    lines.append("---")
    lines.append("")
    lines.append(f"**Overall verdict:** {'PASS' if overall_pass else 'FAIL'}")
    lines.append("")
    return "\n".join(lines)


def write_report(results: list[SkillEvalResult], repo_root: Path) -> Path:
    reports_dir = repo_root / ".specify" / "reports"
    reports_dir.mkdir(parents=True, exist_ok=True)
    out = reports_dir / "SKILL-EVAL-REPORT.md"
    from sdd.io import atomic_write_text
    atomic_write_text(out, render_report(results))
    return out
