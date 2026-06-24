"""Terminal output helpers with optional ANSI colour support."""

from __future__ import annotations

import os
import sys


def _supports_colour() -> bool:
    """Return True if the current terminal likely supports ANSI escape codes."""
    if not hasattr(sys.stdout, "isatty") or not sys.stdout.isatty():
        return False
    term = os.environ.get("TERM", "")
    if term == "dumb":
        return False
    return True


_USE_COLOUR: bool = _supports_colour()


def _maybe(code: str, text: str) -> str:
    if _USE_COLOUR:
        return f"\033[{code}m{text}\033[0m"
    return text


def disable_colour() -> None:
    """Globally disable ANSI colour output."""
    global _USE_COLOUR
    _USE_COLOUR = False


def green(text: str) -> str:
    return _maybe("32", text)


def red(text: str) -> str:
    return _maybe("31", text)


def yellow(text: str) -> str:
    return _maybe("33", text)


def cyan(text: str) -> str:
    return _maybe("36", text)


def bold(text: str) -> str:
    return _maybe("1", text)


def success(msg: str) -> None:
    print(f"{green('✓')} {msg}")


def error(msg: str) -> None:
    print(f"{red('✗')} {msg}", file=sys.stderr)


def warn(msg: str) -> None:
    print(f"{yellow('!')} {msg}", file=sys.stderr)


def info(msg: str) -> None:
    print(f"{cyan('→')} {msg}")
