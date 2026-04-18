#!/usr/bin/env bash
# scripts/commands/com-setup.sh - Bridge for /com-setup slash command

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

ensure_env
WORKSPACE_ROOT="$(find_workspace_root)"
cd "${WORKSPACE_ROOT}"
parse_flags "$@"

dispatch_agent "runner" "com_setup"
check_handoff_result "com_setup"
