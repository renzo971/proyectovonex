#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <sandbox-enterprise-sdd-path>" >&2
  exit 2
fi

SANDBOX_ROOT="$1"
cd "$SANDBOX_ROOT"

./.specify/scripts/module-install.sh aws-fe

required_files=(
  ".github/instructions/aws-fe/architecture.instructions.md"
  ".github/instructions/aws-fe/advanced-search-form.instructions.md"
  ".github/instructions/aws-fe/advanced-search-results.instructions.md"
  ".github/prompts/aws-fe/scaffolding.prompt.md"
  ".github/prompts/aws-fe/settlement/future-implementation-template.prompt.md"
  ".specify/templates/setup/project-guidelines.setup.md"
  ".specify/templates/setup/unit-tests.setup.md"
)

for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || { echo "missing installed file: $f" >&2; exit 1; }
done

grep -q 'BEGIN MODULE: aws-fe' .github/copilot-instructions.md || {
  echo "missing aws-fe copilot block" >&2
  exit 1
}

./.specify/scripts/module-remove.sh aws-fe

for f in "${required_files[@]}"; do
  [[ ! -f "$f" ]] || { echo "file not removed: $f" >&2; exit 1; }
done

if [[ -f .github/copilot-instructions.md ]]; then
  ! grep -q 'BEGIN MODULE: aws-fe' .github/copilot-instructions.md || {
    echo "aws-fe copilot block still present" >&2
    exit 1
  }
fi

echo "PASS aws-fe module install/remove"
