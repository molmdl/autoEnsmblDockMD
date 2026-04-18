#!/usr/bin/env bash

# Common bash utilities for workflow scripts.

_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${_COMMON_DIR}/config_loader.sh" ]]; then
    # shellcheck source=/dev/null
    source "${_COMMON_DIR}/config_loader.sh"
else
    printf 'Error: config_loader.sh not found in %s\n' "${_COMMON_DIR}" >&2
    return 1 2>/dev/null || exit 1
fi

_log_ts() {
    date +"%Y-%m-%dT%H:%M:%S%z"
}

log_info() {
    printf '[%s] [INFO] %s\n' "$(_log_ts)" "$*"
}

log_warn() {
    printf '[%s] [WARN] %s\n' "$(_log_ts)" "$*"
}

log_error() {
    printf '[%s] [ERROR] %s\n' "$(_log_ts)" "$*" >&2
}

require_file() {
    local path="$1"
    local msg="${2-Required file missing: $path}"
    if [[ ! -f "$path" ]]; then
        log_error "$msg"
        exit 1
    fi
}

require_dir() {
    local path="$1"
    local msg="${2-Required directory missing: $path}"
    if [[ ! -d "$path" ]]; then
        log_error "$msg"
        exit 1
    fi
}

require_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_error "Required command not found: $cmd"
        exit 1
    fi
}

run_gmx() {
    require_cmd gmx
    log_info "Running: gmx $*"
    if ! gmx "$@"; then
        log_error "gmx command failed: gmx $*"
        return 1
    fi
    return 0
}

submit_job() {
    local script="$1"
    local output job_id

    require_file "$script" "Slurm script missing: $script"
    require_cmd sbatch

    log_info "Submitting Slurm job: $script"
    if ! output="$(sbatch "$script" 2>&1)"; then
        log_error "sbatch failed: $output"
        return 1
    fi

    if [[ "$output" =~ Submitted[[:space:]]batch[[:space:]]job[[:space:]]([0-9]+) ]]; then
        job_id="${BASH_REMATCH[1]}"
        log_info "Submitted job ${job_id}"
        printf '%s\n' "$job_id"
        return 0
    fi

    log_error "Unable to parse job ID from sbatch output: $output"
    return 1
}

wait_job() {
    local job_id="$1"
    local interval="${2:-10}"
    local state

    if [[ -z "$job_id" ]]; then
        log_error "wait_job requires <job_id>"
        return 1
    fi

    require_cmd squeue
    require_cmd sacct

    log_info "Waiting for Slurm job ${job_id}"

    while true; do
        if squeue -h -j "$job_id" >/dev/null 2>&1 && [[ -n "$(squeue -h -j "$job_id")" ]]; then
            sleep "$interval"
            continue
        fi

        state="$(sacct -n -j "$job_id" --format=State 2>/dev/null | tr -d ' ' | tr '\n' ',' )"
        case "$state" in
            *COMPLETED*)
                log_info "Job ${job_id} completed"
                return 0
                ;;
            *FAILED*|*CANCELLED*|*TIMEOUT*|*OUT_OF_MEMORY*)
                log_error "Job ${job_id} failed with state: ${state}"
                return 1
                ;;
            "")
                log_warn "No sacct state for job ${job_id} yet; retrying"
                sleep "$interval"
                ;;
            *)
                sleep "$interval"
                ;;
        esac
    done
}

ensure_dir() {
    local path="$1"
    if [[ -z "$path" ]]; then
        log_error "ensure_dir requires <path>"
        return 1
    fi
    mkdir -p "$path"
}

backup_if_exists() {
    local file="$1"
    local backup
    if [[ -f "$file" ]]; then
        backup="${file}.bak.$(date +%Y%m%d%H%M%S)"
        cp "$file" "$backup"
        log_info "Backed up ${file} -> ${backup}"
    fi
}

init_script() {
    local script_name="$1"
    local config_file="${2-}"
    local repo_root setenv_file

    if [[ -z "$script_name" ]]; then
        log_error "init_script requires <name> [config_file]"
        exit 1
    fi

    repo_root="$(cd "${_COMMON_DIR}/../.." && pwd)"
    setenv_file="${repo_root}/scripts/setenv.sh"

    if [[ -f "$setenv_file" ]]; then
        # shellcheck source=/dev/null
        source "$setenv_file"
    else
        log_warn "setenv.sh not found at ${setenv_file}; continuing without sourcing"
    fi

    if [[ -n "$config_file" ]]; then
        load_config "$config_file" || {
            log_error "Failed to load config file: $config_file"
            exit 1
        }
        log_info "Loaded config from ${config_file}"
    fi

    log_info "Starting script: ${script_name}"
}
