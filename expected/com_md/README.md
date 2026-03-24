# Contents in this directory

## ibp
reference ligand ibp related files, use exact scripts in it. Order of execution:
(0. copying related files from receptor preparation, ligand preparation, docking output to here)
1. `bash dock2com.sh`
2. `bash prep.sh`
3. `sbatch pr.sh`
4. `sbatch prod.sh`

## dzp
files of reference ligand dzp simulation, 

## lig
this is actually dzp selected from ensemble docking results

## amber19SB_OL21_OL3_lipid17.ff
symbolic link to ff directory

