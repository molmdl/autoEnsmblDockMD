#!/usr/bin/env bash
# scripts/commands/aedmd-preflight.sh - Preflight validation wrapper command

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

usage() {
  cat <<'EOF'
Preflight validation - validate config, tools, and inputs before workflow execution

Options:
  --config FILE    Config file to validate (default: config.ini)
  --verbose        Enable verbose output
  --help           Show this help
EOF
}

parse_flags "$@"
ensure_env
WORKSPACE_ROOT="$(find_workspace_root)"
cd "${WORKSPACE_ROOT}"

PLUGIN="${PROJECT_ROOT}/scripts/infra/plugins/preflight.py"
HANDOFF_FILE="${WORKSPACE_ROOT}/.handoffs/preflight_validation.json"

if [[ ! -f "$PLUGIN" ]]; then
  printf 'Error: preflight plugin not found: %s\n' "$PLUGIN" >&2
  exit 1
fi

mkdir -p "${WORKSPACE_ROOT}/.handoffs"
python3 "$PLUGIN" --config "$CONFIG" --workspace "$WORKSPACE_ROOT" > "$HANDOFF_FILE"

check_handoff_result "preflight_validation"
