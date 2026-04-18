#!/usr/bin/env bash
# scripts/commands/checker-validate.sh - Bridge for /checker-validate slash command

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

ensure_env
WORKSPACE_ROOT="$(find_workspace_root)"
cd "${WORKSPACE_ROOT}"
parse_flags "$@"

dispatch_agent "checker" "checker_validate"
check_handoff_result "checker_validate"
