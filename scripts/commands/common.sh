#!/usr/bin/env bash
# Shared utilities sourced by scripts/commands/*.sh bridge scripts.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG="config.ini"
VERBOSE=false
EXTRA_PARAMS='{}'

usage() {
  cat <<'EOF'
Usage: <command> [--config FILE] [--verbose] [--key value ...]

Common flags:
  --config FILE   Path to config.ini (default: config.ini)
  --verbose       Enable verbose command output
  --help          Show this help message

Any additional --key value pairs are forwarded to agent handoff params.
EOF
}

find_workspace_root() {
  local dir
  dir="$(pwd)"

  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/config.ini" || -f "$dir/.gsd-workspace" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done

  printf '%s\n' "$(pwd)"
}

ensure_env() {
  local setenv_path
  local had_nounset
  setenv_path="${PROJECT_ROOT}/scripts/setenv.sh"
  if [[ -f "$setenv_path" ]]; then
    had_nounset=false
    if [[ $- == *u* ]]; then
      had_nounset=true
      set +u
    fi
    # shellcheck disable=SC1090
    source "$setenv_path"
    if [[ "$had_nounset" == true ]]; then
      set -u
    fi
  fi
}

parse_flags() {
  CONFIG="config.ini"
  VERBOSE=false
  EXTRA_PARAMS='{}'

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        usage
        exit 0
        ;;
      --config)
        if [[ $# -lt 2 ]]; then
          printf 'Error: --config requires a value\n' >&2
          exit 1
        fi
        CONFIG="$2"
        shift 2
        ;;
      --verbose)
        VERBOSE=true
        EXTRA_PARAMS="$(jq '.verbose = true' <<<"$EXTRA_PARAMS")"
        shift
        ;;
      --*)
        if [[ $# -lt 2 || "$2" == --* ]]; then
          printf 'Error: %s requires a value\n' "$1" >&2
          exit 1
        fi
        local key
        key="${1#--}"
        EXTRA_PARAMS="$(jq --arg k "$key" --arg v "$2" '.[$k] = $v' <<<"$EXTRA_PARAMS")"
        shift 2
        ;;
      *)
        printf 'Error: unexpected argument: %s\n' "$1" >&2
        usage
        exit 1
        ;;
    esac
  done
}

dispatch_agent() {
  local agent stage handoff_input handoff_file
  agent="$1"
  stage="$2"
  handoff_file=".handoffs/${stage}.json"

  handoff_input="$(jq -n \
    --arg stage "$stage" \
    --arg config "$CONFIG" \
    --argjson params "$EXTRA_PARAMS" \
    '{stage: $stage, config: $config, params: $params}')"

  if [[ "$VERBOSE" == true ]]; then
    printf 'Dispatching agent=%s stage=%s config=%s\n' "$agent" "$stage" "$CONFIG" >&2
  fi

  mkdir -p .handoffs

  python -m scripts.agents --agent "$agent" --workspace "$(pwd)" --config "$CONFIG" --input <(printf '%s\n' "$handoff_input") --output "$handoff_file"
}

check_handoff_result() {
  local stage handoff_file status
  stage="$1"
  handoff_file=".handoffs/${stage}.json"

  if [[ ! -f "$handoff_file" ]]; then
    printf 'Handoff status: missing (%s)\n' "$handoff_file" >&2
    return 1
  fi

  status="$(jq -r '.status // "unknown"' "$handoff_file")"
  printf 'Handoff status for %s: %s\n' "$stage" "$status"

  case "$status" in
    success)
      return 0
      ;;
    needs_review)
      jq -r '.warnings[]? // empty' "$handoff_file" | sed 's/^/WARNING: /' >&2
      return 2
      ;;
    failure|blocked)
      jq -r '.errors[]? // empty' "$handoff_file" | sed 's/^/ERROR: /' >&2
      jq -r '.recommendations[]? // empty' "$handoff_file" | sed 's/^/RECOMMENDATION: /' >&2
      return 1
      ;;
    *)
      printf 'Unknown handoff status: %s\n' "$status" >&2
      return 1
      ;;
  esac
}
