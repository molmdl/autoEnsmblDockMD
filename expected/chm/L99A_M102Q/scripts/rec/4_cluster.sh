cd rec
#echo 1 1 | gmx cluster -method gromos -f ./apo_50ns_merged_fit.xtc -s ./pr_0.tpr -rmsmin 0.1 -cutoff 0.2 -sz -clid -cl clusters.xtc
echo 1 1 | gmx cluster -method gromos -f ./apo_50ns_merged_fit.xtc -s ./pr_0.tpr -rmsmin 0.1 -cutoff 0.15 -sz -clid -cl clusters.xtc
echo 1 | gmx trjconv -s ./pr_0.tpr -f clusters.xtc -sep -pbc mol -o rec.gro
for i in {0..9} ; do
	gmx editconf -f rec${i}.gro -o rec${i}.pdb
done

