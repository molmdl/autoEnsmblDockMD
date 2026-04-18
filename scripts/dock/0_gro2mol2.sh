#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../infra/common.sh"

DEFAULT_CONFIG="config.ini"
CONFIG_FILE=""

print_help() {
    cat <<'EOF'
Usage: 0_gro2mol2.sh [--config FILE] [--help]

Convert ligand GRO files to MOL2 for docking input.

Config keys (section [dock]):
  ligand_dir        Directory containing ligand GRO/ITP files (required)
  output_dir        Output directory for MOL2 files (required)
  gro_pattern       GRO file glob under ligand_dir (default: *.gro)
  itp_suffix        ITP suffix relative to GRO stem (default: _gmx.top)
  converter_script  Python converter path (default: scripts/dock/0_gro_itp_to_mol2.py)

Examples:
  bash scripts/dock/0_gro2mol2.sh --config work/config.ini
  bash scripts/dock/0_gro2mol2.sh
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
    init_script "0_gro2mol2" "$CONFIG_FILE"
else
    init_script "0_gro2mol2"
fi

require_cmd python

LIGAND_DIR="$(require_config dock ligand_dir)"
OUTPUT_DIR="$(require_config dock output_dir)"
GRO_PATTERN="$(get_config dock gro_pattern "*.gro")"
ITP_SUFFIX="$(get_config dock itp_suffix "_gmx.top")"
CONVERTER_SCRIPT="$(get_config dock converter_script "scripts/dock/0_gro_itp_to_mol2.py")"

require_dir "$LIGAND_DIR" "Ligand directory not found: $LIGAND_DIR"
require_file "$CONVERTER_SCRIPT" "Converter script not found: $CONVERTER_SCRIPT"
ensure_dir "$OUTPUT_DIR"

shopt -s nullglob
gro_files=("${LIGAND_DIR}"/${GRO_PATTERN})
shopt -u nullglob

if [[ ${#gro_files[@]} -eq 0 ]]; then
    log_error "No GRO files matched pattern '${GRO_PATTERN}' in '${LIGAND_DIR}'"
    exit 1
fi

converted=0
for gro_file in "${gro_files[@]}"; do
    require_file "$gro_file"

    base_name="$(basename "$gro_file" .gro)"
    itp_file="${LIGAND_DIR}/${base_name}${ITP_SUFFIX}"
    out_file="${OUTPUT_DIR}/${base_name}.mol2"

    require_file "$itp_file" "Matching ITP file missing for ${gro_file}: ${itp_file}"

    log_info "Converting ${gro_file} + ${itp_file} -> ${out_file}"
    python "$CONVERTER_SCRIPT" --gro "$gro_file" --itp "$itp_file" --output "$out_file"
    ((converted+=1))
done

log_info "Finished conversion: ${converted} ligand(s) written to ${OUTPUT_DIR}"
