#!/bin/bash

#for l in phe_sssD_sap phe_sssL_sap phe_rrrL_sap ; do 
for l in me_sssD_sap me_sssL_sap me_rrrL_sap ; do 
	cd $l
	#cp ../../scripts/com/*mdp .
	bash ../../scripts/com/pr_prod.sh $l
	cd ..
done
