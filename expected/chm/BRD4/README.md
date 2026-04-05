# blind docking protocol with CHERMM36m/CGenFF

Forcefield: charmm36m + CGenFF
Pocket: whole protein

## Required inputs: 
1. receptor pdb in rec/ (BRD4)
2. ligand top and gro, placed in corresponding lig/ligid directory
3. charmm36.ff from CGenFF server
4. charmm36.ff/LIGANDNAME_ffbonded.itp from CGenFF server copied into the same directory as the ligand.

##$ Workflow
cd this directory

**Generate Receptor ensemble**
1. prepare input and submit to slurm for equilibration: bash scripts/rec/0_prep.sh
2. after above job is done, submit the 4 trials 10+50ns sampling: bash scripts/rec/1_pr_rec.sh
3. after the 4 trials are done, do trjconv and basic analysis: bash scripts/rec/3_ana.sh
4. after trjconv and basic analysis, clustering to get diverse conf: scripts/rec/4_cluster.sh

**Run Blind Docking**
1. copy ligands to docking dir: bash scripts/dock/0_gro2mol2.sh
2. copy receptor to docking dir: bash scripts/dock/1_rec4dock.sh
3. submit all jobs to slurm: bash scripts/dock/2_gnina_blind.sh

**Run Complex MD and MM/PBSA**
1. extract ligand itp from top and extract top rec+lig pair for gromacs simulation: bash scripts/dock/dock2com_2.2.sh
   - This also generates posre_lig.itp (heavy atom position restraints for ligand)
   - Ligand ITP references posre_lig.itp under #ifdef POSRES
   - Use define = -DPOSRES in MDP to restrain both receptor and ligand
2. run system preparation: bash scripts/com/0_prep.sh
3. run unrestained equilibration and production MD: bash scripts/com/1_pr_prod.sh
4. run trjconv and submit mmpbsa: bash scripts/com/2_run_mmpbsa.sh
5. Run standard trajectory anaylsis on the trajectory in the mmpbsa dir, and plotting both mmpbsa results and trj analysis results: bash scripts/com/3_ana.sh

