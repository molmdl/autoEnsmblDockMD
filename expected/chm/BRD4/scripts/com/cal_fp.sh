#!/bin/bash

#source ~/scripts/gmxMMPBSA.env 

CWD=`pwd`
GMXEXEC=gmx_mpi

for i in {1..10} ; do
	cd com
	cd lig$i
	mkdir fp
	cd fp
	$GMXEXEC trjcat -f ../mmpbsa_?/com_traj.xtc -o v1.xtc -cat
	cp ../mmpbsa_0/com.tpr .
	echo -e "Protein_Other \n" | $GMXEXEC trjconv -f v1.xtc -s com.tpr -dump 0 -n ../index.ndx -o v1.pdb
	sbatch <<- EOF
#!/bin/bash
#SBATCH --job-name=fp_$i
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH -p cpu
#SBATCH --mem=32GB

source ~/scripts/miniconda_py3.env

export PYTHONPATH="../../../scripts/com:\$PYTHONPATH"

python ../../../scripts/com/fp.py \
  --topology v1.pdb \
  --trajectory v1.xtc \
  --receptor_sel "protein" \
  --ligand_sel "resid 122" 
EOF
	cd $CWD
done
