#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../infra/common.sh"

SCRIPT_NAME="1_pr_prod"
CONFIG_FILE=""
LIGAND_OVERRIDE=""

usage() {
    cat <<'EOF'
Usage: 1_pr_prod.sh [--config FILE] [--ligand NAME|PATH] [--help]

Submit equilibration + production MD for complex systems.

Pipeline per ligand and trial:
1) Position-restrained equilibration chain (pr0 -> pr1..prN)
2) Production MD (prod)

Production job is submitted with Slurm dependency after equilibration succeeds.

Options:
  --config FILE          INI config file
  --ligand NAME|PATH     Run one ligand only
  -h, --help             Show this help and exit

Config keys used:
  [general]
    workdir
  [complex]
    workdir
    ligand_pattern
    ligand_list
    ff
  [production]
    workdir
    ligand_dir
    ligand_pattern
    ligand_list
    n_trials
    n_equilibration_stages
    equil_input_gro
    index_file
    mdp_dir
    pr0_mdp
    pr_mdp_prefix
    production_mdp
    md_time
    ntomp
    partition
    gpus
  [slurm]
    partition
    ntomp
    gpus
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
PROD_WORKDIR="$(get_config production workdir "${COMPLEX_WORKDIR}")"
LIGAND_DIR="$(get_config production ligand_dir "${PROD_WORKDIR}")"
COMPLEX_LIGAND_PATTERN_DEFAULT="$(get_config complex ligand_pattern "lig*")"
COMPLEX_LIGAND_LIST_DEFAULT="$(get_config complex ligand_list "")"
SLURM_NTOMP_DEFAULT="$(get_config slurm ntomp "8")"
SLURM_PARTITION_DEFAULT="$(get_config slurm partition "rtx4090")"
SLURM_GPUS_DEFAULT="$(get_config slurm gpus "1")"
LIGAND_PATTERN="$(get_config production ligand_pattern "${COMPLEX_LIGAND_PATTERN_DEFAULT}")"
LIGAND_LIST_CFG="$(get_config production ligand_list "${COMPLEX_LIGAND_LIST_DEFAULT}")"

N_TRIALS="$(get_config production n_trials "4")"
N_EQ_STAGES="$(get_config production n_equilibration_stages "1")"
EQ_INPUT_GRO="$(get_config production equil_input_gro "pr_pos.gro")"
INDEX_FILE="$(get_config production index_file "index.ndx")"

MDP_DIR="$(get_config production mdp_dir "${SCRIPT_DIR}")"
PR0_MDP="$(get_config production pr0_mdp "pr0.mdp")"
PR_MDP_PREFIX="$(get_config production pr_mdp_prefix "pr")"
PRODUCTION_MDP="$(get_config production production_mdp "md.mdp")"

MD_TIME="$(get_config production md_time "100ns")"
NTOMP="$(get_config production ntomp "${SLURM_NTOMP_DEFAULT}")"
SLURM_PARTITION="$(get_config production partition "${SLURM_PARTITION_DEFAULT}")"
SLURM_GPUS="$(get_config production gpus "${SLURM_GPUS_DEFAULT}")"

FF_NAME="$(get_config complex ff "")"

require_dir "${LIGAND_DIR}" "Ligand complex directory not found: ${LIGAND_DIR}"
require_dir "${MDP_DIR}" "MDP directory not found: ${MDP_DIR}"
require_file "${MDP_DIR}/${PR0_MDP}" "Missing pr0 MDP file: ${MDP_DIR}/${PR0_MDP}"
require_file "${MDP_DIR}/${PRODUCTION_MDP}" "Missing production MDP file: ${MDP_DIR}/${PRODUCTION_MDP}"

if ! [[ "${N_TRIALS}" =~ ^[0-9]+$ ]] || [[ "${N_TRIALS}" -le 0 ]]; then
    log_error "Invalid [production] n_trials='${N_TRIALS}'"
    exit 1
fi

if ! [[ "${N_EQ_STAGES}" =~ ^[0-9]+$ ]] || [[ "${N_EQ_STAGES}" -lt 0 ]]; then
    log_error "Invalid [production] n_equilibration_stages='${N_EQ_STAGES}'"
    exit 1
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

