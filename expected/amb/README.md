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
1. Run reference redocking validation: `bash scripts/dock/gnina_test.sh` (uses `--autobox_ligand ref.pdb --autobox_add 8`)
2. Validation criteria: RMSD < 2.0 Å from crystal structure and acceptable CNN score threshold

**Stage 1: Generate Receptor Ensemble**
1. Prepare receptor and submit equilibration job: `bash scripts/rec/prep.sh`
2. Submit 4 parallel trials for [X+Y]ns sampling: `bash scripts/rec/pr_rec.sh`
3. Convert trajectories and run basic analysis: `bash scripts/rec/ana.sh`
4. Perform clustering to extract diverse conformations: `bash scripts/rec/cluster.sh`

**Stage 2: Ensemble Docking with Reference Pocket**
1. Align ensemble structures to reference: `python scripts/rec/align_structures.py`
2. Redock reference ligand to ensemble (validation): `bash scripts/dock/gnina_0.sh` (reference validation)
3. Dock new ligands to ensemble with reference-defined pocket: `bash scripts/dock/gnina_1.sh` and `bash scripts/dock/gnina_2.sh` (ensemble docking)
   - Pocket definition: `--autobox_ligand ref.pdb --autobox_add [X]`
4. Pose selection and ranking: `bash scripts/dock/dock_report.sh` (scoring and ranking)

**Stage 3: Run Complex MD and MM/PBSA**
1. Extract best poses and prepare receptor-ligand topology: use `bash scripts/dock/dock2com_2_ref.sh` for reference ligand and `bash scripts/dock/dock2com_2.sh` for new ligands
2. Prepare complex system (solvation, ionization, minimization): `bash scripts/com/prep.sh`
3. Run equilibration and production MD: `bash scripts/com/pr_prod.sh`
4. Submit MM/PBSA calculations: `bash scripts/com/sub_mmpbsa.sh`
5. Run trajectory analysis: `bash scripts/com/ana.sh`

## Output Structure

- `rec/rec_md/` - Receptor MD trajectories and analysis
- `rec/ensemble/` - Clustered conformations (hsa0-hsa9.pdb/gro)
- `dock/[REF_LIGAND]/` - Reference redocking results and validation
- `dock/[LIGAND_ID]/` - Docking poses (SDF), scores, logs per ligand
- `com_md/[LIGAND_ID]/` - Complex MD trajectories, energy files, MM/PBSA results
- `com_ana/` - Comparative analysis across ligands

## Ligands

Reference ligand: [REF_LIGAND_NAME] ([REF_LIGAND_ID])  
New ligands to evaluate: [LIST_LIGAND_IDS] ([N] ligands)

## Notes

- Ensemble structures require alignment to reference before docking (see `rec/ensemble/README.md`)
- Reference ligand complex in `com_md/[REF]/` contains validated exact scripts
- AMBER topology requires `scripts/com/bypass_angle_type3.py` for proper angle handling
- Ligand format conversion via `scripts/dock/gro_itp_to_mol2.py` before docking
- MM/PBSA analysis via `bash scripts/com/sub_mmpbsa.sh` with trajectory preparation
