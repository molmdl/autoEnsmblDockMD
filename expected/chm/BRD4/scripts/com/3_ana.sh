#!/bin/bash

for i in {1..10} ; do 
	cat <<-EOF > com/lig${i}/trials.txt
	mmpbsa_0
	mmpbsa_1
	mmpbsa_2
	mmpbsa_3
EOF
done

sbatch <<-EOL
#!/bin/bash
#SBATCH -J ana_mmpbsa
#SBATCH -n 1
#SBATCH -c 1
#SBATCH -p cpu

python scripts/com/com_ana_trj.py --workspace com --output-dir ./com_ana

EOL
