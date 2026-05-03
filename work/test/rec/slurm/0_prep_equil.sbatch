#!/usr/bin/env bash
#SBATCH -J rec_prep
#SBATCH -n 1
#SBATCH -c 8
#SBATCH -p rtx4090-short
#SBATCH --gres=gpu:1

set -euo pipefail
cd "/share/home/nglokwan/autoEnsmblDockMD/work/test/rec"

gmx grompp -v -f em.mdp -c ion.gro -p topol.top -o em.tpr
gmx mdrun -deffnm em -ntomp 8 -ntmpi 1
gmx grompp -v -f pr_pos.mdp -c em.gro -p topol.top -o pr_pos.tpr -r em.gro -maxwarn 3
gmx mdrun -deffnm pr_pos -ntomp 8 -bonded gpu -nb gpu -update gpu -cpi 5 -ntmpi 1
gmx grompp -v -f em.mdp -c pr_pos.gro -p topol.top -o pr_em.tpr -maxwarn 3
gmx mdrun -deffnm pr_em -ntomp 8 -ntmpi 1
