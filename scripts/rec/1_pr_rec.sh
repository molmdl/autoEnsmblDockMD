#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../infra/common.sh"

SCRIPT_NAME="1_pr_rec"
CONFIG_FILE=""

usage() {
    cat <<'USAGE'
Usage: 1_pr_rec.sh [--config FILE] [--help]

Submit N parallel receptor production MD trials with Slurm array.

Config sections/keys:
  [receptor]
    workdir, n_trials, mdp_dir, pr0_mdp
  [slurm]
    partition, ntomp, gpus
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --config)
            [[ $# -ge 2 ]] || { log_error "--config requires a file path"; exit 1; }
            CONFIG_FILE="$2"
            shift 2
            ;;
        *)
            log_error "Unknown argument: $1"
            usage
            exit 1
            ;;
    esac
done

init_script "$SCRIPT_NAME" "$CONFIG_FILE"

WORKDIR="$(get_config receptor workdir rec)"
N_TRIALS="$(get_config receptor n_trials 4)"
MDP_DIR="$(get_config receptor mdp_dir "${SCRIPT_DIR}")"
PR0_MDP="$(get_config receptor pr0_mdp pr0.mdp)"

PARTITION="$(get_config slurm partition rtx4090-short)"
NTOMP="$(get_config slurm ntomp 8)"
GPUS="$(get_config slurm gpus 1)"

require_dir "$WORKDIR" "Receptor workdir not found: $WORKDIR"
cd "$WORKDIR"

require_file "pr_em.gro" "Required input missing: pr_em.gro (run 0_prep.sh first)"
require_file "topol.top" "Required topology missing: topol.top"
require_file "${MDP_DIR}/${PR0_MDP}" "Missing production MDP: ${MDP_DIR}/${PR0_MDP}"

cp "${MDP_DIR}/${PR0_MDP}" ./pr0.mdp

if [[ "$N_TRIALS" -lt 1 ]]; then
    log_error "n_trials must be >= 1 (got: ${N_TRIALS})"
    exit 1
fi

ensure_dir slurm
JOB_SCRIPT="slurm/${SCRIPT_NAME}.sbatch"
ARRAY_END=$((N_TRIALS - 1))

cat > "$JOB_SCRIPT" <<SBATCH
#!/usr/bin/env bash
#SBATCH --job-name=rec_pr
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=${NTOMP}
#SBATCH --gres=gpu:${GPUS}
#SBATCH -p ${PARTITION}
#SBATCH --array=0-${ARRAY_END}

set -euo pipefail
cd "$PWD"

trial="\${SLURM_ARRAY_TASK_ID}"

gmx grompp -v -f pr0.mdp -c pr_em.gro -p topol.top -o "pr_\${trial}.tpr" -maxwarn 3
gmx mdrun -deffnm "pr_\${trial}" -ntomp ${NTOMP} -bonded gpu -nb gpu -update gpu -cpi 5 -ntmpi 1
SBATCH

chmod +x "$JOB_SCRIPT"
JOB_ID="$(submit_job "$JOB_SCRIPT")"
log_info "Submitted receptor production array job ${JOB_ID} with ${N_TRIALS} trials"
