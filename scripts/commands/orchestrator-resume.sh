#!/usr/bin/env bash
# scripts/commands/orchestrator-resume.sh - Bridge for /orchestrator-resume slash command

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

ensure_env
WORKSPACE_ROOT="$(find_workspace_root)"
cd "${WORKSPACE_ROOT}"
parse_flags "$@"

dispatch_agent "orchestrator" "orchestrator_resume"
check_handoff_result "orchestrator_resume"
