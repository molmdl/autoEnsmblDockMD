---
phase: quick-002
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - expected/amb/README.md
  - WORKFLOW.md
  - scripts/CONTEXT.md
autonomous: true

must_haves:
  truths:
    - "expected/amb/README.md has no TBD placeholders, references actual scripts"
    - "WORKFLOW.md Mode A documents complete targeted docking workflow"
    - "scripts/CONTEXT.md lists all generalized scripts needed for both modes"
  artifacts:
    - path: "expected/amb/README.md"
      provides: "Complete targeted docking workflow documentation with actual script names"
      min_lines: 60
    - path: "WORKFLOW.md"
      provides: "Mode A targeted docking workflow (parallel to Mode B blind docking)"
      contains: "Stage 0: Reference Ligand Redocking"
    - path: "scripts/CONTEXT.md"
      provides: "Inventory of generalized scripts needed"
      contains: "rec/0_prep.sh"
  key_links:
    - from: "expected/amb/README.md"
      to: "WORKFLOW.md Mode A"
      via: "workflow structure alignment"
      pattern: "Stage [0-3]:"
    - from: "scripts/CONTEXT.md"
      to: "expected/amb/scripts/"
      via: "script inventory mapping"
      pattern: "[0-9]_.*\\.sh"
---

<objective>
Finalize the targeted site docking workflow documentation by updating placeholders with actual scripts, documenting Mode A workflow, and creating an inventory of generalized scripts needed.

Purpose: Complete WORKFLOW.md documentation so agents know the full targeted docking protocol and script requirements.

Output: Updated documentation files ready for script generalization phase.
</objective>

<execution_context>
@~/.config/opencode/get-shit-done/workflows/execute-plan.md
@~/.config/opencode/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@WORKFLOW.md
@expected/amb/README.md
@expected/amb/scripts/
@AGENTS.md
</context>

<tasks>

<task type="auto">
  <name>Update expected/amb/README.md with actual script references</name>
  <files>expected/amb/README.md</files>
  <action>
Replace all [TBD: ...] placeholders in expected/amb/README.md with actual script names and protocols based on expected/amb/scripts/:

**Stage 0: Reference Ligand Redocking (Validation)**
- Script: `bash scripts/dock/gnina_test.sh` (uses --autobox_ligand ref.pdb)
- Validation criteria: RMSD < 2.0 Å from crystal structure, CNN score threshold

**Stage 1: Generate Receptor Ensemble**
- Already documented with correct script names (prep.sh, pr_rec.sh, ana.sh, cluster.sh)
- Keep as-is

**Stage 2: Ensemble Docking**
- Line 29: Replace "[TBD: alignment script]" with "`python scripts/rec/align_structures.py`"
- Line 30: Replace "[TBD: gnina_ref.sh or equivalent]" with "`bash scripts/dock/gnina_0.sh` (reference validation)"
- Line 31: Replace "[TBD: gnina_ensemble.sh or equivalent]" with "`bash scripts/dock/gnina_1.sh` and `bash scripts/dock/gnina_2.sh` (ensemble docking)"
- Line 34: Replace "[TBD: Pose selection and ranking protocol]" with "`bash scripts/dock/dock_report.sh` (scoring and ranking)"

**Stage 3: Complex MD**
- Line 36: Keep `dock2com_2.sh` but add reference variant: "Use `dock2com_2_ref.sh` for reference ligand, `dock2com_2.sh` for new ligands"
- Line 40: Replace "[TBD: analysis script]" with "`bash scripts/com/ana.sh`"

**Output Structure section:**
- Line 49: Replace "[TBD: com_ana/ for comparative analysis]" with "com_ana/ - Comparative analysis across ligands"

**Notes section:**
- Line 58: Replace "[TBD: Specific protocols and parameters to be finalized]" with:
  - "AMBER topology requires bypass_angle_type3.py for proper angle handling"
  - "Ligand format conversion via gro_itp_to_mol2.py before docking"
  - "MM/PBSA analysis via sub_mmpbsa.sh with trajectory preparation"
  </action>
  <verify>
grep -c "TBD" expected/amb/README.md returns 0
grep "gnina_test.sh" expected/amb/README.md
grep "align_structures.py" expected/amb/README.md
  </verify>
  <done>expected/amb/README.md contains no TBD placeholders, all scripts referenced with actual names from expected/amb/scripts/</done>
</task>

<task type="auto">
  <name>Document Mode A in WORKFLOW.md</name>
  <files>WORKFLOW.md</files>
  <action>
Replace the placeholder content in WORKFLOW.md lines 39-48 (Mode A section) with complete targeted docking workflow:

