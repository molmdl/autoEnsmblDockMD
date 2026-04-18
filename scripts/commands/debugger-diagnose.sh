#!/usr/bin/env bash
# scripts/commands/debugger-diagnose.sh - Bridge for /debugger-diagnose slash command

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

ensure_env
WORKSPACE_ROOT="$(find_workspace_root)"
cd "${WORKSPACE_ROOT}"
parse_flags "$@"

dispatch_agent "debugger" "debugger_diagnose"
check_handoff_result "debugger_diagnose"
