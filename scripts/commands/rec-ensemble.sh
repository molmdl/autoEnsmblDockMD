#!/usr/bin/env bash
# scripts/commands/rec-ensemble.sh - Bridge for /rec-ensemble slash command

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

ensure_env
WORKSPACE_ROOT="$(find_workspace_root)"
cd "${WORKSPACE_ROOT}"
parse_flags "$@"

dispatch_agent "runner" "rec_ensemble"
check_handoff_result "rec_ensemble"
