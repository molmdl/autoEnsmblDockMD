# Scripts Context - Generalized Ensemble Docking Pipeline

This document lists the generalized scripts needed for both targeted (Mode A) and blind (Mode B) docking workflows.

## Script Naming Convention
- Numeric prefix indicates execution order: `0_`, `1_`, `2_`, etc.
- Core workflow scripts in respective subdirectories: `rec/`, `dock/`, `com/`
- Project-specific utilities in `infra/` (already implemented in Phase 1)

## Receptor Ensemble Generation (scripts/rec/)
Common to both modes:
- `0_prep.sh` - Prepare receptor system and submit equilibration (IMPLEMENTED for blind)
- `1_pr_rec.sh` - Submit parallel receptor MD trials (IMPLEMENTED for blind)
- `3_ana.sh` - Convert trajectories and run analysis (IMPLEMENTED for blind)
- `4_cluster.sh` - Extract diverse conformations via clustering (IMPLEMENTED for blind)

Mode A only:
- `align_structures.py` - Align ensemble to reference ligand complex (GAP)

## Docking Workflow (scripts/dock/)

### Ligand Conversion
Mode B:
- `0_gro2mol2.sh` - Convert CHARMM ligands GRO→MOL2 (IMPLEMENTED)

Mode A:
- `gro_itp_to_mol2.py` - Convert AMBER ligands with bypass_angle_type3.py (GAP)

### Receptor Preparation
- `1_rec4dock.sh` - Copy ensemble conformations to dock directory (IMPLEMENTED for blind)

### Docking Execution
Mode B:
- `2_gnina_blind.sh` - Blind docking across ensemble (IMPLEMENTED)

Mode A:
- `gnina_test.sh` - Reference ligand validation redocking (GAP)
- `gnina_0.sh` - Reference ligand ensemble redocking (GAP)
- `gnina_1.sh` - New ligand ensemble docking batch 1 (GAP)
- `gnina_2.sh` - New ligand ensemble docking batch 2 (GAP)

### Post-Docking Analysis
Mode A/B common:
- `dock_report.sh` - Generate docking scores and rankings (GAP)

### Docking-to-Complex Conversion
Mode B:
- `dock2com_2.2.sh` - Extract ligand ITP, prepare topology with posre (IMPLEMENTED)

Mode A:
- `dock2com_2_ref.sh` - Prepare reference ligand complex topology (GAP)
- `dock2com_2.sh` - Prepare new ligand complex topology (GAP)

Supporting utilities (Mode A):
- `dock2com_1.py` - SDF to GRO conversion helper (GAP)
- `dock2com_2.py` - Topology extraction core logic (GAP)
- `dock2com_2.1.py` - ITP parsing utilities (GAP)
- `dock2com_2.2.1.py` - Position restraint generation (GAP)
- `sdf2gro.sh` - Batch SDF conversion wrapper (GAP)

## Complex MD and MM/PBSA (scripts/com/)

### System Preparation
Mode B:
- `0_prep.sh` - Solvate, ionize, minimize complex (IMPLEMENTED)

Mode A:
- `prep_com.sh` - Initial complex assembly (GAP)
- `prep.sh` - Solvation, ionization, minimization (GAP)

### MD Execution
Mode A/B common:
- `1_pr_prod.sh` or `pr_prod.sh` - Equilibration + production MD (IMPLEMENTED for blind, GAP for unified naming)

### MM/PBSA Calculations
Mode B:
- `2_run_mmpbsa.sh` - Convert trajectories and run MM/PBSA (IMPLEMENTED)

Mode A:
- `sub_mmpbsa.sh` - Submit MM/PBSA job array (GAP)
- `mmpbsa.sh` - MM/PBSA execution wrapper (GAP)
- `trj4mmpbsa.sh` - Trajectory preparation for MM/PBSA (GAP)

### Analysis
Mode A/B common:
- `3_ana.sh` or `ana.sh` - Trajectory analysis and plotting (IMPLEMENTED for blind, GAP for Mode A)

Mode A specific:
- `com_ana_trj.py` - Advanced trajectory analysis (GAP)
- `selection_defaults.py` - Standard selection groups (GAP)

Supporting utilities (Mode A):
- `bypass_angle_type3.py` - AMBER topology angle type fixing (GAP)
- `fp.py` - Fingerprint analysis (GAP)
- `cal_fp.sh` - Calculate fingerprints (GAP)
- `arc_sel.sh` - Archive selection workflow (GAP)
- `rerun_sel.sh` - Rerun selection for failed jobs (GAP)

## Implementation Status Summary

**IMPLEMENTED (Phase 1 - Blind Docking):**
- `scripts/rec/`: 0_prep.sh, 1_pr_rec.sh, 3_ana.sh, 4_cluster.sh (4 scripts)
- `scripts/dock/`: 0_gro2mol2.sh, 1_rec4dock.sh, 2_gnina_blind.sh, dock2com_2.2.sh (4 scripts)
- `scripts/com/`: 0_prep.sh, 1_pr_prod.sh, 2_run_mmpbsa.sh, 3_ana.sh (4 scripts)
- Total: 12 generalized scripts

**GAPS (Mode A - Targeted Docking):**
- `scripts/rec/`: align_structures.py (1 script)
- `scripts/dock/`: gro_itp_to_mol2.py, gnina_test.sh, gnina_0.sh, gnina_1.sh, gnina_2.sh, dock_report.sh, dock2com_2_ref.sh, dock2com_2.sh + 5 supporting utilities (13 scripts)
- `scripts/com/`: prep_com.sh, prep.sh, sub_mmpbsa.sh, mmpbsa.sh, trj4mmpbsa.sh, ana.sh, com_ana_trj.py, selection_defaults.py, bypass_angle_type3.py + 4 supporting utilities (13 scripts)
- Total: 27 gap scripts

**Naming Unification Needed:**
- Receptor scripts already use numeric prefix (0_, 1_, 3_, 4_)
- Complex MD scripts for blind use numeric prefix (0_, 1_, 2_, 3_)
- Mode A scripts need numeric prefix adoption: prep.sh → 0_prep.sh, pr_prod.sh → 1_pr_prod.sh, etc.

## Next Steps
1. Generalize Mode A scripts from expected/amb/scripts/ following blind docking patterns
2. Unify script naming: numeric prefix across both modes
3. Extract mode-specific logic into configuration/flags
4. Document script interfaces and common utilities
