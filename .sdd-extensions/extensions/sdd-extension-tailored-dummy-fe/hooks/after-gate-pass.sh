#!/usr/bin/env bash
set -euo pipefail
echo "after-gate-pass:$1" >> "$(dirname "$0")/../hook.log"
