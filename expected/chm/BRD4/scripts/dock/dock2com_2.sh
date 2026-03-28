#!/bin/bash

CWD=`pwd`

for i in {1..10} ; do 
	cd lig/lig$i
	l=`basename *.mol2 .mol2`
	python ${CWD}/scripts/dock/extract_ligand_itp.py ${l}_gmx.top
	cd $CWD
done

cd dock

for ligid in {1..10} ; do
        cd lig$ligid
        l=`basename *.mol2 .mol2`
	ln -s ../rec?.gro .
	cp ${CWD}/lig/lig${ligid}/${l}_gmx.itp lig.itp
	python ${CWD}/scripts/dock/dock2com_2.py -i lig.itp -s rec?-${l}.sdf -t ${l}.mol2 -r ../../rec/\#topol.top.1\# --ff-path ../../charm36.ff/forcefield.itp --water-itp ../../charmm36.ff/tip3p.itp --ions-itp ../../charmm36.ff/ions.itp --lig-gro best.gro --com-gro com.gro --rec-itp rec.itp --sys-top sys.top  --metric minimizedAffinity
	find . -maxdepth 1 -type l -delete
	mkdir -p ../../com/lig${ligid}
	cp sys.top rec.itp com.gro best.gro lig.itp ../../rec/posre.itp  ../../com/lig${ligid}/
	cd ..
done
