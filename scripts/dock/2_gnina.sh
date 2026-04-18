#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../infra/common.sh"

print_help() {
    cat <<'EOF'
Usage: 2_gnina.sh [options]

Unified gnina docking launcher (Slurm):
  - mode=test     : single receptor/reference redocking validation
  - mode=blind    : ensemble docking, autobox from each receptor
  - mode=targeted : ensemble docking, autobox from reference ligand

Options:
  --config <path>          Config file path (default: config.ini)
  --mode <mode>            Override docking mode: test|blind|targeted
  --dock-dir <path>        Override docking workspace directory
  --ligands-dir <path>     Override ligand discovery directory
  --ligand-list "a,b,c"    Explicit ligand list (names or .mol2 paths)
  --ensemble-size <N>      Override receptor ensemble size
  --dry-run                Print resolved parameters and discovered ligands only
  -h, --help               Show this help message

Config keys used:
  [general] workdir
  [docking] mode = blind|targeted|test
  [docking] dock_dir
  [docking] ligands_dir
  [docking] ligand_pattern
  [docking] ligand_list
  [docking] receptor_dir
  [docking] receptor_prefix
  [docking] reference_ligand
  [docking] test_receptor
  [docking] exhaustiveness
  [docking] num_modes
  [docking] autobox_add
  [docking] autobox_ligand = receptor|ref.pdb|/path/to/file
  [docking] scoring = cnn|ad4_scoring
  [docking] addH = off|on
  [docking] stripH = off|on
  [docking] cpu
  [docking] min_rmsd_filter
  [slurm] partition
  [slurm] gpus
  [slurm] cpus_per_task
EOF
}

CONFIG_FILE="config.ini"
MODE_OVERRIDE=""
DOCK_DIR_OVERRIDE=""
LIGANDS_DIR_OVERRIDE=""
LIGAND_LIST_OVERRIDE=""
ENSEMBLE_SIZE_OVERRIDE=""
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --mode)
            MODE_OVERRIDE="$2"
            shift 2
            ;;
        --dock-dir)
            DOCK_DIR_OVERRIDE="$2"
            shift 2
            ;;
        --ligands-dir)
            LIGANDS_DIR_OVERRIDE="$2"
            shift 2
            ;;
        --ligand-list)
            LIGAND_LIST_OVERRIDE="$2"
            shift 2
            ;;
        --ensemble-size)
            ENSEMBLE_SIZE_OVERRIDE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            print_help
            exit 1
            ;;
    esac
done

init_script "2_gnina.sh" "${CONFIG_FILE}"

require_cmd gnina
require_cmd sbatch

WORKDIR="$(get_config general workdir "$(pwd)")"
DOCK_DIR="$(get_config docking dock_dir "${WORKDIR}/dock")"
LIGANDS_DIR="$(get_config docking ligands_dir "${DOCK_DIR}")"

if [[ -n "${DOCK_DIR_OVERRIDE}" ]]; then
    DOCK_DIR="${DOCK_DIR_OVERRIDE}"
fi
if [[ -n "${LIGANDS_DIR_OVERRIDE}" ]]; then
    LIGANDS_DIR="${LIGANDS_DIR_OVERRIDE}"
fi

MODE="$(get_config docking mode "blind")"
if [[ -n "${MODE_OVERRIDE}" ]]; then
    MODE="${MODE_OVERRIDE}"
fi
MODE="${MODE,,}"

if [[ "${MODE}" != "blind" && "${MODE}" != "targeted" && "${MODE}" != "test" ]]; then
    log_error "Invalid docking mode: ${MODE}. Expected one of: blind, targeted, test"
    exit 1
fi

RECEPTOR_DIR="$(get_config docking receptor_dir "${DOCK_DIR}")"
RECEPTOR_PREFIX="$(get_config docking receptor_prefix "rec")"
ENSEMBLE_SIZE="$(get_config receptor ensemble_size "10")"
if [[ -n "${ENSEMBLE_SIZE_OVERRIDE}" ]]; then
    ENSEMBLE_SIZE="${ENSEMBLE_SIZE_OVERRIDE}"
fi

REFERENCE_LIGAND="$(get_config docking reference_ligand "${DOCK_DIR}/ref.pdb")"
TEST_RECEPTOR="$(get_config docking test_receptor "${RECEPTOR_DIR}/${RECEPTOR_PREFIX}.pdb")"

DEFAULT_EXHAUSTIVENESS="100"
DEFAULT_NUM_MODES="32"
DEFAULT_AUTOBOX_ADD="4"
if [[ "${MODE}" == "targeted" || "${MODE}" == "test" ]]; then
    DEFAULT_EXHAUSTIVENESS="64"
    DEFAULT_AUTOBOX_ADD="12"
fi

