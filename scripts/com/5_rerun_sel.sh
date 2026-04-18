#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../infra/common.sh"

SCRIPT_NAME="5_rerun_sel"
CONFIG_FILE=""
LIGAND_OVERRIDE=""
STAGE_OVERRIDE=""

usage() {
    cat <<'EOF'
Usage: 5_rerun_sel.sh [--config FILE] [--stage prep|prod|mmpbsa] [--ligand NAME|PATH] [--help]

Identify incomplete outputs and submit reruns for selected stage.

Options:
  --config FILE          INI config file
  --stage STAGE          Stage to check/resubmit (prep|prod|mmpbsa)
  --ligand NAME|PATH     Limit to specific ligand(s), comma-separated
  -h, --help             Show this help and exit

Config keys used:
  [general]
    workdir
  [complex]
    workdir
    ligand_pattern
  [rerun]
    workdir
    ligand_dir
    ligand_pattern
    ligand_list
    stage
    expected_prep
    expected_prod
    expected_mmpbsa
    prep_script
    prod_script
    mmpbsa_script
    partition
    cpus_per_task
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --config)
            [[ $# -ge 2 ]] || { log_error "--config requires a file path"; exit 1; }
            CONFIG_FILE="$2"
            shift 2
            ;;
        --stage)
            [[ $# -ge 2 ]] || { log_error "--stage requires a value"; exit 1; }
            STAGE_OVERRIDE="$2"
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
RERUN_WORKDIR="$(get_config rerun workdir "${COMPLEX_WORKDIR}")"
LIGAND_DIR="$(get_config rerun ligand_dir "${RERUN_WORKDIR}")"
LIGAND_PATTERN="$(get_config rerun ligand_pattern "$(get_config complex ligand_pattern "lig*")")"
LIGAND_LIST_CFG="$(get_config rerun ligand_list "")"

STAGE="$(get_config rerun stage "prod")"
if [[ -n "${STAGE_OVERRIDE}" ]]; then
    STAGE="${STAGE_OVERRIDE}"
fi
STAGE="${STAGE,,}"

EXPECTED_PREP="$(get_config rerun expected_prep "pr_pos.gro,sys.top,index.ndx")"
EXPECTED_PROD="$(get_config rerun expected_prod "prod_0.xtc,prod_0.tpr")"
EXPECTED_MMPBSA="$(get_config rerun expected_mmpbsa "mmpbsa_0/FINAL_RESULTS_MMPBSA.dat")"

PREP_SCRIPT="$(get_config rerun prep_script "${SCRIPT_DIR}/0_prep.sh")"
PROD_SCRIPT="$(get_config rerun prod_script "${SCRIPT_DIR}/1_pr_prod.sh")"
MMPBSA_SCRIPT="$(get_config rerun mmpbsa_script "${SCRIPT_DIR}/2_sub_mmpbsa.sh")"

SLURM_PARTITION="$(get_config rerun partition "$(get_config slurm partition "cpu")")"
SLURM_CPUS="$(get_config rerun cpus_per_task "4")"

require_dir "${LIGAND_DIR}" "Rerun ligand directory not found: ${LIGAND_DIR}"

case "${STAGE}" in
    prep|prod|mmpbsa)
        ;;
    *)
        log_error "Invalid stage '${STAGE}'. Use prep|prod|mmpbsa"
        exit 1
        ;;
esac

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

expected_patterns_for_stage() {
    case "$1" in
        prep) printf '%s\n' "${EXPECTED_PREP}" ;;
        prod) printf '%s\n' "${EXPECTED_PROD}" ;;
        mmpbsa) printf '%s\n' "${EXPECTED_MMPBSA}" ;;
    esac
}

script_for_stage() {
    case "$1" in
        prep) printf '%s\n' "${PREP_SCRIPT}" ;;
        prod) printf '%s\n' "${PROD_SCRIPT}" ;;
        mmpbsa) printf '%s\n' "${MMPBSA_SCRIPT}" ;;
    esac
}

is_ligand_complete_for_stage() {
    local lig_path="$1"
    local stage="$2"
    local raw token

    raw="$(expected_patterns_for_stage "${stage}")"
    raw="${raw//,/ }"
    for token in ${raw}; do
        shopt -s nullglob
        local matches=("${lig_path}"/${token})
        shopt -u nullglob
        if [[ ${#matches[@]} -eq 0 ]]; then
            return 1
        fi
    done
    return 0
}

submit_rerun() {
    local lig_path="$1"
    local lig_name="$2"
    local stage="$3"
    local worker_script job_id

    worker_script="$(script_for_stage "${stage}")"
    require_file "${worker_script}" "Missing rerun script for stage ${stage}: ${worker_script}"

    job_id="$({
        sbatch --parsable <<EOF
#!/usr/bin/env bash
#SBATCH -J rerun_${stage}_${lig_name}
#SBATCH -n 1
#SBATCH -c ${SLURM_CPUS}
#SBATCH -p ${SLURM_PARTITION}

set -euo pipefail

bash "${worker_script}" --config "${CONFIG_FILE}" --ligand "${lig_path}"
EOF
    } | tr -d '[:space:]')"

    if [[ -z "${job_id}" ]]; then
        log_error "Failed to submit rerun for ${lig_name} (${stage})"
        exit 1
    fi
    log_info "Submitted rerun job ${job_id} for ${lig_name} (${stage})"
}

declare -a TARGETS=()
discover_ligands "${LIGAND_LIST_CFG}" TARGETS

if [[ ${#TARGETS[@]} -eq 0 ]]; then
    log_error "No ligand directories discovered under ${LIGAND_DIR} (pattern: ${LIGAND_PATTERN})"
    exit 1
fi

rerun_count=0
for lig_path in "${TARGETS[@]}"; do
    lig_name="$(basename "${lig_path}")"
    if is_ligand_complete_for_stage "${lig_path}" "${STAGE}"; then
        log_info "${lig_name}: stage ${STAGE} appears complete"
        continue
    fi

    log_warn "${lig_name}: missing expected outputs for stage ${STAGE}; submitting rerun"
    submit_rerun "${lig_path}" "${lig_name}" "${STAGE}"
    rerun_count=$((rerun_count + 1))
done

if [[ ${rerun_count} -eq 0 ]]; then
    log_info "No reruns needed for stage ${STAGE}"
else
    log_info "Submitted ${rerun_count} rerun job(s) for stage ${STAGE}"
fi
