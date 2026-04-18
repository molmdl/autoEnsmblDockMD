#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../infra/common.sh"

SCRIPT_NAME="0_prep"
CONFIG_FILE=""

usage() {
    cat <<'EOF'
Usage: 0_prep.sh [--config FILE] [--help]

Prepare receptor system and submit equilibration steps:
1) pdb2pqr protonation
2) pdb2gmx topology generation
3) box/solvation/ions
4) minimization + restrained equilibration + pre-production minimization (Slurm)

Config sections/keys:
  [receptor]
    workdir, input_pdb, ff, water_model, box_distance, ion_conc, mdp_dir,
    em_mdp, pr_pos_mdp
  [slurm]
    partition, ntomp, gpus
EOF
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
INPUT_PDB="$(get_config receptor input_pdb receptor.pdb)"
FF="$(get_config receptor ff charmm36)"
WATER_MODEL="$(get_config receptor water_model tip3p)"
BOX_DISTANCE="$(get_config receptor box_distance 1.0)"
ION_CONC="$(get_config receptor ion_conc 0.15)"
MDP_DIR="$(get_config receptor mdp_dir "${SCRIPT_DIR}")"
EM_MDP="$(get_config receptor em_mdp em.mdp)"
PR_POS_MDP="$(get_config receptor pr_pos_mdp pr_pos.mdp)"
RECEPTOR_PQR_FF="$(get_config receptor pdb2pqr_ff AMBER)"
RECEPTOR_PH="$(get_config receptor ph 7.4)"

PARTITION="$(get_config slurm partition rtx4090-short)"
NTOMP="$(get_config slurm ntomp 8)"
GPUS="$(get_config slurm gpus 1)"

require_dir "$WORKDIR" "Receptor workdir not found: $WORKDIR"
cd "$WORKDIR"

require_file "$INPUT_PDB" "Input receptor PDB not found: $WORKDIR/$INPUT_PDB"
require_file "${MDP_DIR}/${EM_MDP}" "Missing minimization MDP: ${MDP_DIR}/${EM_MDP}"
require_file "${MDP_DIR}/${PR_POS_MDP}" "Missing position-restraint MDP: ${MDP_DIR}/${PR_POS_MDP}"

cp "${MDP_DIR}/${EM_MDP}" ./em.mdp
cp "${MDP_DIR}/${PR_POS_MDP}" ./pr_pos.mdp

if [[ -d "../${FF}.ff" && ! -e "./${FF}.ff" ]]; then
    ln -s "../${FF}.ff" "./${FF}.ff"
fi

if command -v pdb2pqr30 >/dev/null 2>&1; then
    PDB2PQR_CMD="pdb2pqr30"
elif command -v pdb2pqr >/dev/null 2>&1; then
    PDB2PQR_CMD="pdb2pqr"
else
    log_error "pdb2pqr (or pdb2pqr30) not found in PATH"
    exit 1
fi

log_info "Running pdb2pqr protonation"
"$PDB2PQR_CMD" --ff="$RECEPTOR_PQR_FF" --with-ph="$RECEPTOR_PH" "$INPUT_PDB" receptor_pqr.pdb

run_gmx pdb2gmx -f receptor_pqr.pdb -ignh -o prot.gro --ff "$FF" -water "$WATER_MODEL"
run_gmx editconf -f prot.gro -o box.gro -d "$BOX_DISTANCE" -c -bt dodecahedron
run_gmx solvate -cp box.gro -cs spc216 -p topol.top -o solv.gro
run_gmx grompp -f em.mdp -c solv.gro -p topol.top -o ion.tpr -maxwarn 1
run_gmx genion -s ion.tpr -p topol.top -neutral -conc "$ION_CONC" -nname CL -pname NA -o ion.gro <<< "SOL"

ensure_dir slurm
JOB_SCRIPT="slurm/${SCRIPT_NAME}_equil.sbatch"
cat > "$JOB_SCRIPT" <<EOF
#!/usr/bin/env bash
#SBATCH -J rec_prep
#SBATCH -n 1
#SBATCH -c ${NTOMP}
#SBATCH -p ${PARTITION}
#SBATCH --gres=gpu:${GPUS}

set -euo pipefail
cd "$PWD"

gmx grompp -v -f em.mdp -c ion.gro -p topol.top -o em.tpr
gmx mdrun -deffnm em -ntomp ${NTOMP} -ntmpi 1
gmx grompp -v -f pr_pos.mdp -c em.gro -p topol.top -o pr_pos.tpr -r em.gro -maxwarn 3
gmx mdrun -deffnm pr_pos -ntomp ${NTOMP} -bonded gpu -nb gpu -update gpu -cpi 5 -ntmpi 1
gmx grompp -v -f em.mdp -c pr_pos.gro -p topol.top -o pr_em.tpr -maxwarn 3
gmx mdrun -deffnm pr_em -ntomp ${NTOMP} -ntmpi 1
EOF

chmod +x "$JOB_SCRIPT"
JOB_ID="$(submit_job "$JOB_SCRIPT")"
log_info "Submitted equilibration workflow as Slurm job ${JOB_ID}"
