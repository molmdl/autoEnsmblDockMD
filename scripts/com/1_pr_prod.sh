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

escape_sed_replacement() {
    local value="$1"
    value="${value//\\/\\\\}"
    value="${value//|/\\|}"
    value="${value//&/\\&}"
    printf '%s' "${value}"
}

submit_chain_for_trial() {
    local lig_name="$1"
    local lig_dir="$2"
    local trial_idx="$3"
    local eq_job_script prod_job_script
    local eq_job_id prod_job_id
    local stage stage_mdp last_eq_name
    local -a stage_mdps=()
    local s_job_name s_lig_dir s_eq_input_gro s_index_file s_pr0_mdp s_ntomp s_mdp_dir
    local s_last_eq_name s_production_mdp s_stage_mdp s_stage_idx

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

    s_job_name="$(escape_sed_replacement "${lig_name}_eq_${trial_idx}")"
    s_lig_dir="$(escape_sed_replacement "${lig_dir}")"
    s_eq_input_gro="$(escape_sed_replacement "${EQ_INPUT_GRO}")"
    s_index_file="$(escape_sed_replacement "${INDEX_FILE}")"
    s_pr0_mdp="$(escape_sed_replacement "${PR0_MDP}")"
    s_ntomp="$(escape_sed_replacement "${NTOMP}")"
    s_mdp_dir="$(escape_sed_replacement "${MDP_DIR}")"

    cat > "${eq_job_script}" <<'EOF'
#!/usr/bin/env bash
#SBATCH -J __JOB_NAME__
#SBATCH -n 1
#SBATCH -c __NTOMP__
#SBATCH -p __PARTITION__
#SBATCH --gres=gpu:__GPUS__

set -euo pipefail
cd __LIG_DIR__

readonly START_GRO=__EQ_INPUT_GRO__
readonly INDEX_FILE=__INDEX_FILE__
readonly PR0_MDP=__PR0_MDP__
readonly NTOMP=__NTOMP__
readonly MDP_DIR=__MDP_DIR__

gmx grompp -f "${MDP_DIR}/${PR0_MDP}" -c "${START_GRO}" -p sys.top -n "${INDEX_FILE}" -o "pr___TRIAL_IDX__.tpr" -maxwarn 2
gmx mdrun -deffnm "pr___TRIAL_IDX__" -ntmpi 1 -ntomp "${NTOMP}" -bonded gpu -nb gpu -update gpu -pme gpu -cpt 5

last_eq_name="pr___TRIAL_IDX__"
EOF

    sed -i "s|__JOB_NAME__|${s_job_name}|g" "${eq_job_script}"
    sed -i "s|__LIG_DIR__|${s_lig_dir}|g" "${eq_job_script}"
    sed -i "s|__EQ_INPUT_GRO__|${s_eq_input_gro}|g" "${eq_job_script}"
    sed -i "s|__INDEX_FILE__|${s_index_file}|g" "${eq_job_script}"
    sed -i "s|__PR0_MDP__|${s_pr0_mdp}|g" "${eq_job_script}"
    sed -i "s|__NTOMP__|${s_ntomp}|g" "${eq_job_script}"
    sed -i "s|__MDP_DIR__|${s_mdp_dir}|g" "${eq_job_script}"
    sed -i "s|__PARTITION__|$(escape_sed_replacement "${SLURM_PARTITION}")|g" "${eq_job_script}"
    sed -i "s|__GPUS__|$(escape_sed_replacement "${SLURM_GPUS}")|g" "${eq_job_script}"
    sed -i "s|__TRIAL_IDX__|$(escape_sed_replacement "${trial_idx}")|g" "${eq_job_script}"

    for stage in $(seq 1 "${N_EQ_STAGES}"); do
        stage_mdp="${stage_mdps[$((stage - 1))]}"
        s_stage_mdp="$(escape_sed_replacement "${stage_mdp}")"
        s_stage_idx="$(escape_sed_replacement "${stage}")"
        cat >> "${eq_job_script}" <<'EOF'
gmx grompp -f __STAGE_MDP__ -c "${last_eq_name}.gro" -p sys.top -n "${INDEX_FILE}" -o "pr__STAGE_IDX_____TRIAL_IDX__.tpr" -maxwarn 2
gmx mdrun -deffnm "pr__STAGE_IDX_____TRIAL_IDX__" -ntmpi 1 -ntomp "${NTOMP}" -bonded gpu -nb gpu -update gpu -pme gpu -cpt 5
last_eq_name="pr__STAGE_IDX_____TRIAL_IDX__"
EOF
        sed -i "s|__STAGE_MDP__|${s_stage_mdp}|g" "${eq_job_script}"
        sed -i "s|__STAGE_IDX__|${s_stage_idx}|g" "${eq_job_script}"
    done

    chmod +x "${eq_job_script}"
    eq_job_id="$(sbatch --parsable "${eq_job_script}" | tr -d '[:space:]')"
    if [[ -z "${eq_job_id}" ]]; then
        log_error "Failed to submit equilibration job for ${lig_name} trial ${trial_idx}"
        exit 1
    fi

    s_last_eq_name="$(escape_sed_replacement "${last_eq_name}")"
    s_production_mdp="$(escape_sed_replacement "${PRODUCTION_MDP}")"

    cat > "${prod_job_script}" <<'EOF'
#!/usr/bin/env bash
#SBATCH -J __JOB_NAME__
#SBATCH -n 1
#SBATCH -c __NTOMP__
#SBATCH -p __PARTITION__
#SBATCH --gres=gpu:__GPUS__

set -euo pipefail
cd __LIG_DIR__

readonly LAST_EQ_GRO=__LAST_EQ_NAME__.gro
readonly INDEX_FILE=__INDEX_FILE__
readonly PRODUCTION_MDP=__PRODUCTION_MDP__
readonly NTOMP=__NTOMP__
readonly MDP_DIR=__MDP_DIR__

gmx grompp -f "${MDP_DIR}/${PRODUCTION_MDP}" -c "${LAST_EQ_GRO}" -p sys.top -n "${INDEX_FILE}" -o "prod___TRIAL_IDX__.tpr" -maxwarn 2
gmx mdrun -deffnm "prod___TRIAL_IDX__" -ntmpi 1 -ntomp "${NTOMP}" -bonded gpu -nb gpu -update gpu -pme gpu -cpt 5
EOF

    sed -i "s|__JOB_NAME__|$(escape_sed_replacement "${lig_name}_${MD_TIME}_${trial_idx}")|g" "${prod_job_script}"
    sed -i "s|__LIG_DIR__|${s_lig_dir}|g" "${prod_job_script}"
    sed -i "s|__LAST_EQ_NAME__|${s_last_eq_name}|g" "${prod_job_script}"
    sed -i "s|__INDEX_FILE__|${s_index_file}|g" "${prod_job_script}"
    sed -i "s|__PRODUCTION_MDP__|${s_production_mdp}|g" "${prod_job_script}"
    sed -i "s|__NTOMP__|${s_ntomp}|g" "${prod_job_script}"
    sed -i "s|__MDP_DIR__|${s_mdp_dir}|g" "${prod_job_script}"
    sed -i "s|__PARTITION__|$(escape_sed_replacement "${SLURM_PARTITION}")|g" "${prod_job_script}"
    sed -i "s|__GPUS__|$(escape_sed_replacement "${SLURM_GPUS}")|g" "${prod_job_script}"
    sed -i "s|__TRIAL_IDX__|$(escape_sed_replacement "${trial_idx}")|g" "${prod_job_script}"

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
