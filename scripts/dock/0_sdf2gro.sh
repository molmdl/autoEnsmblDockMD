#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../infra/common.sh"

DEFAULT_CONFIG="config.ini"
CONFIG_FILE=""

print_help() {
    cat <<'EOF'
Usage: 0_sdf2gro.sh [--config FILE] [--help]

Convert SDF docking output files to GRO for downstream MD setup.

Config keys (section [dock]):
  sdf_input_dir   Root directory to search for SDF files (required)
  sdf_pattern     Glob pattern under sdf_input_dir (default: **/*.sdf)
  output_dir      Output directory for GRO files (required)
  recurse         Whether to recurse (true/false, default: true)

The conversion uses Open Babel:
  obabel input.sdf -O output.gro

Examples:
  bash scripts/dock/0_sdf2gro.sh --config work/config.ini
  bash scripts/dock/0_sdf2gro.sh
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --config)
            CONFIG_FILE="${2:-}"
            if [[ -z "$CONFIG_FILE" ]]; then
                log_error "--config requires a file path"
                exit 1
            fi
            shift 2
            ;;
        --help|-h)
            print_help
            exit 0
            ;;
        *)
            log_error "Unknown argument: $1"
            print_help
            exit 1
            ;;
    esac
done

if [[ -z "$CONFIG_FILE" && -f "$DEFAULT_CONFIG" ]]; then
    CONFIG_FILE="$DEFAULT_CONFIG"
fi

if [[ -n "$CONFIG_FILE" ]]; then
    init_script "0_sdf2gro" "$CONFIG_FILE"
else
    init_script "0_sdf2gro"
fi

require_cmd obabel

SDF_INPUT_DIR="$(require_config dock sdf_input_dir)"
SDF_PATTERN="$(get_config dock sdf_pattern "*.sdf")"
OUTPUT_DIR="$(require_config dock output_dir)"
RECURSE="$(get_config dock recurse "true")"

require_dir "$SDF_INPUT_DIR" "SDF input directory not found: $SDF_INPUT_DIR"
ensure_dir "$OUTPUT_DIR"

declare -a sdf_files=()

if [[ "${RECURSE,,}" == "true" ]]; then
    shopt -s globstar nullglob
    sdf_files=("${SDF_INPUT_DIR}"/${SDF_PATTERN})
    shopt -u globstar nullglob
else
    shopt -s nullglob
    sdf_files=("${SDF_INPUT_DIR}"/${SDF_PATTERN})
    shopt -u nullglob
fi

if [[ ${#sdf_files[@]} -eq 0 ]]; then
    log_error "No SDF files matched pattern '${SDF_PATTERN}' in '${SDF_INPUT_DIR}'"
    exit 1
fi

converted=0
for sdf_file in "${sdf_files[@]}"; do
    require_file "$sdf_file"

    rel_path="${sdf_file#${SDF_INPUT_DIR}/}"
    rel_dir="$(dirname "$rel_path")"
    stem="$(basename "$sdf_file" .sdf)"

    out_dir="${OUTPUT_DIR}"
    if [[ "$rel_dir" != "." ]]; then
        out_dir="${OUTPUT_DIR}/${rel_dir}"
        ensure_dir "$out_dir"
    fi
    out_file="${out_dir}/${stem}.gro"

    log_info "Converting ${sdf_file} -> ${out_file}"
    obabel "$sdf_file" -O "$out_file" >/dev/null
    ((converted+=1))
done

log_info "Finished conversion: ${converted} SDF file(s) written to ${OUTPUT_DIR}"
