#!/bin/bash
cd rec
cp ../scripts/rec/*.mdp .
ln -s ../charmm36.ff .
gmx pdb2gmx -f ${1}.pdb -ignh -o prot.gro --ff charmm36 -water tip3p
gmx editconf -f prot.gro -o box.gro -d 1 -c -bt dodecahedron #-bt cubic
gmx solvate -cp box.gro -cs spc216 -p topol.top -o solv.gro
gmx grompp -f em.mdp -c solv.gro -p topol.top -o ion.tpr -maxwarn 1
echo SOL | gmx genion -s ion.tpr  -p topol.top  -neutral -conc 0.15 -nname CL -pname NA -o ion.gro

sbatch << EOF
#!/bin/bash
#SBATCH -J prep
#SBATCH -n 1
#SBATCH -c 8
#SBATCH -p rtx4090-short
#SBATCH --gres=gpu:1

gmx grompp -v -f em.mdp -c ion.gro -p topol.top -o em.tpr 
gmx mdrun -deffnm em -ntomp 8 -ntmpi 1 
gmx grompp -v -f pr_pos.mdp -c em.gro -p topol.top -o pr_pos.tpr -r em.gro -maxwarn 3 
gmx mdrun -deffnm pr_pos -ntomp 8 -bonded gpu -nb gpu -update gpu -cpi 5 -ntmpi 1 
gmx grompp -v -f em.mdp -c pr_pos.gro -p topol.top -o pr_em.tpr -maxwarn 3 
gmx mdrun -deffnm pr_em -ntomp 8 -ntmpi 1 
EOF