```markdown
### Mode A. Reference Pocket Docking
Targeted docking workflow using AMBER19SB/GAFF2 force field with pocket defined by reference ligand.

**Required Inputs:**
1. Receptor PDB file in `rec/` directory (processed with pdb2pqr)
2. Reference ligand structure (PDB) for pocket definition and validation
3. Reference ligand coordinates (.gro) and topology files in `lig/ref/`
4. New ligand coordinates (.gro) and topology files in `lig/new/LIGAND_ID/` directories
5. Force field directory `amber19SB_OL21_OL3_lipid17.ff/`
6. GAFF2 atom types manually inserted into `ffnonbonded.itp`
7. Ligand bonded parameters `.itp` files from ACPYPE or equivalent

**Directory Structure:**
- `rec/` - Receptor ensemble generation workspace
- `lig/ref/` - Reference ligand input files
- `lig/new/` - New ligands to evaluate organized by ligand ID
- `dock/` - Docking runs and results (ref validation + new ligands)
- `com_md/` - Complex MD simulations and MM/PBSA calculations
- `com_ana/` - Comparative analysis across ligands
- `scripts/rec/` - Receptor ensemble generation scripts
- `scripts/dock/` - Docking workflow scripts (gnina + conversion)
- `scripts/com/` - Complex MD and analysis scripts

**Workflow Stages:**

**Stage 0: Reference Ligand Redocking (Validation)**
1. Convert receptor to Gromacs format: `pdb2pqr` then `gmx pdb2gmx`
2. Validate reference ligand redocking: `bash scripts/dock/gnina_test.sh`
   - Uses `--autobox_ligand ref.pdb --autobox_add 8` for pocket definition
   - Validation: RMSD < 2.0 Å from crystal structure
3. Verify GAFF2 parameters in `ffnonbonded.itp`

**Stage 1: Generate Receptor Ensemble**
1. Prepare input and submit equilibration job: `bash scripts/rec/prep.sh`
2. Submit 4 parallel trials for equilibration + production sampling: `bash scripts/rec/pr_rec.sh`
3. Convert trajectories and run basic analysis: `bash scripts/rec/ana.sh`
4. Perform clustering to extract diverse conformations: `bash scripts/rec/cluster.sh`
5. Align ensemble structures to reference: `python scripts/rec/align_structures.py`
   - Critical for maintaining pocket geometry across ensemble

**Stage 2: Ensemble Docking with Reference Pocket**
1. Convert ligands from GRO to MOL2 format: `python scripts/dock/gro_itp_to_mol2.py`
   - AMBER-specific: Uses bypass_angle_type3.py internally
2. Redock reference ligand to ensemble (validation): `bash scripts/dock/gnina_0.sh`
   - Confirms pocket definition generalizes across ensemble
3. Dock new ligands to ensemble with reference-defined pocket: 
   - `bash scripts/dock/gnina_1.sh` and `bash scripts/dock/gnina_2.sh`
   - Pocket: `--autobox_ligand ref.pdb --autobox_add 8`
4. Generate docking reports and rankings: `bash scripts/dock/dock_report.sh`

**Stage 3: Run Complex MD and MM/PBSA**
1. Extract ligand topology and prepare receptor-ligand complex:
   - Reference ligand: `bash scripts/dock/dock2com_2_ref.sh`
   - New ligands: `bash scripts/dock/dock2com_2.sh`
   - Applies bypass_angle_type3.py for AMBER topology compatibility
2. Prepare complex system (solvation, ionization, minimization): `bash scripts/com/prep_com.sh` then `bash scripts/com/prep.sh`
3. Run equilibration and production MD: `bash scripts/com/pr_prod.sh`
4. Prepare trajectories and submit MM/PBSA calculations: `bash scripts/com/sub_mmpbsa.sh`
5. Run trajectory analysis and plot results: `bash scripts/com/ana.sh`

**Output Structure:**
- `rec/rec_md/` - Receptor MD trajectories and analysis
- `rec/ensemble/` - Clustered conformations (hsa0-hsa9.pdb/gro), aligned to reference
- `dock/REF_LIGAND/` - Reference redocking validation results
- `dock/LIGAND_ID/` - Docking poses (SDF), scores, logs per ligand
- `com_md/LIGAND_ID/` - Complex MD trajectories, energy files, MM/PBSA results
- `com_ana/` - Cross-ligand comparison plots and per-ligand analysis

**Key Differences from Blind Docking (Mode B):**
1. Pocket definition via `--autobox_ligand ref.pdb` instead of whole protein
2. Reference redocking validation stage (Stage 0)
3. Ensemble alignment required via `align_structures.py`
4. AMBER force field requires GAFF2 manual insertion in `ffnonbonded.itp`
5. AMBER topology processing via `bypass_angle_type3.py`
6. Ligand conversion via `gro_itp_to_mol2.py` (not generic gro2mol2.sh)
7. Ligand organization: `lig/ref/` and `lig/new/` instead of flat `lig/LIGAND_ID/`
```
  </action>
  <verify>
grep "Stage 0: Reference Ligand Redocking" WORKFLOW.md
grep "align_structures.py" WORKFLOW.md
grep "Key Differences from Blind Docking" WORKFLOW.md
  </verify>
  <done>WORKFLOW.md Mode A section fully documents targeted docking workflow parallel to Mode B, with all stages and script names</done>
</task>

<task type="auto">
  <name>Create scripts/CONTEXT.md listing generalized scripts needed</name>
  <files>scripts/CONTEXT.md</files>
  <action>
Create scripts/CONTEXT.md documenting the generalized scripts needed for both workflow modes based on the documented workflows and expected/amb/ + prior blind docking analysis.

Structure:
```markdown
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
```
  </action>
  <verify>
ls scripts/CONTEXT.md
grep "27 gap scripts" scripts/CONTEXT.md
grep "align_structures.py" scripts/CONTEXT.md
grep "IMPLEMENTED (Phase 1" scripts/CONTEXT.md
  </verify>
  <done>scripts/CONTEXT.md created, listing all generalized scripts with implementation status and gaps identified</done>
</task>

</tasks>

<verification>
1. No TBD placeholders remain in expected/amb/README.md
2. WORKFLOW.md Mode A section is complete and parallel to Mode B
3. scripts/CONTEXT.md exists with complete script inventory
4. All three files reference consistent script names
</verification>

<success_criteria>
- expected/amb/README.md fully updated with actual script references from expected/amb/scripts/
- WORKFLOW.md Mode A documents complete 4-stage targeted docking workflow
- scripts/CONTEXT.md provides complete inventory: 12 implemented (Phase 1), 27 gaps (Mode A)
- Documentation ready for script generalization phase
</success_criteria>

<output>
After completion, create `.planning/quick/002-finalize-targeted-docking-workflow-amber-ff/002-SUMMARY.md`
</output>
