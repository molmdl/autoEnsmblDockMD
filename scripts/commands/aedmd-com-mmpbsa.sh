#!/usr/bin/env bash
# scripts/commands/aedmd-com-mmpbsa.sh - Bridge for /aedmd-com-mmpbsa slash command

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

ensure_env
WORKSPACE_ROOT="$(find_workspace_root)"
cd "${WORKSPACE_ROOT}"
parse_flags "$@"

dispatch_agent "runner" "complex_mmpbsa"
check_handoff_result "complex_mmpbsa"
