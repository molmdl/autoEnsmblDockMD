# Docking-only workflow with CHARMM36m - Lysozyme L99A/M102Q

Forcefield: CHARMM36m  
Pocket: Whole protein (blind docking)  
Workflow: Receptor ensemble generation + Docking only (no complex MD/MM-PBSA)

## Required Inputs

1. Receptor PDB file in `rec/` (3huk_pras.pdb)
2. Ligand MOL2 files in `lig/LIGAND_ID/` directories (symlinked from `../L99A/lig/`)
3. Force field directory `charmm36.ff/` (symlinked from `../L99A/charmm36.ff/`)

**Note:** Docking-only workflow requires only MOL2 files for ligands. No topology (.top), coordinates (.gro), or bonded parameter (.itp) files needed.

## Workflow

**Stage 1: Generate Receptor Ensemble**
1. Prepare input and submit equilibration job: `bash scripts/rec/0_prep.sh`
2. Submit 4 parallel trials for 10+50ns sampling: `bash scripts/rec/1_pr_rec.sh`
3. Convert trajectories and run basic analysis: `bash scripts/rec/3_ana.sh`
4. Perform clustering to extract diverse conformations: `bash scripts/rec/4_cluster.sh`

**Stage 2: Run Blind Docking**
1. Convert ligands from GRO to MOL2 format (if needed): `bash scripts/dock/0_gro2mol2.sh`
2. Copy receptor ensemble conformations to docking directory: `bash scripts/dock/1_rec4dock.sh`
3. Submit gnina blind docking jobs to Slurm: `bash scripts/dock/2_gnina_blind.sh`

**Stage 3: Complex MD and MM/PBSA** - Not performed in docking-only workflow

## Output Structure

- `rec/` - Receptor trajectories, analysis, and clustered conformations (rec0-rec9.gro)
- `dock/LIGAND_ID/` - Docking poses (SDF), scores, logs per ligand

## Ligands

M102Q variant: 1LI2, 1XEP, 3HU8, 3HUK, 3HTF, 2RBN, 3HUA (7 ligands)  
L99A variant: See `../L99A/` (shared ligand directory - both variants use same lig inputs)
