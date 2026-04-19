#!/usr/bin/env bash
# scripts/commands/aedmd-rec-ensemble.sh - Bridge for /aedmd-rec-ensemble slash command

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

ensure_env
WORKSPACE_ROOT="$(find_workspace_root)"
cd "${WORKSPACE_ROOT}"
parse_flags "$@"

dispatch_agent "runner" "receptor_prep"
check_handoff_result "receptor_prep"
