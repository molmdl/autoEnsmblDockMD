#!/bin/bash

#cd phe_sssL
#ln -s ../hsa?.pdb_ali.gro .
#cp ../../solv_md/phe_sssL_sap/lig_g.itp .
#python ../../scripts/dock/dock2com_2.py -i lig_g.itp -s hsa*-phe.sdf -t phe.mol2 -r ../../rec/\#topol.top.1\# --ff-path ../../amber19SB_OL21_OL3_lipid17.ff/forcefield.itp --water-itp ../../amber19SB_OL21_OL3_lipid17.ff/opc3.itp --ions-itp ../../amber19SB_OL21_OL3_lipid17.ff/ions.itp --lig-gro best.gro --com-gro com.gro --rec-itp rec.itp --sys-top sys.top --metric sasa
#rm hsa?.pdb_ali.gro
#
#mkdir ../../com_md/phe_sssL_sap/
#cp sys.top rec.itp com.gro best.gro lig_g.itp ../../rec/posre.itp ../../com_md/phe_sssL_sap/
#
#cd ..
#
#cd phe_sssD
#ln -s ../hsa?.pdb_ali.gro .
#cp ../../solv_md/phe_sssD_sap_frmInvert/lig_g.itp .
#python ../../scripts/dock/dock2com_2.py -i lig_g.itp -s hsa*-phe_sssD.sdf -t phe_sssD.mol2 -r ../../rec/\#topol.top.1\# --ff-path ../../amber19SB_OL21_OL3_lipid17.ff/forcefield.itp --water-itp ../../amber19SB_OL21_OL3_lipid17.ff/opc3.itp --ions-itp ../../amber19SB_OL21_OL3_lipid17.ff/ions.itp --lig-gro best.gro --com-gro com.gro --rec-itp rec.itp --sys-top sys.top  --metric sasa 
#rm hsa?.pdb_ali.gro
#
#mkdir ../../com_md/phe_sssD_sap/
#cp sys.top rec.itp com.gro best.gro lig_g.itp ../../rec/posre.itp  ../../com_md/phe_sssD_sap/
#
#cd ..
#
#cd phe_rrrL
#ln -s ../hsa?.pdb_ali.gro .
#cp ../../solv_md/phe_rrrL_sap/lig_g.itp .
#python ../../scripts/dock/dock2com_2.py -i lig_g.itp -s hsa*-phe_rrrL.sdf -t phe_rrrL.mol2 -r ../../rec/\#topol.top.1\# --ff-path ../../amber19SB_OL21_OL3_lipid17.ff/forcefield.itp --water-itp ../../amber19SB_OL21_OL3_lipid17.ff/opc3.itp --ions-itp ../../amber19SB_OL21_OL3_lipid17.ff/ions.itp --lig-gro best.gro --com-gro com.gro --rec-itp rec.itp --sys-top sys.top  --metric sasa 
#rm hsa?.pdb_ali.gro
#
#mkdir ../../com_md/phe_rrrL_sap/
#cp sys.top rec.itp com.gro best.gro lig_g.itp ../../rec/posre.itp  ../../com_md/phe_rrrL_sap/
#
#cd ..

cd me_sssL
ln -s ../hsa?.pdb_ali.gro .
cp ../../solv_md/me_sssL_sap/lig_me_g.itp .
python ../../scripts/dock/dock2com_2.py -i lig_me_g.itp -s hsa*-me.sdf -t me.mol2 -r ../../rec/\#topol.top.1\# --ff-path ../../amber19SB_OL21_OL3_lipid17.ff/forcefield.itp --water-itp ../../amber19SB_OL21_OL3_lipid17.ff/opc3.itp --ions-itp ../../amber19SB_OL21_OL3_lipid17.ff/ions.itp --lig-gro best.gro --com-gro com.gro --rec-itp rec.itp --sys-top sys.top --metric sasa
rm hsa?.pdb_ali.gro

mkdir ../../com_md/me_sssL_sap/
cp sys.top rec.itp com.gro best.gro lig_me_g.itp ../../rec/posre.itp ../../com_md/me_sssL_sap/

cd ..

cd me_sssD
ln -s ../hsa?.pdb_ali.gro .
cp ../../solv_md/me_sssD_sap_frmInvert/lig_me_g.itp .
python ../../scripts/dock/dock2com_2.py -i lig_me_g.itp -s hsa*-me_sssD.sdf -t me_sssD.mol2 -r ../../rec/\#topol.top.1\# --ff-path ../../amber19SB_OL21_OL3_lipid17.ff/forcefield.itp --water-itp ../../amber19SB_OL21_OL3_lipid17.ff/opc3.itp --ions-itp ../../amber19SB_OL21_OL3_lipid17.ff/ions.itp --lig-gro best.gro --com-gro com.gro --rec-itp rec.itp --sys-top sys.top  --metric sasa 
rm hsa?.pdb_ali.gro

mkdir ../../com_md/me_sssD_sap/
cp sys.top rec.itp com.gro best.gro lig_me_g.itp ../../rec/posre.itp  ../../com_md/me_sssD_sap/

cd ..

cd me_rrrL
ln -s ../hsa?.pdb_ali.gro .
cp ../../solv_md/me_rrrL_sap/lig_me_g.itp .
python ../../scripts/dock/dock2com_2.py -i lig_me_g.itp -s hsa*-me_rrrL.sdf -t me_rrrL.mol2 -r ../../rec/\#topol.top.1\# --ff-path ../../amber19SB_OL21_OL3_lipid17.ff/forcefield.itp --water-itp ../../amber19SB_OL21_OL3_lipid17.ff/opc3.itp --ions-itp ../../amber19SB_OL21_OL3_lipid17.ff/ions.itp --lig-gro best.gro --com-gro com.gro --rec-itp rec.itp --sys-top sys.top  --metric sasa 
rm hsa?.pdb_ali.gro

mkdir ../../com_md/me_rrrL_sap/
cp sys.top rec.itp com.gro best.gro lig_me_g.itp ../../rec/posre.itp  ../../com_md/me_rrrL_sap/

cd ..

