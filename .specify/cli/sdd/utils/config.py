"""Configuration helpers — locate repo root and scripts directory."""

from __future__ import annotations

import os
import sys
from pathlib import Path

IS_WINDOWS = sys.platform == "win32"


def find_repo_root(start: Path | None = None) -> Path:
    """Walk up the directory tree to find the repo root that contains `.specify/`."""
    current = (start or Path.cwd()).resolve()
    for directory in [current, *current.parents]:
        if (directory / ".specify").is_dir():
            return directory
    raise FileNotFoundError(
        "Could not locate .specify/ directory. "
        "Run this command from inside an Enterprise SDD repository."
    )


def scripts_dir(repo_root: Path | None = None) -> Path:
    """Return the path to `.specify/scripts/`."""
    root = repo_root or find_repo_root()
    return root / ".specify" / "scripts"


def spec_dir(repo_root: Path | None = None) -> Path:
    """Return the path to `.specify/specs/`."""
    root = repo_root or find_repo_root()
    return root / ".specify" / "specs"


def adapters_dir(repo_root: Path | None = None) -> Path:
    """Return the path to `.specify/adapters/`."""
    root = repo_root or find_repo_root()
    return root / ".specify" / "adapters"


def get_env(repo_root: Path | None = None) -> dict[str, str]:
    """Return an environment dict suitable for subprocess calls."""
    root = repo_root or find_repo_root()
    env = os.environ.copy()
    env["SDD_ROOT"] = str(root)
    return env


def script_command(stem: str, repo_root: Path | None = None) -> list[str]:
    """Return the platform-appropriate command list to invoke a script by stem name.

    On Windows: ``["powershell", "-ExecutionPolicy", "Bypass", "-File", "<path>.ps1"]``
    On Unix:    ``["bash", "<path>.sh"]``
    """
    root = repo_root or find_repo_root()
    sd = scripts_dir(root)
    if IS_WINDOWS:
        script = sd / f"{stem}.ps1"
        if not script.exists():
            raise FileNotFoundError(f"PowerShell script not found: {script}")
        return ["powershell", "-ExecutionPolicy", "Bypass", "-File", str(script)]
    else:
        script = sd / f"{stem}.sh"
        if not script.exists():
            raise FileNotFoundError(f"Bash script not found: {script}")
        return ["bash", str(script)]


def venv_bin_dir(venv_dir: Path) -> Path:
    """Return the platform-appropriate bin directory inside a venv."""
    return venv_dir / "Scripts" if IS_WINDOWS else venv_dir / "bin"


def ps_arg(bash_arg: str) -> str:
    """Translate a ``--bash-style`` flag to ``-PowerShellStyle`` on Windows.

    On Unix (or if the argument doesn't start with ``--``) returns unchanged.
    """
    if not IS_WINDOWS or not bash_arg.startswith("--"):
        return bash_arg
    name = bash_arg[2:]  # strip leading --
    return "-" + "".join(part.capitalize() for part in name.split("-"))
