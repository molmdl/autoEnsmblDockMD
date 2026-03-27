#!/bin/bash

cd rec
for i in {0..3} ; do

	sbatch << EOF
#!/bin/bash
#SBATCH --job-name=rec_pr_$i
#SBATCH --nodes=1            
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=22
#SBATCH --gres=gpu:1
#SBATCH -p rtx4090-short
##SBATCH -p rtx4090
##SBATCH -p workq

## Now try to minimize and do some pre-equilibration of the system
gmx grompp -v -f pr0.mdp -c pr_em.gro -p topol.top -o pr_${i}.tpr -maxwarn 3
gmx mdrun -deffnm pr_${i} -ntomp 22 -bonded gpu -nb gpu -update gpu -cpi 5 -ntmpi 1 

echo
echo date
EOF

done
