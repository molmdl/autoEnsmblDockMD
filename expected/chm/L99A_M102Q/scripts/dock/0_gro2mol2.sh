#!/bin/bash

#cd lig
#ls */*gro | sed s/.gro// > list.txt
#for i in `cat list.txt` ; do 
#	python ../scripts/dock/gro_itp_to_mol2.py --gro ${i}.gro --itp ${i}_gmx.top --out ${i}.mol2
#done

for i in `cat lig/L99A.txt` ; do
	mkdir ../dock/$i
	cp ${i}/*.mol2 ../dock/${i}
done
