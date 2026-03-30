#!/bin/bash

cd dock

for ligid in `cat ../lig/L99A.txt` ; do
	cd $ligid
	l=`basename *.mol2 .mol2`
	sbatch << EOF
#!/bin/bash
#SBATCH -J gnina_blind
#SBATCH --gres=gpu:1
#SBATCH -n 1
#SBATCH -c 8
#SBATCH -p workq

for i in {0..9} ; do
	echo rec conf \$i
	echo
	gnina -r ../rec\${i}.pdb -l ${l}.mol2 --autobox_ligand ../rec\${i}.pdb --autobox_add 4 --cpu 8 -o rec\${i}-${l}.sdf --log rec\${i}-${l}.log --exhaustiveness 100 --num_modes 100 --min_rmsd_filter 3 --scoring ad4_scoring 2>/dev/null
	echo
done

EOF
	cd ..
done

