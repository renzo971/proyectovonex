"""Wave 26 §25 #2/#3 — SDD I/O helpers (atomic writes + JSON envelope).

Submodules:
- `sdd.io.atomic` — `atomic_write_text`, `atomic_write_json`, `atomic_write_yaml`
- `sdd.io.json_envelope` — `emit_envelope`, `route_logs_to_stderr`
"""

from sdd.io.atomic import (  # noqa: F401
    atomic_write_text,
    atomic_write_json,
    atomic_write_yaml,
)
from sdd.io.json_envelope import (  # noqa: F401
    emit_envelope,
    route_logs_to_stderr,
)
from sdd.io.cli_helpers import (  # noqa: F401
    add_json_flags,
    wrap_envelope,
)
