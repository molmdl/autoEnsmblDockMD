#!/bin/bash

CWD=`pwd`

#for i in {1..10} ; do 
#	cd lig/lig$i
#	l=`basename *.mol2 .mol2`
#	python ${CWD}/scripts/dock/extract_ligand_itp.py ${l}_gmx.top
#	cd $CWD
#done
#
cd dock

for ligid in {1..10} ; do
        cd lig$ligid
        l=`basename *.mol2 .mol2`
#	ln -s ../rec?.gro .
#	cp ${CWD}/lig/lig${ligid}/${l}_gmx.itp lig.itp
	
	ffbonded_src="${CWD}/lig/lig${ligid}/${l}_ffbonded.itp"
	ffbonded_arg=""
#	if [ -f "$ffbonded_src" ]; then
#		cp "$ffbonded_src" .
#		ffbonded_arg="--lig-ffbonded ${l}_ffbonded.itp"
#		echo "Found ffbonded.itp: $ffbonded_src"
#	fi
	
	python ${CWD}/scripts/dock/dock2com_2.2.1.py -i lig.itp -s rec?-${l}.sdf -t ${l}.mol2 --rec-gro-pattern {prefix}.gro $ffbonded_arg --list-models | grep -v '\-\-\-\-' > lig${ligid}_dock.csv
	
#	find . -maxdepth 1 -type l -delete
#	mkdir -p ../../com/lig${ligid}
#	cp sys.top rec.itp com.gro best.gro lig.itp posre_lig.itp ../../rec/posre.itp ../../com/lig${ligid}/
#	
#	if [ -f "lig_ffbonded.itp" ]; then
#		cp lig_ffbonded.itp ../../com/lig${ligid}/
#	fi
	
	cd ..
done
