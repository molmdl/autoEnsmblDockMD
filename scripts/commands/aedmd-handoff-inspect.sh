#!/usr/bin/env bash
# scripts/commands/aedmd-handoff-inspect.sh - Handoff inspector wrapper command

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

usage() {
  cat <<'EOF'
Handoff inspector - parse latest handoff and provide next-action guidance

Options:
  --workspace DIR  Workspace to inspect (default: auto-detect)
  --verbose        Enable verbose output
  --help           Show this help
EOF
}

WORKSPACE=""
FILTERED_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace)
      if [[ $# -lt 2 || "$2" == --* ]]; then
        printf 'Error: --workspace requires a value\n' >&2
        exit 1
      fi
      WORKSPACE="$2"
      shift 2
      ;;
    *)
      FILTERED_ARGS+=("$1")
      shift
      ;;
  esac
done

parse_flags "${FILTERED_ARGS[@]}"
ensure_env

WORKSPACE_ROOT="${WORKSPACE:-$(find_workspace_root)}"
PLUGIN="${PROJECT_ROOT}/scripts/infra/plugins/handoff_inspect.py"
HANDOFF_FILE="${WORKSPACE_ROOT}/.handoffs/handoff_inspection.json"

if [[ ! -f "$PLUGIN" ]]; then
  printf 'Error: handoff inspector plugin not found: %s\n' "$PLUGIN" >&2
  exit 1
fi

mkdir -p "${WORKSPACE_ROOT}/.handoffs"
python3 "$PLUGIN" --workspace "$WORKSPACE_ROOT" > "$HANDOFF_FILE"

check_handoff_result "handoff_inspection"