resolve_equil_mdp() {
    local stage="$1"
    local candidate="${MDP_DIR}/${PR_MDP_PREFIX}${stage}.mdp"
    local fallback="${MDP_DIR}/${PR_MDP_PREFIX}.mdp"

    if [[ -f "${candidate}" ]]; then
        printf '%s\n' "${candidate}"
        return 0
    fi
    if [[ -f "${fallback}" ]]; then
        printf '%s\n' "${fallback}"
        return 0
    fi

    log_error "Missing equilibration MDP for stage ${stage}: ${candidate} (or fallback ${fallback})"
    return 1
}

require_safe_id() {
    local value="$1"
    local label="$2"
    if [[ ! "${value}" =~ ^[A-Za-z0-9._-]+$ ]]; then
        log_error "Invalid ${label} '${value}'. Allowed characters: A-Z a-z 0-9 . _ -"
        exit 1
    fi
}

require_uint() {
    local value="$1"
    local label="$2"
    if [[ ! "${value}" =~ ^[0-9]+$ ]]; then
        log_error "Invalid ${label}='${value}'. Expected non-negative integer."
        exit 1
    fi
}

require_safe_partition() {
    local value="$1"
    if [[ ! "${value}" =~ ^[A-Za-z0-9._,-]+$ ]]; then
        log_error "Invalid slurm partition='${value}'."
        exit 1
    fi
}

