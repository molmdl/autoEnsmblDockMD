#!/usr/bin/env bash
# scripts/commands/aedmd-workspace-init.sh - Workspace initialization bridge

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

usage_workspace_init() {
  cat <<'EOF'
Usage: aedmd-workspace-init.sh --template DIR --target DIR [--force]

Required flags:
  --template DIR   Source workspace template directory
  --target DIR     Target workspace directory to create

Optional flags:
  --force          Overwrite target directory if it exists
  --help, -h       Show this help message
EOF
}

TEMPLATE=""
TARGET=""
FORCE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --template)
      if [[ $# -lt 2 || "$2" == --* ]]; then
        printf 'Error: --template requires a value\n' >&2
        exit 1
      fi
      TEMPLATE="$2"
      shift 2
      ;;
    --target)
      if [[ $# -lt 2 || "$2" == --* ]]; then
        printf 'Error: --target requires a value\n' >&2
        exit 1
      fi
      TARGET="$2"
      shift 2
      ;;
    --force)
      FORCE="1"
      shift
      ;;
    --help|-h)
      usage_workspace_init
      exit 0
      ;;
    *)
      printf 'Error: unexpected argument: %s\n' "$1" >&2
      usage_workspace_init
      exit 1
      ;;
  esac
done

if [[ -z "$TEMPLATE" || -z "$TARGET" ]]; then
  printf 'Error: --template and --target are required\n' >&2
  usage_workspace_init
  exit 1
fi

ensure_env
WORKSPACE_ROOT="$(find_workspace_root)"
cd "${WORKSPACE_ROOT}"

PLUGIN="${PROJECT_ROOT}/scripts/infra/plugins/workspace_init.py"
HANDOFF_FILE=".handoffs/workspace_init.json"

mkdir -p "$(dirname "$HANDOFF_FILE")"
python3 "$PLUGIN" --template "$TEMPLATE" --target "$TARGET" ${FORCE:+--force} > "$HANDOFF_FILE"

check_handoff_result "workspace_init"
