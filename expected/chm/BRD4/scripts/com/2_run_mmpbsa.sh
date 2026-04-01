#!/bin/bash

cd com

for ligid in {1..10} ; do
	cd lig$ligid
	bash ../../scripts/com/trj4mmpbsa.sh 
	for i in {0..3} ; do 
		cd mmpbsa_$i 
		sbatch mmpbsa.sh 
		cd .. 
	done
	cd ..
done
