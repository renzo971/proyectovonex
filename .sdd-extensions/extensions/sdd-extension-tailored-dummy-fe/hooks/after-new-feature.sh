#!/usr/bin/env bash
set -euo pipefail
echo "after-new-feature:$1" >> "$(dirname "$0")/../hook.log"
