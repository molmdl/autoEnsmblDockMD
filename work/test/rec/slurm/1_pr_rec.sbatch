#!/usr/bin/env bash
#SBATCH --job-name=rec_pr
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --gres=gpu:1
#SBATCH -p rtx4090-short
#SBATCH --array=0-3

set -euo pipefail
cd "/share/home/nglokwan/autoEnsmblDockMD/work/test/rec"

trial="${SLURM_ARRAY_TASK_ID}"

gmx grompp -v -f pr0.mdp -c pr_em.gro -p topol.top -o "pr_${trial}.tpr" -maxwarn 3
gmx mdrun -deffnm "pr_${trial}" -ntomp 8 -bonded gpu -nb gpu -update gpu -cpi 5 -ntmpi 1
