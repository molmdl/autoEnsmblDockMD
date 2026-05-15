#!/bin/bash
cd lig
ls */*gro | sed s/.gro// > list.txt
for i in `cat list.txt` ; do 
	python ../scripts/dock/gro_itp_to_mol2.py --gro ${i}.gro --itp ${i}_gmx.top --out ${i}.mol2
done

for i in {1..10} ; do
	mkdir -p ../dock_static/lig$i
	cp lig${i}/*.mol2 ../dock_static/lig${i}
done
