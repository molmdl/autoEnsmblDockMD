#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../infra/common.sh"

SCRIPT_NAME="2_sub_mmpbsa"
CONFIG_FILE=""
LIGAND_OVERRIDE=""

usage() {
    cat <<'EOF'
Usage: 2_sub_mmpbsa.sh [--config FILE] [--ligand NAME|PATH] [--help]

Submit MM/PBSA as Slurm job arrays (one array task per chunk) for each ligand.

Options:
  --config FILE          INI config file
  --ligand NAME|PATH     Submit one ligand only
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
    chunk_dir_prefix
    partition
    cpus_per_task
    array_parallelism
    mmpbsa_script
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
require_cmd sbatch

WORKDIR="$(get_config general workdir "$(pwd)")"
COMPLEX_WORKDIR="$(get_config complex workdir "${WORKDIR}/com")"
MMPBSA_WORKDIR="$(get_config mmpbsa workdir "${COMPLEX_WORKDIR}")"
LIGAND_DIR="$(get_config mmpbsa ligand_dir "${MMPBSA_WORKDIR}")"
COMPLEX_LIGAND_PATTERN_DEFAULT="$(get_config complex ligand_pattern "lig*")"
COMPLEX_LIGAND_LIST_DEFAULT="$(get_config complex ligand_list "")"
SLURM_PARTITION_DEFAULT="$(get_config slurm partition "cpu")"
LIGAND_PATTERN="$(get_config mmpbsa ligand_pattern "${COMPLEX_LIGAND_PATTERN_DEFAULT}")"
LIGAND_LIST_CFG="$(get_config mmpbsa ligand_list "${COMPLEX_LIGAND_LIST_DEFAULT}")"

N_CHUNKS="$(get_config mmpbsa n_chunks "4")"
CHUNK_DIR_PREFIX="$(get_config mmpbsa chunk_dir_prefix "mmpbsa_")"
SLURM_PARTITION="$(get_config mmpbsa partition "${SLURM_PARTITION_DEFAULT}")"
SLURM_CPUS="$(get_config mmpbsa cpus_per_task "16")"
ARRAY_PARALLELISM="$(get_config mmpbsa array_parallelism "")"
MMPBSA_SCRIPT="$(get_config mmpbsa mmpbsa_script "${SCRIPT_DIR}/2_mmpbsa.sh")"

if ! [[ "${N_CHUNKS}" =~ ^[0-9]+$ ]] || [[ "${N_CHUNKS}" -le 0 ]]; then
    log_error "Invalid [mmpbsa] n_chunks='${N_CHUNKS}'"
    exit 1
fi

require_dir "${LIGAND_DIR}" "MM/PBSA ligand directory not found: ${LIGAND_DIR}"
require_file "${MMPBSA_SCRIPT}" "MM/PBSA worker script not found: ${MMPBSA_SCRIPT}"

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

submit_ligand_array() {
    local lig_path="$1"
    local lig_name array_spec job_id

    lig_name="$(basename "${lig_path}")"

    for chunk in $(seq 0 $((N_CHUNKS - 1))); do
        require_dir "${lig_path}/${CHUNK_DIR_PREFIX}${chunk}" "Missing chunk directory for ${lig_name}: ${lig_path}/${CHUNK_DIR_PREFIX}${chunk}"
    done

    array_spec="0-$((N_CHUNKS - 1))"
    if [[ -n "${ARRAY_PARALLELISM}" ]]; then
        array_spec+="%${ARRAY_PARALLELISM}"
    fi

    job_id="$({
        sbatch --parsable --array="${array_spec}" <<EOF
#!/usr/bin/env bash
#SBATCH -J mmpbsa_${lig_name}
#SBATCH -n 1
#SBATCH -c ${SLURM_CPUS}
#SBATCH -p ${SLURM_PARTITION}

set -euo pipefail

bash "${MMPBSA_SCRIPT}" --config "${CONFIG_FILE}" --ligand "${lig_path}" --chunk "\${SLURM_ARRAY_TASK_ID}"
EOF
    } | tr -d '[:space:]')"

    if [[ -z "${job_id}" ]]; then
        log_error "Failed to submit MM/PBSA array for ${lig_name}"
        exit 1
    fi

    printf '%s\n' "${lig_name}:${job_id}"
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
    entry="$(submit_ligand_array "${lig_path}")"
    log_info "Submitted MM/PBSA array ${entry}"
done

log_info "MM/PBSA array submission complete"
