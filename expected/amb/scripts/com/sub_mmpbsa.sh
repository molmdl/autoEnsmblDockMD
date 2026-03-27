bash ../../scripts/com/trj4mmpbsa.sh 
for i in {0..3} ; do cd mmpbsa_$i ; sbatch mmpbsa.sh ; cd .. ; done
