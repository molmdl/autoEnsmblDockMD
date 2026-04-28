#!/usr/bin/env bash
# scripts/commands/aedmd-group-id-check.sh - Group ID consistency checker wrapper

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

WORKSPACE=""
FILTERED_ARGS=()

usage() {
  cat <<'EOF'
Group ID consistency checker - validate MM/PBSA group IDs against index.ndx

Options:
  --workspace DIR  Workspace to validate (default: auto-detect)
  --verbose        Enable verbose output
  --help           Show this help
EOF
}

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

PLUGIN="${PROJECT_ROOT}/scripts/infra/plugins/group_id_check.py"
HANDOFF_FILE="${WORKSPACE_ROOT}/.handoffs/group_id_check.json"

mkdir -p "${WORKSPACE_ROOT}/.handoffs"
python3 "$PLUGIN" --workspace "$WORKSPACE_ROOT" > "$HANDOFF_FILE"

check_handoff_result "group_id_check"
