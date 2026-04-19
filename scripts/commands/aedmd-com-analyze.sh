#!/usr/bin/env bash
# scripts/commands/aedmd-com-analyze.sh - Bridge for /aedmd-com-analyze slash command

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

ensure_env
WORKSPACE_ROOT="$(find_workspace_root)"
cd "${WORKSPACE_ROOT}"
parse_flags "$@"

dispatch_agent "analyzer" "complex_analysis"
check_handoff_result "complex_analysis"
