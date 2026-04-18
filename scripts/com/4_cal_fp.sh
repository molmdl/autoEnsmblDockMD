#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../infra/common.sh"

SCRIPT_NAME="4_cal_fp"
CONFIG_FILE=""
LIGAND_OVERRIDE=""

usage() {
    cat <<'EOF'
Usage: 4_cal_fp.sh [--config FILE] [--ligand NAME|PATH] [--help]

Run fingerprint analysis across one or more ligand complex directories.

Options:
  --config FILE          INI config file
  --ligand NAME|PATH     Process one or more ligands (comma-separated)
  -h, --help             Show this help and exit

Config keys used:
  [general]
    workdir
  [complex]
    workdir
    ligand_pattern
  [fingerprint]
    workdir
    ligand_dir
    ligand_pattern
    ligand_list
    trajectory
    topology
    output_dir
    output_prefix
    ligand_selection
    receptor_selection
    cutoff
    summary_csv
    fp_script
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --config)
            [[ $# -ge 2 ]] || { log_error "--config requires a file path"; exit 1; }
            CONFIG_FILE="$2"
            shift 2
            ;;
        --ligand)
            [[ $# -ge 2 ]] || { log_error "--ligand requires a value"; exit 1; }
            LIGAND_OVERRIDE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

init_script "${SCRIPT_NAME}" "${CONFIG_FILE}"
require_cmd python

WORKDIR="$(get_config general workdir "$(pwd)")"
COMPLEX_WORKDIR="$(get_config complex workdir "${WORKDIR}/com")"
FP_WORKDIR="$(get_config fingerprint workdir "${COMPLEX_WORKDIR}")"
LIGAND_DIR="$(get_config fingerprint ligand_dir "${FP_WORKDIR}")"
LIGAND_PATTERN="$(get_config fingerprint ligand_pattern "$(get_config complex ligand_pattern "lig*")")"
LIGAND_LIST_CFG="$(get_config fingerprint ligand_list "")"

TRAJ_NAME="$(get_config fingerprint trajectory "com_traj.xtc")"
TOP_NAME="$(get_config fingerprint topology "com.tpr")"
OUTPUT_SUBDIR="$(get_config fingerprint output_dir "fp")"
OUTPUT_PREFIX="$(get_config fingerprint output_prefix "fingerprint")"
LIGAND_SELECTION="$(get_config fingerprint ligand_selection "resname MOL and not name H*")"
RECEPTOR_SELECTION="$(get_config fingerprint receptor_selection "protein and not name H*")"
CUTOFF="$(get_config fingerprint cutoff "4.5")"
SUMMARY_CSV="$(get_config fingerprint summary_csv "${FP_WORKDIR}/fingerprint_summary.csv")"
FP_SCRIPT="$(get_config fingerprint fp_script "${SCRIPT_DIR}/4_fp.py")"

require_dir "${LIGAND_DIR}" "Fingerprint ligand directory not found: ${LIGAND_DIR}"
require_file "${FP_SCRIPT}" "Fingerprint script not found: ${FP_SCRIPT}"

if [[ -n "${LIGAND_OVERRIDE}" ]]; then
    LIGAND_LIST_CFG="${LIGAND_OVERRIDE}"
fi

discover_ligands() {
    local explicit="$1"
    local -n _targets_ref="$2"
    local token
    _targets_ref=()

    if [[ -n "${explicit}" ]]; then
        explicit="${explicit//,/ }"
        for token in ${explicit}; do
            if [[ -d "${token}" ]]; then
                _targets_ref+=("$(realpath "${token}")")
            elif [[ -d "${LIGAND_DIR}/${token}" ]]; then
                _targets_ref+=("$(realpath "${LIGAND_DIR}/${token}")")
            else
                log_error "Ligand target not found: ${token}"
                exit 1
            fi
        done
        return
    fi

    shopt -s nullglob
    local entries=("${LIGAND_DIR}/${LIGAND_PATTERN}")
    shopt -u nullglob

    for token in "${entries[@]}"; do
        [[ -d "${token}" ]] || continue
        _targets_ref+=("$(realpath "${token}")")
    done
}

declare -a TARGETS=()
discover_ligands "${LIGAND_LIST_CFG}" TARGETS

if [[ ${#TARGETS[@]} -eq 0 ]]; then
    log_error "No ligand directories discovered under ${LIGAND_DIR} (pattern: ${LIGAND_PATTERN})"
    exit 1
fi

summary_dir="$(dirname "${SUMMARY_CSV}")"
ensure_dir "${summary_dir}"
printf 'ligand,matrix_csv,heatmap_png\n' > "${SUMMARY_CSV}"

for lig_path in "${TARGETS[@]}"; do
    lig_name="$(basename "${lig_path}")"
    traj_file="${lig_path}/${TRAJ_NAME}"
    top_file="${lig_path}/${TOP_NAME}"
    out_dir="${lig_path}/${OUTPUT_SUBDIR}"
    out_prefix="${out_dir}/${OUTPUT_PREFIX}"
    matrix_file="${out_prefix}_matrix.csv"
    heatmap_file="${out_prefix}_similarity_heatmap.png"

    require_file "${traj_file}" "Missing trajectory for ${lig_name}: ${traj_file}"
    require_file "${top_file}" "Missing topology for ${lig_name}: ${top_file}"
    ensure_dir "${out_dir}"

    log_info "Calculating fingerprint for ${lig_name}"
    python "${FP_SCRIPT}" \
        --topology "${top_file}" \
        --trajectory "${traj_file}" \
        --ligand-selection "${LIGAND_SELECTION}" \
        --receptor-selection "${RECEPTOR_SELECTION}" \
        --cutoff "${CUTOFF}" \
        --output "${out_prefix}" \
        --config "${CONFIG_FILE}"

    printf '%s,%s,%s\n' "${lig_name}" "${matrix_file}" "${heatmap_file}" >> "${SUMMARY_CSV}"
done

log_info "Fingerprint calculation complete for ${#TARGETS[@]} ligand(s)"
log_info "Summary written to ${SUMMARY_CSV}"
