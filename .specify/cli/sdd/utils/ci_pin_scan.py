"""CI action SHA-pin scanner (Wave 23 §23.B.10–§23.B.12).

Scans `.github/workflows/*.yml`, `.github/workflows/*.yml.example`, and
`.specify/templates/workflows/*.yml` for `uses:` references and reports any
that are not pinned to a 40-character commit SHA.

A SHA-pinned `uses:` matches the regex ``^[^@]+@[a-f0-9]{40}$``.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path


_USES_RE = re.compile(r"^\s*-?\s*uses:\s*([^\s#]+)", re.MULTILINE)
_SHA_RE = re.compile(r"^[^@]+@[a-f0-9]{40}$")

_WORKFLOW_GLOBS = (
    (".github/workflows", ("*.yml", "*.yaml", "*.yml.example")),
    (".specify/templates/workflows", ("*.yml", "*.yaml")),
)


@dataclass
class UnpinnedAction:
    path: str
    line_no: int
    reference: str


def _iter_workflow_files(repo_root: Path):
    for sub, patterns in _WORKFLOW_GLOBS:
        d = repo_root / sub
        if not d.exists():
            continue
        for pat in patterns:
            for f in d.rglob(pat):
                if f.is_file():
                    yield f


def scan(repo_root: Path) -> list[UnpinnedAction]:
    """Return every unpinned `uses:` reference across workflow files."""
    findings: list[UnpinnedAction] = []
    for path in _iter_workflow_files(repo_root):
        try:
            text = path.read_text(encoding="utf-8")
        except OSError:
            continue
        for line_no, line in enumerate(text.splitlines(), start=1):
            m = _USES_RE.match(line)
            if not m:
                continue
            ref = m.group(1).strip()
            if not _SHA_RE.match(ref):
                rel = path.relative_to(repo_root) if path.is_absolute() else path
                findings.append(UnpinnedAction(
                    path=str(rel),
                    line_no=line_no,
                    reference=ref,
                ))
    return findings
