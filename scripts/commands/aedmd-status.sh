#!/usr/bin/env bash
# scripts/commands/aedmd-status.sh - Workspace status inspection for /aedmd-status slash command

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

ensure_env
WORKSPACE_ROOT="$(find_workspace_root)"
cd "${WORKSPACE_ROOT}"
parse_flags "$@"

status() {
  local config_file mode handoff_dir last_stage latest_success_ts
  config_file="$CONFIG"
  mode="unknown"
  handoff_dir=".handoffs"
  last_stage="none"
  latest_success_ts=""

  if [[ -f "$config_file" ]]; then
    mode="$(awk -F'=' '
      $0 ~ /^\[workflow\]/ { in_workflow=1; next }
      /^\[/ { in_workflow=0 }
      in_workflow && $1 ~ /^[[:space:]]*mode[[:space:]]*$/ {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
        print $2
        exit
      }
    ' "$config_file")"
    mode="${mode:-unknown}"
  fi

  printf 'Workspace: %s\n' "$WORKSPACE_ROOT"
  printf 'Config: %s\n' "$config_file"
  printf 'Mode: %s\n' "$mode"
  printf 'Handoffs:\n'

  if [[ -d "$handoff_dir" ]]; then
    local found_any
    found_any=false
    for f in "$handoff_dir"/*.json; do
      if [[ -f "$f" ]]; then
        found_any=true
        local stage_name status ts
        stage_name="$(basename "$f" .json)"
        status="$(jq -r '.status // "unknown"' "$f")"
        ts="$(jq -r '.timestamp // ""' "$f")"
        printf '  - %s: %s\n' "$stage_name" "$status"
        if [[ "$status" == "success" && -n "$ts" ]]; then
          if [[ -z "$latest_success_ts" || "$ts" > "$latest_success_ts" ]]; then
            latest_success_ts="$ts"
            last_stage="$stage_name"
          fi
        elif [[ "$status" == "success" && "$last_stage" == "none" ]]; then
          last_stage="$stage_name"
        fi
      fi
    done

    if [[ "$found_any" == false ]]; then
      printf '  (none)\n'
    fi
  else
    printf '  (none)\n'
  fi

  printf 'Last completed stage: %s\n' "${last_stage:-none}"
}

status
