#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../infra/common.sh"

SCRIPT_NAME="2_mmpbsa"
CONFIG_FILE=""
LIGAND_OVERRIDE=""
CHUNK_OVERRIDE=""

usage() {
    cat <<'EOF'
Usage: 2_mmpbsa.sh [--config FILE] [--ligand NAME|PATH] --chunk N [--help]

Run a single MM/PBSA chunk for one ligand.

Options:
  --config FILE          INI config file
  --ligand NAME|PATH     Ligand directory name/path
  --chunk N              Chunk index (0-based)
  -h, --help             Show this help and exit

Config keys used:
  [general]
    workdir
  [complex]
    workdir
  [mmpbsa]
    workdir
    ligand_dir
    chunk_dir_prefix
    index_file
    receptor_group_id
    ligand_group_id
    mmpbsa_input
    topology_file
    amber_topology_file
    charmm_topology_file
    ff
    mpi_ranks
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
        --chunk)
            [[ $# -ge 2 ]] || { log_error "--chunk requires an integer"; exit 1; }
            CHUNK_OVERRIDE="$2"
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
require_cmd gmx_MMPBSA
require_cmd mpirun

if [[ -z "${CHUNK_OVERRIDE}" ]]; then
    log_error "--chunk is required"
    usage
    exit 1
fi
if ! [[ "${CHUNK_OVERRIDE}" =~ ^[0-9]+$ ]]; then
    log_error "Invalid --chunk value '${CHUNK_OVERRIDE}'"
    exit 1
fi

WORKDIR="$(get_config general workdir "$(pwd)")"
COMPLEX_WORKDIR="$(get_config complex workdir "${WORKDIR}/com")"
MMPBSA_WORKDIR="$(get_config mmpbsa workdir "${COMPLEX_WORKDIR}")"
LIGAND_DIR="$(get_config mmpbsa ligand_dir "${MMPBSA_WORKDIR}")"
CHUNK_DIR_PREFIX="$(get_config mmpbsa chunk_dir_prefix "mmpbsa_")"
INDEX_FILE_NAME="$(get_config mmpbsa index_file "index.ndx")"
MMPBSA_INPUT_NAME="$(get_config mmpbsa mmpbsa_input "mmpbsa.in")"
RECEPTOR_GROUP_ID="$(get_config mmpbsa receptor_group_id "1")"
LIGAND_GROUP_ID="$(get_config mmpbsa ligand_group_id "12")"
MPI_RANKS="$(get_config mmpbsa mpi_ranks "16")"

FF_MODE="$(get_config mmpbsa ff "$(get_config complex ff "charmm")")"
FF_MODE="${FF_MODE,,}"

resolve_ligand_path() {
    local input="$1"
    if [[ -z "${input}" ]]; then
        log_error "--ligand is required"
        exit 1
    fi
    if [[ -d "${input}" ]]; then
        realpath "${input}"
        return
    fi
    if [[ -d "${LIGAND_DIR}/${input}" ]]; then
        realpath "${LIGAND_DIR}/${input}"
        return
    fi
    log_error "Ligand directory not found: ${input}"
    exit 1
}

resolve_topology() {
    local lig_path="$1"
    local explicit base

    explicit="$(get_config mmpbsa topology_file "")"
    if [[ -n "${explicit}" ]]; then
        if [[ -f "${explicit}" ]]; then
            realpath "${explicit}"
            return
        fi
        if [[ -f "${lig_path}/${explicit}" ]]; then
            realpath "${lig_path}/${explicit}"
            return
        fi
    fi

    if [[ "${FF_MODE}" == *amber* ]]; then
        base="$(get_config mmpbsa amber_topology_file "bypass_sys.top")"
        if [[ -f "${lig_path}/${base}" ]]; then
            realpath "${lig_path}/${base}"
            return
        fi
    else
        base="$(get_config mmpbsa charmm_topology_file "sys.top")"
        if [[ -f "${lig_path}/${base}" ]]; then
            realpath "${lig_path}/${base}"
            return
        fi
    fi

    if [[ -f "${lig_path}/bypass_sys.top" ]]; then
        realpath "${lig_path}/bypass_sys.top"
        return
    fi
    if [[ -f "${lig_path}/sys.top" ]]; then
        realpath "${lig_path}/sys.top"
        return
    fi

    log_error "No usable topology found in ${lig_path}"
    exit 1
}

lig_path="$(resolve_ligand_path "${LIGAND_OVERRIDE}")"
chunk_dir="${lig_path}/${CHUNK_DIR_PREFIX}${CHUNK_OVERRIDE}"
index_file="${lig_path}/${INDEX_FILE_NAME}"
topology_file="$(resolve_topology "${lig_path}")"

require_dir "${chunk_dir}" "Missing chunk directory: ${chunk_dir}"
require_file "${chunk_dir}/com.tpr" "Missing chunk topology: ${chunk_dir}/com.tpr"
require_file "${chunk_dir}/com_traj.xtc" "Missing chunk trajectory: ${chunk_dir}/com_traj.xtc"
require_file "${index_file}" "Missing index file: ${index_file}"

mmpbsa_input="${chunk_dir}/${MMPBSA_INPUT_NAME}"
if [[ ! -f "${mmpbsa_input}" ]]; then
    mmpbsa_input="$(get_config mmpbsa mmpbsa_input "${SCRIPT_DIR}/mmpbsa.in")"
fi
require_file "${mmpbsa_input}" "Missing MM/PBSA input file: ${mmpbsa_input}"

pushd "${chunk_dir}" >/dev/null
mpirun -np "${MPI_RANKS}" gmx_MMPBSA -O \
    -i "${mmpbsa_input}" \
    -cs com.tpr \
    -ct com_traj.xtc \
    -ci "${index_file}" \
    -cg "${RECEPTOR_GROUP_ID}" "${LIGAND_GROUP_ID}" \
    -cp "${topology_file}" \
    -o FINAL_RESULTS_MMPBSA.dat \
    -eo FINAL_RESULTS_MMPBSA.csv \
    -do FINAL_DECOMP_MMPBSA.dat \
    -deo FINAL_DECOMP_MMPBSA.csv \
    -nogui
popd >/dev/null

log_info "MM/PBSA chunk ${CHUNK_OVERRIDE} complete for $(basename "${lig_path}")"
