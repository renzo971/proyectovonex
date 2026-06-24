"""Tokenizer abstraction (Wave 23 §23.A.23).

Prefer `tiktoken` for OpenAI-compatible models; fall back to a `chars / 4`
heuristic for unsupported models or environments without `tiktoken`.

Also provides default model context windows used by `sdd bridge --context-check`.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Optional

# Default model context windows (tokens). Conservative defaults — refine as needed.
DEFAULT_MODEL = "gpt-4o-mini"
MODEL_WINDOWS: dict[str, int] = {
    "gpt-4o": 128_000,
    "gpt-4o-mini": 128_000,
    "gpt-4-turbo": 128_000,
    "gpt-4": 8_192,
    "gpt-3.5-turbo": 16_385,
    "claude-3-5-sonnet": 200_000,
    "claude-3-opus": 200_000,
    "claude-sonnet-4-5": 200_000,
}

WARN_THRESHOLD = 0.60
CRITICAL_THRESHOLD = 0.70


@dataclass
class TokenCount:
    tokens: int
    method: str  # "tiktoken" or "heuristic"


def count_tokens(text: str, model: str = DEFAULT_MODEL) -> TokenCount:
    """Return the estimated token count for `text` under `model`.

    Falls back to `len(text) // 4` when tiktoken is not available or the
    model is not OpenAI-compatible.
    """
    try:
        import tiktoken  # type: ignore

        try:
            enc = tiktoken.encoding_for_model(model)
        except Exception:
            enc = tiktoken.get_encoding("cl100k_base")
        return TokenCount(tokens=len(enc.encode(text)), method="tiktoken")
    except Exception:
        return TokenCount(tokens=max(1, len(text) // 4), method="heuristic")


def model_window(model: str = DEFAULT_MODEL) -> int:
    return MODEL_WINDOWS.get(model, 128_000)


def utilisation_status(used: int, window: int) -> tuple[str, float]:
    """Return (status, ratio). Status ∈ {OK, WARN, CRITICAL}."""
    ratio = used / max(window, 1)
    if ratio >= CRITICAL_THRESHOLD:
        return "CRITICAL", ratio
    if ratio >= WARN_THRESHOLD:
        return "WARN", ratio
    return "OK", ratio


def session_discipline_recommendation() -> str:
    """Wave 23 §23.A.25 — surface §21 session discipline action at CRITICAL."""
    return (
        "RECOMMENDATION (Wave 21 §21 session discipline):\n"
        "  1. Compact the current context (drop verbose tool outputs, large file reads).\n"
        "  2. Carry forward only the minimum: active task, last gate decision, open questions.\n"
        "  3. Start a fresh session for the next phase; load only `sdd resume <feature-id>` output."
    )
