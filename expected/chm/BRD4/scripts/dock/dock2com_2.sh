#!/bin/bash

cd dock

for ligid in {1..10} ; do
        cd lig$ligid
        l=`basename *.mol2 .mol2`
	ln -s ../rec?.gro .
	cp ../../lig${ligid}/${l}_gmx.top lig.itp
	python ../../scripts/dock/dock2com_2.py -i lig.itp -s hsa*-phe_sssD.sdf -t ${l}.mol2 -r ../../rec/\#topol.top.1\# --ff-path ../../charm36.ff/forcefield.itp --water-itp ../../charmm36.ff/tip3p.itp --ions-itp ../../charmm36.ff/ions.itp --lig-gro best.gro --com-gro com.gro --rec-itp rec.itp --sys-top sys.top  --metric minimizedAffinity
	find . -maxdepth 1 -type l -delete
	mkdir -p ../../com/lig${ligid}
	cp sys.top rec.itp com.gro best.gro lig.itp ../../rec/posre.itp  ../../com/lig${ligid}/
	cd ..
done
