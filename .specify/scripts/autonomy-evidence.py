#!/usr/bin/env python3
"""Sync and summarize autonomy cycle evidence for Enterprise SDD.

This script implements Wave 13 / Phase N features:
- N.1 per-attempt evidence pack under .specify/checkpoints/autonomy-runs/
- N.2 structured verdict schema (passed/retry/blocked + confidence + repair_hint)
- N.3 derived autonomy-progress.md ledger
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path


STATUS_VALUES = {"passed", "retry", "blocked"}


@dataclass
class CycleEvidence:
    cycle: int
    text: str
    status: str
    confidence: float
    repair_hint: str
    summary: str
    blocker: str


@dataclass
class Summary:
    feature_id: str
    current_cycle: int
    latest_status: str
    confidence: float
    repair_hint: str
    blocker: str
    next_action: str
    cycle_count: int


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def parse_cycles(todo_text: str) -> list[tuple[int, str]]:
    pattern = re.compile(r"^##\s+Cycle\s+(\d+)\s*$", re.MULTILINE)
    matches = list(pattern.finditer(todo_text))
    cycles: list[tuple[int, str]] = []
    for idx, match in enumerate(matches):
        cycle_n = int(match.group(1))
        start = match.start()
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(todo_text)
        cycles.append((cycle_n, todo_text[start:end].strip()))
    return cycles


def clamp_confidence(raw: float) -> float:
    if raw < 0:
        return 0.0
    if raw <= 1.0:
        return round(raw, 2)
    if raw <= 5.0:
        return round(raw / 5.0, 2)
    if raw <= 100.0:
        return round(raw / 100.0, 2)
    return 1.0


def parse_confidence(text: str) -> float:
    # Match patterns like: confidence 4/5, confidence score: 0.8, confidence: 80%
    ratio = re.search(r"confidence[^\n\r]*?(\d+(?:\.\d+)?)\s*/\s*(\d+(?:\.\d+)?)", text, re.IGNORECASE)
    if ratio:
        num = float(ratio.group(1))
        den = float(ratio.group(2))
        if den > 0:
            return clamp_confidence(num / den)

    percent = re.search(r"confidence[^\n\r]*?(\d+(?:\.\d+)?)\s*%", text, re.IGNORECASE)
    if percent:
        return clamp_confidence(float(percent.group(1)) / 100.0)

    number = re.search(r"confidence(?:\s+score)?\s*[:=]\s*(\d+(?:\.\d+)?)", text, re.IGNORECASE)
    if number:
        return clamp_confidence(float(number.group(1)))

    return 0.0


def parse_repair_hint(text: str) -> str:
    m = re.search(r"repair[_\-\s]?hint\s*[:=]\s*(.+)$", text, re.IGNORECASE | re.MULTILINE)
    if m:
        return m.group(1).strip()
    m = re.search(r"next\s+fix\s*[:=]\s*(.+)$", text, re.IGNORECASE | re.MULTILINE)
    if m:
        return m.group(1).strip()
    return ""


def parse_status(text: str) -> str:
    if re.search(r"\bverdict\s*:\s*pass\b", text, re.IGNORECASE):
        return "passed"
    if re.search(r"\bverdict\s*:\s*pass\s+with\s+warnings\b", text, re.IGNORECASE):
        return "retry"
    if re.search(r"\b(verdict\s*:\s*fail|blocked|escalat(e|ion))\b", text, re.IGNORECASE):
        return "blocked"
    if re.search(r"\bretry\b", text, re.IGNORECASE):
        return "retry"
    return "retry"


def first_nonempty_line(text: str) -> str:
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        if line.lower().startswith("## cycle"):
            continue
        return line
    return "No summary available"


def parse_blocker(text: str, status: str) -> str:
    m = re.search(r"blocker\s*[:=]\s*(.+)$", text, re.IGNORECASE | re.MULTILINE)
    if m:
        return m.group(1).strip()
    if status == "blocked":
        return "Autonomous cycle blocked by verifier/provenance constraints."
    return "none"


def parse_cycle_evidence(cycle: int, text: str) -> CycleEvidence:
    status = parse_status(text)
    confidence = parse_confidence(text)
    repair_hint = parse_repair_hint(text)
    summary = first_nonempty_line(text)
    blocker = parse_blocker(text, status)
    return CycleEvidence(
        cycle=cycle,
        text=text,
        status=status,
        confidence=confidence,
        repair_hint=repair_hint,
        summary=summary,
        blocker=blocker,
    )


def next_action_for_status(status: str) -> str:
    if status == "passed":
        return "Proceed to the next autonomous cycle."
    if status == "retry":
        return "Retry current cycle using repair_hint and updated evidence."
    return "Escalate to human review or fallbackExecutionMode."


def load_prompt_template(repo_root: Path) -> str:
    prompt_path = repo_root / ".github" / "prompts" / "autonomous-implement.prompt.md"
    if prompt_path.exists():
        return prompt_path.read_text(encoding="utf-8")
    return "Autonomous implement prompt template not found."


def ensure_cycle_artifacts(
    repo_root: Path,
    feature_id: str,
    feature_dir: Path,
    evidence: CycleEvidence,
    prompt_template: str,
) -> Path:
    cycle_dir = repo_root / ".specify" / "checkpoints" / "autonomy-runs" / feature_id / f"cycle-{evidence.cycle:03d}"
    cycle_dir.mkdir(parents=True, exist_ok=True)

    prompt_file = cycle_dir / "prompt.md"
    result_file = cycle_dir / "result.md"
    verdict_file = cycle_dir / "verdict.json"

    prompt_file.write_text(
        "\n".join(
            [
                f"# Autonomous Cycle Prompt Snapshot — {feature_id} cycle {evidence.cycle}",
                "",
                "## Prompt Template Source",
                str((repo_root / ".github" / "prompts" / "autonomous-implement.prompt.md").relative_to(repo_root)),
                "",
                "## Prompt Body",
                prompt_template,
                "",
            ]
        ),
        encoding="utf-8",
    )

    result_file.write_text(
        "\n".join(
            [
                f"# Autonomous Cycle Result Snapshot — {feature_id} cycle {evidence.cycle}",
                "",
                "## Source",
                str((feature_dir / "todo.md").relative_to(repo_root)) if (feature_dir / "todo.md").exists() else "todo.md not found",
                "",
                "## Captured Block",
                evidence.text,
                "",
            ]
        ),
        encoding="utf-8",
    )

    verdict_payload = {
        "schemaVersion": "1.0",
        "featureId": feature_id,
        "cycle": evidence.cycle,
        "status": evidence.status,
        "confidence": evidence.confidence,
        "repair_hint": evidence.repair_hint,
        "summary": evidence.summary,
        "blocker": evidence.blocker,
        "next_action": next_action_for_status(evidence.status),
        "source": f"{feature_id}/todo.md#cycle-{evidence.cycle}",
        "updatedAt": utc_now_iso(),
    }
    verdict_file.write_text(json.dumps(verdict_payload, indent=2), encoding="utf-8")

    return cycle_dir


def load_existing_verdicts(repo_root: Path, feature_id: str) -> list[CycleEvidence]:
    base = repo_root / ".specify" / "checkpoints" / "autonomy-runs" / feature_id
    if not base.exists():
        return []

    items: list[CycleEvidence] = []
    for verdict in sorted(base.glob("cycle-*/verdict.json")):
        data = json.loads(verdict.read_text(encoding="utf-8"))
        status = str(data.get("status", "retry")).strip().lower()
        if status not in STATUS_VALUES:
            status = "retry"
        items.append(
            CycleEvidence(
                cycle=int(data.get("cycle", 0) or 0),
                text="",
                status=status,
                confidence=clamp_confidence(float(data.get("confidence", 0.0) or 0.0)),
                repair_hint=str(data.get("repair_hint", "") or "").strip(),
                summary=str(data.get("summary", "No summary available") or "No summary available"),
                blocker=str(data.get("blocker", "none") or "none"),
            )
        )
    items.sort(key=lambda x: x.cycle)
    return items


def write_progress_ledger(feature_dir: Path, summary: Summary, evidence_items: list[CycleEvidence]) -> Path:
    ledger = feature_dir / "autonomy-progress.md"
    lines = [
        "# Autonomy Progress Ledger",
        "",
        f"- Feature: {summary.feature_id}",
        f"- Generated: {utc_now_iso()}",
        "",
        "## Current State",
        "",
        f"- Current cycle: {summary.current_cycle}",
        f"- Latest verdict: {summary.latest_status}",
        f"- Confidence: {summary.confidence:.2f}",
        f"- Blocker: {summary.blocker}",
        f"- Next action: {summary.next_action}",
        "",
        "## Cycle Index",
        "",
        "| Cycle | Status | Confidence | Repair Hint |",
        "|---:|---|---:|---|",
    ]
    for item in evidence_items:
        hint = item.repair_hint.replace("|", "\\|") if item.repair_hint else "-"
        lines.append(f"| {item.cycle} | {item.status} | {item.confidence:.2f} | {hint} |")

    ledger.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return ledger


def compute_summary(feature_id: str, evidence_items: list[CycleEvidence]) -> Summary:
    if not evidence_items:
        return Summary(
            feature_id=feature_id,
            current_cycle=0,
            latest_status="retry",
            confidence=0.0,
            repair_hint="",
            blocker="none",
            next_action="Start first autonomous cycle and record evidence.",
            cycle_count=0,
        )

    latest = evidence_items[-1]
    return Summary(
        feature_id=feature_id,
        current_cycle=latest.cycle,
        latest_status=latest.status,
        confidence=latest.confidence,
        repair_hint=latest.repair_hint,
        blocker=latest.blocker,
        next_action=next_action_for_status(latest.status),
        cycle_count=len(evidence_items),
    )


def validate_feature(repo_root: Path, feature_id: str) -> Path:
    feature_dir = repo_root / ".specify" / "specs" / feature_id
    if not feature_dir.exists():
        raise FileNotFoundError(f"Feature not found: {feature_id}")
    return feature_dir


def sync(repo_root: Path, feature_id: str) -> Summary:
    feature_dir = validate_feature(repo_root, feature_id)
    todo = feature_dir / "todo.md"

    prompt_template = load_prompt_template(repo_root)

    if todo.exists():
        todo_text = todo.read_text(encoding="utf-8")
        cycles = parse_cycles(todo_text)
        for cycle_num, cycle_text in cycles:
            evidence = parse_cycle_evidence(cycle_num, cycle_text)
            ensure_cycle_artifacts(repo_root, feature_id, feature_dir, evidence, prompt_template)

    evidence_items = load_existing_verdicts(repo_root, feature_id)
    summary = compute_summary(feature_id, evidence_items)
    write_progress_ledger(feature_dir, summary, evidence_items)
    return summary


def summary_payload(repo_root: Path, feature_id: str) -> dict[str, object]:
    feature_dir = validate_feature(repo_root, feature_id)
    evidence_items = load_existing_verdicts(repo_root, feature_id)
    summary = compute_summary(feature_id, evidence_items)
    ledger = feature_dir / "autonomy-progress.md"
    payload = {
        "feature_id": summary.feature_id,
        "current_cycle": summary.current_cycle,
        "latest_status": summary.latest_status,
        "confidence": summary.confidence,
        "repair_hint": summary.repair_hint,
        "blocker": summary.blocker,
        "next_action": summary.next_action,
        "cycle_count": summary.cycle_count,
        "ledger_path": str(ledger),
    }
    return payload


def emit_text(payload: dict[str, object]) -> None:
    print(
        "|".join(
            [
                str(payload.get("latest_status", "retry")),
                f"{float(payload.get('confidence', 0.0) or 0.0):.2f}",
                str(payload.get("repair_hint", "")),
                str(payload.get("current_cycle", 0)),
                str(payload.get("next_action", "")),
                str(payload.get("blocker", "none")),
                str(payload.get("cycle_count", 0)),
                str(payload.get("ledger_path", "")),
            ]
        )
    )


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Sync and summarize autonomy evidence")
    p.add_argument("command", choices=["sync", "summary"])
    p.add_argument("--repo-root", required=True)
    p.add_argument("--feature-id", required=True)
    p.add_argument("--format", choices=["json", "text"], default="json")
    return p


def main() -> int:
    args = build_parser().parse_args()
    repo_root = Path(args.repo_root).resolve()
    feature_id = args.feature_id.strip()

    if args.command == "sync":
        sync(repo_root, feature_id)

    payload = summary_payload(repo_root, feature_id)
    if args.format == "json":
        print(json.dumps(payload))
    else:
        emit_text(payload)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
