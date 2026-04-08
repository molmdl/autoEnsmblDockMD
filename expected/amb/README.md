# Reference pocket docking workflow with AMBER/GAFF2 - [PROTEIN_NAME]

Forcefield: AMBER19SB (for Gromacs version < 2025) + GAFF2  
Pocket: Defined by reference ligand  
Workflow: Reference validation + Receptor ensemble + Ensemble docking + Complex MD/MM-PBSA

## Required Inputs

1. Receptor PDB file in `rec/` ([RECEPTOR_PDB_FILE])
2. Reference ligand structure for pocket definition ([REF_LIGAND_NAME])
3. Ligand coordinates (.gro/.mol2) and topology files in `lig/ref/` and `lig/new/`
4. Force field directory `amber19SB_OL21_OL3_lipid17.ff/`

**Note:** GAFF2 atom types must be manually inserted into `ffnonbonded.itp` before workflow execution.

## Workflow

**Stage 0: Reference Ligand Redocking (Validation)**
1. [TBD: Reference redocking protocol]
2. [TBD: Validation criteria - RMSD threshold, scoring]

**Stage 1: Generate Receptor Ensemble**
1. Prepare receptor and submit equilibration job: `bash scripts/rec/prep.sh`
2. Submit 4 parallel trials for [X+Y]ns sampling: `bash scripts/rec/pr_rec.sh`
3. Convert trajectories and run basic analysis: `bash scripts/rec/ana.sh`
4. Perform clustering to extract diverse conformations: `bash scripts/rec/cluster.sh`

**Stage 2: Ensemble Docking with Reference Pocket**
1. Align ensemble structures to reference: [TBD: alignment script]
2. Redock reference ligand to ensemble (validation): [TBD: gnina_ref.sh or equivalent]
3. Dock new ligands to ensemble with reference-defined pocket: [TBD: gnina_ensemble.sh or equivalent]
   - Pocket definition: `--autobox_ligand ref.pdb --autobox_add [X]`
4. [TBD: Pose selection and ranking protocol]

**Stage 3: Run Complex MD and MM/PBSA**
1. Extract best poses and prepare receptor-ligand topology: `bash scripts/dock/dock2com_2.sh`
2. Prepare complex system (solvation, ionization, minimization): `bash scripts/com/prep.sh`
3. Run equilibration and production MD: `bash scripts/com/pr_prod.sh`
4. Submit MM/PBSA calculations: `bash scripts/com/sub_mmpbsa.sh`
5. Run trajectory analysis: [TBD: analysis script]

## Output Structure

- `rec/rec_md/` - Receptor MD trajectories and analysis
- `rec/ensemble/` - Clustered conformations (hsa0-hsa9.pdb/gro)
- `dock/[REF_LIGAND]/` - Reference redocking results and validation
- `dock/[LIGAND_ID]/` - Docking poses (SDF), scores, logs per ligand
- `com_md/[LIGAND_ID]/` - Complex MD trajectories, energy files, MM/PBSA results
- [TBD: com_ana/ for comparative analysis]

## Ligands

Reference ligand: [REF_LIGAND_NAME] ([REF_LIGAND_ID])  
New ligands to evaluate: [LIST_LIGAND_IDS] ([N] ligands)

## Notes

- Ensemble structures require alignment to reference before docking (see `rec/ensemble/README.md`)
- Reference ligand complex in `com_md/[REF]/` contains validated exact scripts
- [TBD: Specific protocols and parameters to be finalized]
