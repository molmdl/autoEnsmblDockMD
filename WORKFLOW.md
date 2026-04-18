> TO BE FINALIZED, do not proceed to plan or work of related stages with this banner

# WORKFLOW.md contains information on the full workflow of autoEnsmblDockMD

The workflow takes the following provided by the user: 
- receptor structure PDB, 
- reference ligand for pocket definition and validation (coordinates and topology), 
- ligands to be evaluated (coordinates and topology), 
- the customised forcefield that include ligand parameters
- gromacs run input mdp
- optionally configuration parameters for docking.

Provided the workspace with input files, the agent should be aware of the modes of workflow, which directory to enter, which file to detect, which script to execute, which analysis to do.


## Modes
A. Reference pocket docking
B. Blind docking


## Major stages
- remind or help user to place the required input
- remind user to do manual ff preparation
- optional pdb2pqr for missing atoms
- standard workflow
- default analysis
- tailored analysis

---

## On-demand stages
- checker agent
- debugger agent

---

## Complete Workflow

### Mode A. Reference Pocket Docking
1. process receptor with pdb2pqr
2. gaff2 atomtypes already inserted manually into the amberff ffnonbonded.itp by the user. files in expected is also the example of using amber forcefield
3. reference redock
4. interested lig dock
5. en ensemble, cluster, select, align
6. intermediate analysis step
7. ensemble docking, from all ensemble out select best rec-lig combination
8. conversion and setup for md
9. using slurm for hpc, and run local option

### Mode B. Blind docking
Blind docking workflow using CHARMM36m/CGenFF force field with whole protein as binding pocket.

**Required Inputs:**
1. Receptor PDB file in `rec/` directory
2. Ligand coordinates (.gro) and topology (.top) files in `lig/LIGAND_ID/` directories
3. Force field directory `charmm36.ff/` from CGenFF server
4. Ligand bonded parameters `LIGAND_NAME_ffbonded.itp` from CGenFF server (place in same directory as ligand)

**Directory Structure:**
- `rec/` - Receptor ensemble generation workspace
- `lig/` - Ligand input files organized by ligand ID
- `dock/` - Docking runs and results
- `com/` - Complex MD simulations and MM/PBSA calculations
- `com_ana/` - Comparative analysis across ligands
- `scripts/rec/` - Receptor ensemble generation scripts
- `scripts/dock/` - Docking workflow scripts
- `scripts/com/` - Complex MD and analysis scripts

**Workflow Stages:**

**Stage 1: Generate Receptor Ensemble**
1. Prepare input and submit equilibration job: `bash scripts/rec/0_prep.sh`
2. Submit 4 parallel trials for 10+50ns sampling: `bash scripts/rec/1_pr_rec.sh`
3. Convert trajectories and run basic analysis: `bash scripts/rec/3_ana.sh`
4. Perform clustering to extract diverse conformations: `bash scripts/rec/4_cluster.sh`

**Stage 2: Run Blind Docking**
1. Convert ligands from GRO to MOL2 format: `bash scripts/dock/0_gro2mol2.sh`
2. Copy receptor ensemble conformations to docking directory: `bash scripts/dock/1_rec4dock.sh`
3. Submit gnina blind docking jobs to Slurm: `bash scripts/dock/2_gnina_blind.sh`

**Stage 3: Run Complex MD and MM/PBSA**
1. Extract ligand ITP and prepare receptor-ligand topology:
   - Run `bash scripts/dock/dock2com_2.2.sh`
   - Generates `posre_lig.itp` (heavy atom position restraints)
   - Ligand ITP references `posre_lig.itp` via `#ifdef POSRES`
   - Use `define = -DPOSRES` in MDP file to restrain both receptor and ligand
2. Prepare complex system (solvation, ionization, minimization): `bash scripts/com/0_prep.sh`
3. Run unrestrained equilibration and production MD: `bash scripts/com/1_pr_prod.sh`
4. Convert trajectories and submit MM/PBSA calculations: `bash scripts/com/2_run_mmpbsa.sh`
5. Run trajectory analysis and plot results: `bash scripts/com/3_ana.sh`

**Output Structure:**
- `rec/` - Receptor trajectories, analysis, and clustered conformations
- `dock/LIGAND_ID/` - Docking poses (SDF), scores, logs per ligand
- `com/LIGAND_ID/` - Complex MD trajectories, energy files, MM/PBSA subdirectories
- `com_ana/` - Cross-ligand comparison plots and per-ligand analysis

**Docking-only workflow (no Complex MD/MM-PBSA):**

Simplified workflow that stops after ensemble docking without proceeding to complex MD simulations and MM/PBSA calculations. Used for rapid screening when binding free energy calculations are not required.

**Required Inputs:**
1. Receptor PDB file in `rec/` directory
2. Ligand MOL2 files in `lig/LIGAND_ID/` directories
3. Force field directory `charmm36.ff/` (for receptor ensemble generation only)

**Note:** Ligands only need MOL2 format. No topology (.top), coordinates (.gro), or bonded parameter (.itp) files required.

**Workflow Stages:**
- **Stage 1: Generate Receptor Ensemble** (same as full workflow)
- **Stage 2: Run Blind Docking** (same as full workflow)
- **Stage 3: Complex MD and MM/PBSA** - SKIPPED

**Output Structure:**
- `rec/` - Receptor trajectories, analysis, and clustered conformations (rec0-rec9.gro)
- `dock/LIGAND_ID/` - Docking poses (SDF), scores, logs per ligand

**Omitted from full workflow:**
- No `com/` or `com_ana/` directories
- No `scripts/com/` scripts
- No complex topology files or bonded parameters for ligands

---

## Helper agents

**checker agent**
- checking plans would meet requirements
- checking results validity

**debugger agent**
- systematic diagnosis of issues in simulation
- inspect and fix issues in analysis scripts