submit_chain_for_trial() {
    local lig_name="$1"
    local lig_dir="$2"
    local trial_idx="$3"
    local eq_job_script prod_job_script
    local eq_job_id prod_job_id
    local stage stage_mdp last_eq_name
    local -a stage_mdps=()
    local q_lig_dir q_eq_input_gro q_index_file q_pr0_mdp q_ntomp q_mdp_dir
    local q_last_eq_name q_production_mdp q_stage_mdp

    eq_job_script="${lig_dir}/pr_equil_${trial_idx}.sbatch"
    prod_job_script="${lig_dir}/prod_${trial_idx}.sbatch"

    require_safe_id "${lig_name}" "ligand id"
    require_uint "${trial_idx}" "trial index"
    require_uint "${NTOMP}" "production ntomp"
    require_uint "${SLURM_GPUS}" "production gpus"
    require_safe_partition "${SLURM_PARTITION}"

    last_eq_name="pr_${trial_idx}"
    for stage in $(seq 1 "${N_EQ_STAGES}"); do
        stage_mdp="$(resolve_equil_mdp "${stage}")"
        stage_mdps+=("${stage_mdp}")
        last_eq_name="pr${stage}_${trial_idx}"
    done

    printf -v q_lig_dir '%q' "${lig_dir}"
    printf -v q_eq_input_gro '%q' "${EQ_INPUT_GRO}"
    printf -v q_index_file '%q' "${INDEX_FILE}"
    printf -v q_pr0_mdp '%q' "${PR0_MDP}"
    printf -v q_ntomp '%q' "${NTOMP}"
    printf -v q_mdp_dir '%q' "${MDP_DIR}"
    printf -v q_last_eq_name '%q' "${last_eq_name}"
    printf -v q_production_mdp '%q' "${PRODUCTION_MDP}"

    cat > "${eq_job_script}" <<EOF
#!/usr/bin/env bash
#SBATCH -J ${lig_name}_eq_${trial_idx}
#SBATCH -n 1
#SBATCH -c ${NTOMP}
#SBATCH -p ${SLURM_PARTITION}
#SBATCH --gres=gpu:${SLURM_GPUS}

set -euo pipefail
cd ${q_lig_dir}

readonly START_GRO=${q_eq_input_gro}
readonly INDEX_FILE=${q_index_file}
readonly PR0_MDP=${q_pr0_mdp}
readonly NTOMP=${q_ntomp}
readonly MDP_DIR=${q_mdp_dir}

gmx grompp -f "\${MDP_DIR}/\${PR0_MDP}" -c "\${START_GRO}" -p sys.top -n "\${INDEX_FILE}" -o "pr_${trial_idx}.tpr" -maxwarn 2
gmx mdrun -deffnm "pr_${trial_idx}" -ntmpi 1 -ntomp "\${NTOMP}" -bonded gpu -nb gpu -update gpu -pme gpu -cpt 5

last_eq_name="pr_${trial_idx}"
EOF

    for stage in $(seq 1 "${N_EQ_STAGES}"); do
        stage_mdp="${stage_mdps[$((stage - 1))]}"
        printf -v q_stage_mdp '%q' "${stage_mdp}"
        cat >> "${eq_job_script}" <<EOF
gmx grompp -f ${q_stage_mdp} -c "\${last_eq_name}.gro" -p sys.top -n "\${INDEX_FILE}" -o "pr${stage}_${trial_idx}.tpr" -maxwarn 2
gmx mdrun -deffnm "pr${stage}_${trial_idx}" -ntmpi 1 -ntomp "\${NTOMP}" -bonded gpu -nb gpu -update gpu -pme gpu -cpt 5
last_eq_name="pr${stage}_${trial_idx}"
EOF
    done

    chmod +x "${eq_job_script}"
    eq_job_id="$(sbatch --parsable "${eq_job_script}" | tr -d '[:space:]')"
    if [[ -z "${eq_job_id}" ]]; then
        log_error "Failed to submit equilibration job for ${lig_name} trial ${trial_idx}"
        exit 1
    fi

    cat > "${prod_job_script}" <<EOF
#!/usr/bin/env bash
#SBATCH -J ${lig_name}_${MD_TIME}_${trial_idx}
#SBATCH -n 1
#SBATCH -c ${NTOMP}
#SBATCH -p ${SLURM_PARTITION}
#SBATCH --gres=gpu:${SLURM_GPUS}

set -euo pipefail
cd ${q_lig_dir}

readonly LAST_EQ_GRO=${q_last_eq_name}.gro
readonly INDEX_FILE=${q_index_file}
readonly PRODUCTION_MDP=${q_production_mdp}
readonly NTOMP=${q_ntomp}
readonly MDP_DIR=${q_mdp_dir}

gmx grompp -f "\${MDP_DIR}/\${PRODUCTION_MDP}" -c "\${LAST_EQ_GRO}" -p sys.top -n "\${INDEX_FILE}" -o "prod_${trial_idx}.tpr" -maxwarn 2
gmx mdrun -deffnm "prod_${trial_idx}" -ntmpi 1 -ntomp "\${NTOMP}" -bonded gpu -nb gpu -update gpu -pme gpu -cpt 5
EOF

    chmod +x "${prod_job_script}"
    prod_job_id="$(sbatch --parsable --dependency="afterok:${eq_job_id}" "${prod_job_script}" | tr -d '[:space:]')"
    if [[ -z "${prod_job_id}" ]]; then
        log_error "Failed to submit production job for ${lig_name} trial ${trial_idx}"
        exit 1
    fi

    log_info "${lig_name} trial ${trial_idx}: equil=${eq_job_id}, prod=${prod_job_id}"
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

log_info "Submitting production workflow for ${#TARGETS[@]} ligand(s); trials=${N_TRIALS}, equil_stages=${N_EQ_STAGES}"

for lig_path in "${TARGETS[@]}"; do
    lig_name="$(basename "${lig_path}")"
    require_file "${lig_path}/sys.top" "Missing system topology for ${lig_name}: ${lig_path}/sys.top"
    require_file "${lig_path}/${EQ_INPUT_GRO}" "Missing equilibration input for ${lig_name}: ${lig_path}/${EQ_INPUT_GRO}"
    require_file "${lig_path}/${INDEX_FILE}" "Missing index file for ${lig_name}: ${lig_path}/${INDEX_FILE}"

    for trial in $(seq 0 $((N_TRIALS - 1))); do
        submit_chain_for_trial "${lig_name}" "${lig_path}" "${trial}"
    done
done

log_info "Production MD submission complete"
