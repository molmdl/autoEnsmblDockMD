#!/usr/bin/env bash
# scripts/commands/com-analyze.sh - Bridge for /com-analyze slash command

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

ensure_env
WORKSPACE_ROOT="$(find_workspace_root)"
cd "${WORKSPACE_ROOT}"
parse_flags "$@"

dispatch_agent "analyzer" "com_analyze"
check_handoff_result "com_analyze"
