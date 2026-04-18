#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../infra/common.sh"

SCRIPT_NAME="2_trj4mmpbsa"
CONFIG_FILE=""
LIGAND_OVERRIDE=""

usage() {
    cat <<'EOF'
Usage: 2_trj4mmpbsa.sh [--config FILE] [--ligand NAME|PATH] [--help]

Prepare trajectories for MM/PBSA:
1) Create/refresh index file with receptor+ligand complex group
2) Center and fit each chunk trajectory with trjconv
3) Write chunk workdirs: mmpbsa_0 ... mmpbsa_N-1
4) Copy per-chunk com.tpr and mmpbsa.in

Options:
  --config FILE          INI config file
  --ligand NAME|PATH     Process one ligand only
  -h, --help             Show this help and exit

Config keys used:
  [general]
    workdir
  [complex]
    workdir
    ligand_pattern
    ligand_list
  [mmpbsa]
    workdir
    ligand_dir
    ligand_pattern
    ligand_list
    n_chunks
    receptor_group
    ligand_group
    complex_group_name
    index_file
    source_xtc_pattern
    source_tpr_pattern
    chunk_dir_prefix
    mmpbsa_input
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
require_cmd gmx

WORKDIR="$(get_config general workdir "$(pwd)")"
COMPLEX_WORKDIR="$(get_config complex workdir "${WORKDIR}/com")"
MMPBSA_WORKDIR="$(get_config mmpbsa workdir "${COMPLEX_WORKDIR}")"
LIGAND_DIR="$(get_config mmpbsa ligand_dir "${MMPBSA_WORKDIR}")"
LIGAND_PATTERN="$(get_config mmpbsa ligand_pattern "$(get_config complex ligand_pattern "lig*")")"
LIGAND_LIST_CFG="$(get_config mmpbsa ligand_list "$(get_config complex ligand_list "")")"

N_CHUNKS="$(get_config mmpbsa n_chunks "4")"
RECEPTOR_GROUP="$(get_config mmpbsa receptor_group "Protein")"
LIGAND_GROUP="$(get_config mmpbsa ligand_group "Other")"
COMPLEX_GROUP_NAME="$(get_config mmpbsa complex_group_name "Protein_Other")"
INDEX_FILE_NAME="$(get_config mmpbsa index_file "index.ndx")"
SOURCE_XTC_PATTERN="$(get_config mmpbsa source_xtc_pattern "prod_%d.xtc")"
SOURCE_TPR_PATTERN="$(get_config mmpbsa source_tpr_pattern "prod_%d.tpr")"
CHUNK_DIR_PREFIX="$(get_config mmpbsa chunk_dir_prefix "mmpbsa_")"
MMPBSA_INPUT="$(get_config mmpbsa mmpbsa_input "${SCRIPT_DIR}/mmpbsa.in")"

if ! [[ "${N_CHUNKS}" =~ ^[0-9]+$ ]] || [[ "${N_CHUNKS}" -le 0 ]]; then
    log_error "Invalid [mmpbsa] n_chunks='${N_CHUNKS}'"
    exit 1
fi

if [[ "${SOURCE_XTC_PATTERN}" != *"%d"* ]] || [[ "${SOURCE_TPR_PATTERN}" != *"%d"* ]]; then
    log_error "source_xtc_pattern and source_tpr_pattern must contain %d"
    exit 1
fi

require_dir "${LIGAND_DIR}" "MM/PBSA ligand directory not found: ${LIGAND_DIR}"
require_file "${MMPBSA_INPUT}" "MM/PBSA input file not found: ${MMPBSA_INPUT}"

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

make_index_with_complex_group() {
    local seed_tpr="$1"
    local index_file="$2"
    local group_count complex_group_id

    local ndx_cmd
    ndx_cmd="${RECEPTOR_GROUP} | ${LIGAND_GROUP}\nq\n"
    printf '%b' "${ndx_cmd}" | gmx make_ndx -f "${seed_tpr}" -o "${index_file}" >/dev/null

    group_count="$(python - "${index_file}" <<'PY'
import re
import sys
count = 0
for line in open(sys.argv[1], 'r', encoding='utf-8'):
    if re.match(r'^\s*\[.*\]\s*$', line):
        count += 1
print(count)
PY
)"

    if ! [[ "${group_count}" =~ ^[0-9]+$ ]] || [[ "${group_count}" -le 0 ]]; then
        log_error "Failed to determine group count from ${index_file}"
        exit 1
    fi

    complex_group_id=$((group_count - 1))
    printf '%s\n' "${complex_group_id}"
}

process_chunk() {
    local ligand_dir="$1"
    local chunk_idx="$2"
    local index_file="$3"
    local complex_group_id="$4"
    local src_xtc src_tpr chunk_dir

    src_xtc="$(printf "${SOURCE_XTC_PATTERN}" "${chunk_idx}")"
    src_tpr="$(printf "${SOURCE_TPR_PATTERN}" "${chunk_idx}")"
    src_xtc="${ligand_dir}/${src_xtc}"
    src_tpr="${ligand_dir}/${src_tpr}"
    chunk_dir="${ligand_dir}/${CHUNK_DIR_PREFIX}${chunk_idx}"

    require_file "${src_xtc}" "Missing chunk trajectory: ${src_xtc}"
    require_file "${src_tpr}" "Missing chunk topology: ${src_tpr}"

    ensure_dir "${chunk_dir}"

    printf '%b' "${complex_group_id}\n${complex_group_id}\n" | \
        gmx trjconv -s "${src_tpr}" -f "${src_xtc}" -pbc mol -ur compact -center -n "${index_file}" -o "${chunk_dir}/pbc.xtc" >/dev/null

    printf '%b' "${complex_group_id}\n${complex_group_id}\n" | \
        gmx trjconv -s "${src_tpr}" -f "${chunk_dir}/pbc.xtc" -pbc cluster -fit rot+trans -n "${index_file}" -o "${chunk_dir}/com_traj.xtc" >/dev/null

    cp -f "${src_tpr}" "${chunk_dir}/com.tpr"
    cp -f "${MMPBSA_INPUT}" "${chunk_dir}/mmpbsa.in"
}

if [[ -n "${LIGAND_OVERRIDE}" ]]; then
    LIGAND_LIST_CFG="${LIGAND_OVERRIDE}"
fi

declare -a TARGETS=()
discover_ligands "${LIGAND_LIST_CFG}" TARGETS

if [[ ${#TARGETS[@]} -eq 0 ]]; then
    log_error "No ligand directories discovered under ${LIGAND_DIR} (pattern: ${LIGAND_PATTERN})"
    exit 1
fi

for lig_path in "${TARGETS[@]}"; do
    lig_name="$(basename "${lig_path}")"
    first_tpr="${lig_path}/$(printf "${SOURCE_TPR_PATTERN}" 0)"
    index_file="${lig_path}/${INDEX_FILE_NAME}"
    complex_group_id=""

    require_file "${first_tpr}" "Missing seed topology for index generation: ${first_tpr}"
    complex_group_id="$(make_index_with_complex_group "${first_tpr}" "${index_file}")"

    for chunk in $(seq 0 $((N_CHUNKS - 1))); do
        process_chunk "${lig_path}" "${chunk}" "${index_file}" "${complex_group_id}"
    done

    log_info "Prepared ${N_CHUNKS} MM/PBSA chunk(s) for ${lig_name} (complex group ${complex_group_id})"
done

log_info "Trajectory preparation for MM/PBSA complete"
