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
GROUP_IDS_FILE_NAME="$(get_config mmpbsa group_ids_file "mmpbsa_groups.dat")"
RECEPTOR_GROUP_NAME="$(get_config mmpbsa receptor_group "Protein")"
LIGAND_GROUP_NAME="$(get_config mmpbsa ligand_group "Other")"
RECEPTOR_GROUP_ID=""
LIGAND_GROUP_ID=""
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

resolve_group_ids_from_index() {
    local index_path="$1"
    local receptor_group="$2"
    local ligand_group="$3"

    python - "${index_path}" "${receptor_group}" "${ligand_group}" <<'PY'
import re
import sys

index_path, receptor_name, ligand_name = sys.argv[1:4]
group_names = []
with open(index_path, "r", encoding="utf-8") as handle:
    for line in handle:
        match = re.match(r"^\s*\[(.+)\]\s*$", line)
        if match:
            group_names.append(match.group(1).strip())

if not group_names:
    print(f"ERROR: No groups found in index file: {index_path}", file=sys.stderr)
    sys.exit(1)

def find_group_id(target: str):
    for idx, name in enumerate(group_names):
        if name == target:
            return idx
    return None

receptor_id = find_group_id(receptor_name)
if receptor_id is None:
    print(f"ERROR: Receptor group '{receptor_name}' not found in {index_path}", file=sys.stderr)
    sys.exit(1)

ligand_id = find_group_id(ligand_name)
if ligand_id is None:
    print(f"ERROR: Ligand group '{ligand_name}' not found in {index_path}", file=sys.stderr)
    sys.exit(1)

print(f"receptor_group_id={receptor_id}")
print(f"ligand_group_id={ligand_id}")
PY
}

resolve_mmpbsa_groups() {
    local lig_path="$1"
    local index_path="$2"
    local groups_file="${lig_path}/${GROUP_IDS_FILE_NAME}"
    local cfg_receptor cfg_ligand
    local has_cfg_receptor=0
    local has_cfg_ligand=0
    local file_receptor=""
    local file_ligand=""
    local parsed=""

    cfg_receptor="$(get_config mmpbsa receptor_group_id "1")"
    cfg_ligand="$(get_config mmpbsa ligand_group_id "12")"
    if config_has mmpbsa receptor_group_id; then
        has_cfg_receptor=1
    fi
    if config_has mmpbsa ligand_group_id; then
        has_cfg_ligand=1
    fi

    if [[ ${has_cfg_receptor} -eq 1 && ${has_cfg_ligand} -eq 1 && ( "${cfg_receptor}" != "1" || "${cfg_ligand}" != "12" ) ]]; then
        if ! [[ "${cfg_receptor}" =~ ^[0-9]+$ ]] || ! [[ "${cfg_ligand}" =~ ^[0-9]+$ ]]; then
            log_error "Configured [mmpbsa] receptor_group_id/ligand_group_id must be integers (got '${cfg_receptor}'/'${cfg_ligand}')"
            exit 1
        fi
        RECEPTOR_GROUP_ID="${cfg_receptor}"
        LIGAND_GROUP_ID="${cfg_ligand}"
        log_info "Using configured MM/PBSA group IDs (override): receptor=${RECEPTOR_GROUP_ID}, ligand=${LIGAND_GROUP_ID}"
        return
    fi

    if [[ -f "${groups_file}" ]]; then
        file_receptor="$(python - "${groups_file}" <<'PY'
import sys
for line in open(sys.argv[1], 'r', encoding='utf-8'):
    line = line.strip()
    if not line or line.startswith('#') or '=' not in line:
        continue
    k, v = line.split('=', 1)
    if k.strip() == 'receptor_group_id':
        print(v.strip())
        break
PY
)"
        file_ligand="$(python - "${groups_file}" <<'PY'
import sys
for line in open(sys.argv[1], 'r', encoding='utf-8'):
    line = line.strip()
    if not line or line.startswith('#') or '=' not in line:
        continue
    k, v = line.split('=', 1)
    if k.strip() == 'ligand_group_id':
        print(v.strip())
        break
PY
)"

        if [[ "${file_receptor}" =~ ^[0-9]+$ ]] && [[ "${file_ligand}" =~ ^[0-9]+$ ]]; then
            RECEPTOR_GROUP_ID="${file_receptor}"
            LIGAND_GROUP_ID="${file_ligand}"
            log_info "Using MM/PBSA group IDs from ${groups_file}: receptor=${RECEPTOR_GROUP_ID}, ligand=${LIGAND_GROUP_ID}"
            return
        fi

        log_warn "Ignoring invalid group IDs in ${groups_file}; resolving from ${index_path}"
    fi

    parsed="$(resolve_group_ids_from_index "${index_path}" "${RECEPTOR_GROUP_NAME}" "${LIGAND_GROUP_NAME}")"
    RECEPTOR_GROUP_ID="$(printf '%s\n' "${parsed}" | python -c 'import sys; kv=dict(line.strip().split("=", 1) for line in sys.stdin if "=" in line); print(kv.get("receptor_group_id", ""))')"
    LIGAND_GROUP_ID="$(printf '%s\n' "${parsed}" | python -c 'import sys; kv=dict(line.strip().split("=", 1) for line in sys.stdin if "=" in line); print(kv.get("ligand_group_id", ""))')"

    if ! [[ "${RECEPTOR_GROUP_ID}" =~ ^[0-9]+$ ]] || ! [[ "${LIGAND_GROUP_ID}" =~ ^[0-9]+$ ]]; then
        log_error "Unable to resolve MM/PBSA receptor/ligand group IDs from ${index_path}"
        log_error "Provide valid [mmpbsa] receptor_group_id/ligand_group_id overrides or regenerate ${GROUP_IDS_FILE_NAME} via 2_trj4mmpbsa.sh"
        exit 1
    fi

    log_info "Using MM/PBSA group IDs resolved from ${index_path}: receptor=${RECEPTOR_GROUP_ID}, ligand=${LIGAND_GROUP_ID}"
}

lig_path="$(resolve_ligand_path "${LIGAND_OVERRIDE}")"
chunk_dir="${lig_path}/${CHUNK_DIR_PREFIX}${CHUNK_OVERRIDE}"
index_file="${lig_path}/${INDEX_FILE_NAME}"
topology_file="$(resolve_topology "${lig_path}")"

require_dir "${chunk_dir}" "Missing chunk directory: ${chunk_dir}"
require_file "${chunk_dir}/com.tpr" "Missing chunk topology: ${chunk_dir}/com.tpr"
require_file "${chunk_dir}/com_traj.xtc" "Missing chunk trajectory: ${chunk_dir}/com_traj.xtc"
require_file "${index_file}" "Missing index file: ${index_file}"

resolve_mmpbsa_groups "${lig_path}" "${index_file}"

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
