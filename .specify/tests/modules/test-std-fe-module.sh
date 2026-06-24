#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <sandbox-enterprise-sdd-path>" >&2
  exit 2
fi

SANDBOX_ROOT="$1"
cd "$SANDBOX_ROOT"

./.specify/scripts/module-install.sh std-fe

required_files=(
  ".github/instructions/fe/architecture.instructions.md"
  ".github/instructions/fe/e2e-testing.instructions.md"
  ".github/instructions/fe/general-coding.instructions.md"
  ".github/instructions/fe/stratos.instructions.md"
  ".github/instructions/fe/stratos-ui-agent.instructions.md"
  ".specify/templates/setup/copilot-test-instructions.setup.md"
)

for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || { echo "missing installed file: $f" >&2; exit 1; }
done

grep -q 'BEGIN MODULE: std-fe' .github/copilot-instructions.md || {
  echo "missing std-fe copilot block" >&2
  exit 1
}

./.specify/scripts/module-remove.sh std-fe

for f in "${required_files[@]}"; do
  [[ ! -f "$f" ]] || { echo "file not removed: $f" >&2; exit 1; }
done

if [[ -f .github/copilot-instructions.md ]]; then
  ! grep -q 'BEGIN MODULE: std-fe' .github/copilot-instructions.md || {
    echo "std-fe copilot block still present" >&2
    exit 1
  }
fi

echo "PASS std-fe module install/remove"
