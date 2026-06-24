"""Basic CLI smoke tests."""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

# The CLI package root — tests invoke via `python -m sdd` from this directory
CLI_PACKAGE_DIR = str(Path(__file__).parent.parent)


def _run(*args: str) -> subprocess.CompletedProcess:
    """Run the sdd CLI via `python -m sdd` from the package root."""
    return subprocess.run(
        [sys.executable, "-m", "sdd", *args],
        capture_output=True,
        text=True,
        cwd=CLI_PACKAGE_DIR,
    )


class TestCLIHelp(unittest.TestCase):
    def test_help_exits_zero(self) -> None:
        result = _run("--help")
        self.assertEqual(result.returncode, 0)
        self.assertIn("sdd", result.stdout)

    def test_version(self) -> None:
        result = _run("--version")
        self.assertEqual(result.returncode, 0)
        self.assertIn("0.1.0", result.stdout)

    def test_subcommand_help(self) -> None:
        for cmd in ("init", "new", "gate", "status", "analyze", "report",
                    "resume", "bridge", "module", "adapters", "preset", "sync", "spell", "route", "ship", "extension", "memory", "skill"):
            with self.subTest(cmd=cmd):
                result = _run(cmd, "--help")
                self.assertEqual(result.returncode, 0, msg=result.stderr)

    def test_unknown_command_exits_nonzero(self) -> None:
        result = _run("nonexistent-command")
        self.assertNotEqual(result.returncode, 0)


class TestFindRepoRoot(unittest.TestCase):
    def test_finds_root_when_specify_present(self) -> None:
        from sdd.utils.config import find_repo_root

        # enterprise-sdd contains .specify/
        root = find_repo_root(
            Path(__file__).parent.parent.parent.parent
        )
        self.assertTrue((root / ".specify").is_dir())

    def test_raises_when_not_found(self) -> None:
        from sdd.utils.config import find_repo_root
        import tempfile
        import os

        with self.assertRaises(FileNotFoundError):
            find_repo_root(Path("/"))


class TestOutputModule(unittest.TestCase):
    def test_disable_colour(self) -> None:
        from sdd.utils import output
        output.disable_colour()
        self.assertEqual(output.green("hi"), "hi")
        self.assertEqual(output.red("hi"), "hi")


class TestPresetList(unittest.TestCase):
    def test_preset_list(self) -> None:
        result = _run("preset", "list")
        self.assertEqual(result.returncode, 0)
        self.assertIn("minimal", result.stdout)
        self.assertIn("enterprise", result.stdout)


class TestSkillCommands(unittest.TestCase):
    def test_skill_list(self) -> None:
        result = _run("skill", "list")
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("memory-loop", result.stdout)

    def test_skill_validate(self) -> None:
        result = _run("skill", "validate", "memory-loop")
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("Skill validation passed", result.stdout)

    def test_skill_run_dry_run(self) -> None:
        result = _run("skill", "run", "sdd-auto-implement", "001-example-feature", "--dry-run")
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("DRY-RUN", result.stdout)

    def test_skill_validate_mapping(self) -> None:
        result = _run("skill", "validate-mapping")
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("Command taxonomy mapping validation passed", result.stdout)


if __name__ == "__main__":
    unittest.main()
