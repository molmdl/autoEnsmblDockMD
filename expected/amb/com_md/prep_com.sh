#!/bin/bash

#for i in phe_sssD_sap phe_sssL_sap phe_rrrL_sap ; do 
for i in me_sssD_sap me_sssL_sap me_rrrL_sap ; do 
	cp ../scripts/com/*mdp $i 
	cd $i
	sbatch ../../scripts/com/prep.sh
	cd ..
done