EXHAUSTIVENESS="$(get_config docking exhaustiveness "${DEFAULT_EXHAUSTIVENESS}")"
NUM_MODES="$(get_config docking num_modes "${DEFAULT_NUM_MODES}")"
AUTOBOX_ADD="$(get_config docking autobox_add "${DEFAULT_AUTOBOX_ADD}")"
AUTOBOX_LIGAND_SETTING="$(get_config docking autobox_ligand "")"
SCORING="$(get_config docking scoring "cnn")"
ADDH="$(get_config docking addH "off")"
STRIPH="$(get_config docking stripH "off")"
CPU="$(get_config docking cpu "8")"
MIN_RMSD_FILTER="$(get_config docking min_rmsd_filter "3")"

SLURM_PARTITION="$(get_config slurm partition "workq")"
SLURM_GPUS="$(get_config slurm gpus "1")"
SLURM_CPUS="$(get_config slurm cpus_per_task "${CPU}")"

if [[ -z "${AUTOBOX_LIGAND_SETTING}" ]]; then
    if [[ "${MODE}" == "blind" ]]; then
        AUTOBOX_LIGAND_SETTING="receptor"
    else
        AUTOBOX_LIGAND_SETTING="${REFERENCE_LIGAND}"
    fi
fi

resolve_path() {
    local value="$1"
    if [[ "$value" == /* ]]; then
        printf '%s\n' "$value"
    else
        printf '%s\n' "${DOCK_DIR}/${value}"
    fi
}

discover_ligands() {
    local explicit="$1"
    local -n _names_ref="$2"
    local -n _mol2_ref="$3"
    local ligand_pattern
    local token path name mol2

    _names_ref=()
    _mol2_ref=()

    if [[ -n "$explicit" ]]; then
        explicit="${explicit//,/ }"
        for token in $explicit; do
            if [[ -f "$token" ]]; then
                name="$(basename "$token" .mol2)"
                _names_ref+=("$name")
                _mol2_ref+=("$(realpath "$token")")
            elif [[ -f "${LIGANDS_DIR}/${token}.mol2" ]]; then
                _names_ref+=("$token")
                _mol2_ref+=("$(realpath "${LIGANDS_DIR}/${token}.mol2")")
            elif [[ -f "${LIGANDS_DIR}/${token}/${token}.mol2" ]]; then
                _names_ref+=("$token")
                _mol2_ref+=("$(realpath "${LIGANDS_DIR}/${token}/${token}.mol2")")
            else
                log_error "Ligand entry not found: ${token}"
                exit 1
            fi
        done
        return
    fi

    ligand_pattern="$(get_config docking ligand_pattern "lig*")"

    shopt -s nullglob
    local dirs=("${LIGANDS_DIR}/${ligand_pattern}")
    shopt -u nullglob

    for path in "${dirs[@]}"; do
        [[ -d "$path" ]] || continue
        name="$(basename "$path")"
        shopt -s nullglob
        local candidates=("${path}"/*.mol2)
        shopt -u nullglob
        if [[ ${#candidates[@]} -eq 0 ]]; then
            continue
        fi
        _names_ref+=("$name")
        _mol2_ref+=("$(realpath "${candidates[0]}")")
    done

    if [[ ${#_names_ref[@]} -eq 0 ]]; then
        shopt -s nullglob
        local mol2s=("${LIGANDS_DIR}"/*.mol2)
        shopt -u nullglob
        for mol2 in "${mol2s[@]}"; do
            name="$(basename "$mol2" .mol2)"
            _names_ref+=("$name")
            _mol2_ref+=("$(realpath "$mol2")")
        done
    fi
}

ligand_list_cfg="$(get_config docking ligand_list "")"
if [[ -n "${LIGAND_LIST_OVERRIDE}" ]]; then
    ligand_list_cfg="${LIGAND_LIST_OVERRIDE}"
fi

declare -a LIGAND_NAMES=()
declare -a LIGAND_MOL2=()
discover_ligands "${ligand_list_cfg}" LIGAND_NAMES LIGAND_MOL2

if [[ ${#LIGAND_NAMES[@]} -eq 0 ]]; then
    log_error "No ligands discovered in ${LIGANDS_DIR}. Provide --ligand-list or configure [docking] ligand_list."
    exit 1
fi

if [[ "${MODE}" == "targeted" || "${MODE}" == "test" ]]; then
    require_file "${REFERENCE_LIGAND}" "Reference ligand for autobox not found: ${REFERENCE_LIGAND}"
fi

if [[ "${MODE}" == "test" ]]; then
    if [[ ! -f "${TEST_RECEPTOR}" ]]; then
        if [[ -f "${RECEPTOR_DIR}/${RECEPTOR_PREFIX}0.pdb" ]]; then
            TEST_RECEPTOR="${RECEPTOR_DIR}/${RECEPTOR_PREFIX}0.pdb"
        fi
    fi
    require_file "${TEST_RECEPTOR}" "Test mode receptor not found: ${TEST_RECEPTOR}"
fi

if [[ "${DRY_RUN}" == "true" ]]; then
    log_info "Mode: ${MODE}"
    log_info "Dock dir: ${DOCK_DIR}"
    log_info "Ligands dir: ${LIGANDS_DIR}"
    log_info "Receptor dir: ${RECEPTOR_DIR}"
    log_info "Ensemble size: ${ENSEMBLE_SIZE}"
    log_info "Exhaustiveness: ${EXHAUSTIVENESS}, num_modes: ${NUM_MODES}, autobox_add: ${AUTOBOX_ADD}"
    for idx in "${!LIGAND_NAMES[@]}"; do
        log_info "Ligand[${idx}]: ${LIGAND_NAMES[$idx]} (${LIGAND_MOL2[$idx]})"
    done
    exit 0
fi

submit_ligand_job() {
    local lig_name="$1"
    local lig_file="$2"
    local lig_dir="$3"
    local lig_workdir receptor_rel ref_rel autobox_token scoring_flag min_rmsd_flag
    local job_name="gnina_${MODE}_${lig_name}"
    local job_id

    if [[ -d "${lig_dir}" ]]; then
        lig_workdir="${lig_dir}"
    else
        lig_workdir="${DOCK_DIR}/${lig_name}"
    fi

    ensure_dir "${lig_workdir}"
    if [[ ! -f "${lig_workdir}/${lig_name}.mol2" ]]; then
        cp -f "${lig_file}" "${lig_workdir}/${lig_name}.mol2"
    fi

    receptor_rel="$(python - <<PY
import os
print(os.path.relpath('${RECEPTOR_DIR}', '${lig_workdir}'))
PY
)"

    ref_rel=""
    if [[ -f "${REFERENCE_LIGAND}" ]]; then
        ref_rel="$(python - <<PY
import os
print(os.path.relpath('${REFERENCE_LIGAND}', '${lig_workdir}'))
PY
)"
    fi

    scoring_flag=""
    if [[ "${SCORING,,}" != "cnn" ]]; then
        scoring_flag="--scoring ${SCORING}"
    fi

    min_rmsd_flag=""
    if [[ -n "${MIN_RMSD_FILTER}" && "${MODE}" != "test" ]]; then
        min_rmsd_flag="--min_rmsd_filter ${MIN_RMSD_FILTER}"
    fi

    job_id="$({
        sbatch --parsable <<EOF
#!/usr/bin/env bash
#SBATCH -J ${job_name}
#SBATCH --gres=gpu:${SLURM_GPUS}
#SBATCH -n 1
#SBATCH -c ${SLURM_CPUS}
#SBATCH -p ${SLURM_PARTITION}

set -euo pipefail

cd "${lig_workdir}"

if [[ "${MODE}" == "test" ]]; then
  gnina -r "${TEST_RECEPTOR}" -l "${lig_name}.mol2" \
    --autobox_ligand "${REFERENCE_LIGAND}" \
    --autobox_add ${AUTOBOX_ADD} \
    --exhaustiveness ${EXHAUSTIVENESS} \
    --num_modes ${NUM_MODES} \
    --addH ${ADDH} --stripH ${STRIPH} \
    --cpu ${CPU} \
    ${scoring_flag} \
    -o "rec-${lig_name}.sdf" \
    --log "rec-${lig_name}.log"
else
  for i in \
$(seq 0 $((ENSEMBLE_SIZE - 1))); do
    receptor_file="${receptor_rel}/${RECEPTOR_PREFIX}\
\${i}.pdb"
    if [[ ! -f "\${receptor_file}" ]]; then
      echo "Missing receptor: \${receptor_file}" >&2
      exit 1
    fi

    if [[ "${AUTOBOX_LIGAND_SETTING}" == "receptor" ]]; then
      autobox_token="\${receptor_file}"
    elif [[ -n "${ref_rel}" ]]; then
      autobox_token="${ref_rel}"
    else
      autobox_token="${AUTOBOX_LIGAND_SETTING}"
    fi

    gnina -r "\${receptor_file}" -l "${lig_name}.mol2" \
      --autobox_ligand "\${autobox_token}" \
      --autobox_add ${AUTOBOX_ADD} \
      --exhaustiveness ${EXHAUSTIVENESS} \
      --num_modes ${NUM_MODES} \
      --addH ${ADDH} --stripH ${STRIPH} \
      --cpu ${CPU} \
      ${min_rmsd_flag} \
      ${scoring_flag} \
      -o "${RECEPTOR_PREFIX}\${i}-${lig_name}.sdf" \
      --log "${RECEPTOR_PREFIX}\${i}-${lig_name}.log"
  done
fi
EOF
    } | tr -d '[:space:]')"

    if [[ -z "${job_id}" ]]; then
        log_error "Failed to parse sbatch job id for ligand ${lig_name}"
        exit 1
    fi

    log_info "Submitted ligand ${lig_name} as Slurm job ${job_id}"
}

log_info "Submitting ${#LIGAND_NAMES[@]} ligand jobs for mode=${MODE}"

for idx in "${!LIGAND_NAMES[@]}"; do
    lig_name="${LIGAND_NAMES[$idx]}"
    lig_file="${LIGAND_MOL2[$idx]}"
    lig_dir="$(dirname "${lig_file}")"
    submit_ligand_job "${lig_name}" "${lig_file}" "${lig_dir}"
done

log_info "All ligand jobs submitted"
