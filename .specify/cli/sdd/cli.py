"""Main CLI entry point for the `sdd` command."""

from __future__ import annotations

import argparse
import sys

from sdd.commands.init import add_init_parser, run_init
from sdd.commands.new import add_new_parser, run_new
from sdd.commands.gate import add_gate_parser, run_gate
from sdd.commands.status import add_status_parser, run_status
from sdd.commands.analyze import add_analyze_parser, run_analyze
from sdd.commands.trace import add_trace_parser, run_trace
from sdd.commands.report import add_report_parser, run_report
from sdd.commands.resume import add_resume_parser, run_resume
from sdd.commands.bridge import add_bridge_parser, run_bridge
from sdd.commands.module import add_module_parser, run_module
from sdd.commands.adapters import add_adapters_parser, run_adapters
from sdd.commands.preset import add_preset_parser, run_preset
from sdd.commands.sync import add_sync_parser, run_sync
from sdd.commands.spell import add_spell_parser, run_spell
from sdd.commands.route import add_route_parser, run_route
from sdd.commands.ship import add_ship_parser, run_ship
from sdd.commands.extension import add_extension_parser, run_extension
from sdd.commands.memory import add_memory_parser, run_memory
from sdd.commands.skill import add_skill_parser, run_skill
from sdd.commands.autonomy import add_autonomy_parser, run_autonomy
from sdd.commands.context import add_context_parser, run_context
from sdd.commands.retrospect import add_retrospect_parser, run_retrospect
from sdd.commands.spike import add_spike_parser, run_spike
from sdd.commands.ingest import add_ingest_parser, run_ingest
from sdd.commands.doctor import add_doctor_parser, run_doctor
from sdd.commands.accept_drift import add_accept_drift_parser, run_accept_drift
from sdd.commands.diff_drift import add_diff_drift_parser, run_diff_drift
from sdd.commands.schema import add_schema_parser, run_schema


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="sdd",
        description="Enterprise SDD workflow CLI — manage specs, gates, and AI agents",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--version",
        action="version",
        version="%(prog)s 0.1.0",
    )
    parser.add_argument(
        "--no-color",
        action="store_true",
        default=False,
        help="disable ANSI colour output",
    )

    subparsers = parser.add_subparsers(dest="command", metavar="<command>")
    subparsers.required = True

    add_init_parser(subparsers)
    add_new_parser(subparsers)
    add_gate_parser(subparsers)
    add_status_parser(subparsers)
    add_analyze_parser(subparsers)
    add_trace_parser(subparsers)
    add_report_parser(subparsers)
    add_resume_parser(subparsers)
    add_bridge_parser(subparsers)
    add_module_parser(subparsers)
    add_adapters_parser(subparsers)
    add_preset_parser(subparsers)
    add_sync_parser(subparsers)
    add_spell_parser(subparsers)
    add_route_parser(subparsers)
    add_ship_parser(subparsers)
    add_extension_parser(subparsers)
    add_memory_parser(subparsers)
    add_skill_parser(subparsers)
    add_autonomy_parser(subparsers)
    add_context_parser(subparsers)
    add_retrospect_parser(subparsers)
    add_spike_parser(subparsers)
    add_ingest_parser(subparsers)
    add_doctor_parser(subparsers)
    add_accept_drift_parser(subparsers)
    add_diff_drift_parser(subparsers)
    add_schema_parser(subparsers)

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    dispatch = {
        "init": run_init,
        "new": run_new,
        "gate": run_gate,
        "status": run_status,
        "analyze": run_analyze,
        "trace": run_trace,
        "report": run_report,
        "resume": run_resume,
        "bridge": run_bridge,
        "module": run_module,
        "adapters": run_adapters,
        "preset": run_preset,
        "sync": run_sync,
        "spell": run_spell,
        "route": run_route,
        "ship": run_ship,
        "extension": run_extension,
        "memory": run_memory,
        "skill": run_skill,
        "autonomy": run_autonomy,
        "context": run_context,
        "retrospect": run_retrospect,
        "spike": run_spike,
        "ingest": run_ingest,
        "doctor": run_doctor,
        "accept-drift": run_accept_drift,
        "diff-drift": run_diff_drift,
        "schema": run_schema,
    }

    handler = dispatch.get(args.command)
    if handler is None:
        parser.print_help()
        sys.exit(2)

    sys.exit(handler(args))


if __name__ == "__main__":
    main()
