#!/usr/bin/env bash
# scripts/commands/aedmd-checker-validate.sh - Bridge for /aedmd-checker-validate slash command

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

ensure_env
WORKSPACE_ROOT="$(find_workspace_root)"
cd "${WORKSPACE_ROOT}"
parse_flags "$@"

dispatch_agent "checker" "checker_validate"
check_handoff_result "checker_validate"
