#!/usr/bin/env bash
#
# module-install.sh — Install an SDD user module
#
# Usage: ./module-install.sh <module-name>
#
# Reads a module from .sdd-modules/modules/<name>/, copies its files
# into the project, and registers it in registry.json.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error()   { echo -e "${RED}❌ $1${NC}"; }
log_warn()    { echo -e "${YELLOW}⚠️  $1${NC}"; }

usage() {
    cat << 'EOF'
Usage: module-install.sh <module-name>

Install an SDD user module from .sdd-modules/modules/<name>/.

Arguments:
    module-name    Name of the module directory under .sdd-modules/modules/

Example:
    ./module-install.sh core-be
EOF
    exit 1
}

# Validate arguments
if [[ $# -lt 1 || -z "$1" ]]; then
    log_error "Module name is required"
    usage
fi

MODULE_NAME="$1"
MODULE_DIR="$REPO_ROOT/.sdd-modules/modules/$MODULE_NAME"
REGISTRY="$REPO_ROOT/.sdd-modules/registry.json"

copy_module_tree() {
    local source_dir="$1"
    local target_root="$2"
    local registry_prefix="$3"

    [[ -d "$source_dir" ]] || return 0

    while IFS= read -r -d '' source_file; do
        local rel_path="${source_file#"$source_dir"/}"
        local target_file="$target_root/$rel_path"
        mkdir -p "$(dirname "$target_file")"
        cp "$source_file" "$target_file"
        INSTALLED_FILES+=("$registry_prefix/$rel_path")
    done < <(find "$source_dir" -type f -print0)
}

copy_manifest_imports() {
    local category="$1"
    local target_root="$2"
    local registry_prefix="$3"

    local import_count
    import_count=$(jq -r --arg category "$category" '(.importFrom[$category] // []) | length' "$MODULE_DIR/module.json")
    [[ "$import_count" -gt 0 ]] || return 0

    while IFS= read -r encoded_entry; do
        local entry_json
        local source_rel
        local target_subdir
        local target_name
        local source_path
        local destination_root

        entry_json=$(printf '%s' "$encoded_entry" | base64 -d)
        source_rel=$(printf '%s' "$entry_json" | jq -r '.from')
        target_subdir=$(printf '%s' "$entry_json" | jq -r '.to // ""')
        target_name=$(printf '%s' "$entry_json" | jq -r '.as // ""')
        source_path="$REPO_ROOT/$source_rel"
        destination_root="$target_root"

        if [[ -n "$target_subdir" ]]; then
            destination_root="$destination_root/$target_subdir"
        fi

        if [[ -d "$source_path" ]]; then
            while IFS= read -r -d '' source_file; do
                local rel_path="${source_file#"$source_path"/}"
                local target_file="$destination_root/$rel_path"
                local registry_path="$registry_prefix"
                mkdir -p "$(dirname "$target_file")"
                cp "$source_file" "$target_file"
                if [[ -n "$target_subdir" ]]; then
                    registry_path="$registry_path/$target_subdir"
                fi
                INSTALLED_FILES+=("$registry_path/$rel_path")
            done < <(find "$source_path" -type f -print0)
            continue
        fi

        if [[ ! -f "$source_path" ]]; then
            log_warn "Manifest source path not found: $source_rel"
            continue
        fi

        if [[ -z "$target_name" ]]; then
            target_name="$(basename "$source_path")"
        fi

        mkdir -p "$destination_root"
        cp "$source_path" "$destination_root/$target_name"

        local registry_path="$registry_prefix"
        if [[ -n "$target_subdir" ]]; then
            registry_path="$registry_path/$target_subdir"
        fi
        INSTALLED_FILES+=("$registry_path/$target_name")
    done < <(jq -rc --arg category "$category" '.importFrom[$category] // [] | map(@base64)[]' "$MODULE_DIR/module.json")
}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📦 Installing SDD Module: $MODULE_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verify module exists
if [[ ! -d "$MODULE_DIR" ]]; then
    log_error "Module '$MODULE_NAME' not found in .sdd-modules/modules/"
    exit 1
fi

# Read module.json
if [[ ! -f "$MODULE_DIR/module.json" ]]; then
    log_error "Module '$MODULE_NAME' has no module.json manifest"
    exit 1
fi

# Check if already installed
if [[ -f "$REGISTRY" ]]; then
    EXISTING=$(jq -r --arg name "$MODULE_NAME" '.installedModules[] | select(.name == $name) | .name' "$REGISTRY" 2>/dev/null || true)
    if [[ -n "$EXISTING" ]]; then
        log_error "Module '$MODULE_NAME' is already installed. Run 'sdd module remove $MODULE_NAME' first."
        exit 1
    fi
fi

# Read module version
MODULE_VERSION=$(jq -r '.version // "0.0.0"' "$MODULE_DIR/module.json")
log_info "Module version: $MODULE_VERSION"

# Track installed files for registry
INSTALLED_FILES=()

# Copy instruction files (with applyTo globs intact)
copy_module_tree "$MODULE_DIR/instructions" "$REPO_ROOT/.github/instructions" ".github/instructions"
copy_manifest_imports "instructions" "$REPO_ROOT/.github/instructions" ".github/instructions"
if [[ -d "$MODULE_DIR/instructions" ]] || [[ $(jq -r '(.importFrom.instructions // []) | length' "$MODULE_DIR/module.json") -gt 0 ]]; then
    log_success "Copied instruction files"
fi

# Copy guidance files
copy_module_tree "$MODULE_DIR/guidances" "$REPO_ROOT/.github/guidances" ".github/guidances"
copy_manifest_imports "guidances" "$REPO_ROOT/.github/guidances" ".github/guidances"
if [[ -d "$MODULE_DIR/guidances" ]] || [[ $(jq -r '(.importFrom.guidances // []) | length' "$MODULE_DIR/module.json") -gt 0 ]]; then
    log_success "Copied guidance files"
fi

# Copy prompts
copy_module_tree "$MODULE_DIR/prompts" "$REPO_ROOT/.github/prompts" ".github/prompts"
copy_manifest_imports "prompts" "$REPO_ROOT/.github/prompts" ".github/prompts"
if [[ -d "$MODULE_DIR/prompts" ]] || [[ $(jq -r '(.importFrom.prompts // []) | length' "$MODULE_DIR/module.json") -gt 0 ]]; then
    log_success "Copied prompt files"
fi

# Copy setup templates
copy_module_tree "$MODULE_DIR/setup" "$REPO_ROOT/.specify/templates/setup" ".specify/templates/setup"
copy_manifest_imports "setup" "$REPO_ROOT/.specify/templates/setup" ".specify/templates/setup"
if [[ -d "$MODULE_DIR/setup" ]] || [[ $(jq -r '(.importFrom.setup // []) | length' "$MODULE_DIR/module.json") -gt 0 ]]; then
    log_success "Copied setup templates"
fi

# Append copilot-instructions supplement (if exists)
if [[ -f "$MODULE_DIR/copilot-instructions-supplement.md" ]]; then
    COPILOT_INSTRUCTIONS="$REPO_ROOT/.github/copilot-instructions.md"
    if [[ ! -f "$COPILOT_INSTRUCTIONS" ]]; then
        touch "$COPILOT_INSTRUCTIONS"
    fi
    {
        echo ""
        echo "<!-- BEGIN MODULE: $MODULE_NAME -->"
        cat "$MODULE_DIR/copilot-instructions-supplement.md"
        echo ""
        echo "<!-- END MODULE: $MODULE_NAME -->"
    } >> "$COPILOT_INSTRUCTIONS"
    log_success "Appended copilot-instructions supplement"
fi

# Notify about agent patches (manual merge required)
if [[ -d "$MODULE_DIR/agent-patches" ]] && [[ -n "$(ls -A "$MODULE_DIR/agent-patches/" 2>/dev/null)" ]]; then
    echo ""
    log_warn "Agent patches available in $MODULE_DIR/agent-patches/"
    log_warn "Review and manually merge into agent files as needed:"
    ls -1 "$MODULE_DIR/agent-patches/"
fi

# Present constitution articles (manual merge required)
if [[ -d "$MODULE_DIR/constitution-articles" ]] && [[ -n "$(ls -A "$MODULE_DIR/constitution-articles/" 2>/dev/null)" ]]; then
    echo ""
    log_warn "Constitution articles available:"
    ls -1 "$MODULE_DIR/constitution-articles/"
    log_warn "Merge relevant articles into .specify/memory/constitution.md"
fi

# Notify about placeholders
PLACEHOLDERS=$(jq -r '.placeholders // empty | keys[]' "$MODULE_DIR/module.json" 2>/dev/null || true)
if [[ -n "$PLACEHOLDERS" ]]; then
    echo ""
    log_warn "Module defines placeholders that need configuration:"
    echo "$PLACEHOLDERS" | while read -r key; do
        DESC=$(jq -r --arg k "$key" '.placeholders[$k] // ""' "$MODULE_DIR/module.json")
        echo "  - $key: $DESC"
    done
fi

# Update registry
log_info "Updating registry..."
INSTALL_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
FILES_JSON=$(printf '%s\n' "${INSTALLED_FILES[@]}" | jq -R . | jq -s .)

# Wave 20 §20.C.5 — compute per-file sha256 + aggregate manifest_sha256.
# Portable across macOS (shasum) and Linux (sha256sum).
sha256_of() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

FILE_HASHES_JSON="{}"
AGG_INPUT=""
for rel in "${INSTALLED_FILES[@]}"; do
    abs="$REPO_ROOT/$rel"
    if [[ -f "$abs" ]]; then
        h=$(sha256_of "$abs")
        FILE_HASHES_JSON=$(jq --arg k "$rel" --arg v "$h" '. + {($k): $v}' <<<"$FILE_HASHES_JSON")
        AGG_INPUT+="$rel:$h"$'\n'
    fi
done

if command -v sha256sum >/dev/null 2>&1; then
    MANIFEST_SHA256=$(printf '%s' "$AGG_INPUT" | sha256sum | awk '{print $1}')
else
    MANIFEST_SHA256=$(printf '%s' "$AGG_INPUT" | shasum -a 256 | awk '{print $1}')
fi

NEW_ENTRY=$(jq -n \
    --arg name "$MODULE_NAME" \
    --arg version "$MODULE_VERSION" \
    --arg date "$INSTALL_DATE" \
    --argjson files "$FILES_JSON" \
    --argjson fileHashes "$FILE_HASHES_JSON" \
    --arg manifestSha256 "$MANIFEST_SHA256" \
    '{name: $name, version: $version, installedAt: $date, files: $files, fileHashes: $fileHashes, manifestSha256: $manifestSha256}')

if [[ ! -f "$REGISTRY" ]]; then
    echo '{"version":"1.0.0","installedModules":[]}' > "$REGISTRY"
fi

# Replace any prior entry for this module (so re-install rebuilds the hashes
# rather than appending a duplicate) — Wave 20 §20.C.7 enables --reset.
jq --arg name "$MODULE_NAME" --argjson entry "$NEW_ENTRY" \
    '.installedModules = [(.installedModules[] | select(.name != $name))] + [$entry]' \
    "$REGISTRY" > "$REGISTRY.tmp"
mv "$REGISTRY.tmp" "$REGISTRY"
log_success "Registry updated (manifest sha256: ${MANIFEST_SHA256:0:12}…)"

# Recompose the effective agent set (core + all installed module contributions)
COMPOSE_SCRIPT="$SCRIPT_DIR/compose-agents.py"
if [[ -f "$COMPOSE_SCRIPT" ]]; then
    if python3 "$COMPOSE_SCRIPT" --repo-root "$REPO_ROOT" 2>&1; then
        log_success "Agent set recomposed (agents-composed.json updated)"
    else
        log_warn "compose-agents.py failed — agents-composed.json may be stale"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "Module '$MODULE_NAME' v$MODULE_VERSION installed successfully (${#INSTALLED_FILES[@]} files)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
