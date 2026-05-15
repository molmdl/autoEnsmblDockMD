#!/bin/bash

cd dock_static

for ligid in {1..10} ; do
	cd lig$ligid
	l=`basename *.mol2 .mol2`
	sbatch << EOF
#!/bin/bash
#SBATCH -J gnina_blind
#SBATCH --gres=gpu:1
#SBATCH -n 1
#SBATCH -c 8
#SBATCH -p workq

gnina -r ../${1}.pdb -l ${l}.mol2 --autobox_ligand ../${1}.pdb --autobox_add 4 --cpu 8 -o ${1}-${l}.sdf --log ${1}-${l}.log --exhaustiveness 100 --num_modes 100 --min_rmsd_filter 3 --scoring ad4_scoring 2>/dev/null
EOF
	cd ..
done

