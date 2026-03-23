> TO BE FINALIZED, do not proceed to plan or work of related stages with this banner

# WORKFLOW.md - autoEnsmblDockMD Workflow

This document defines the complete workflow for ensemble docking with MD-based rescoring.
Each stage specifies: working directory, input detection, script execution, and analysis.

---

## Input Files Required (User Provided)

| Category | Files | Location |
|----------|-------|----------|
| **Receptor** | `{RECEPTOR}.pdb` | `work/input/rec/raw/` |
| **Reference Ligand** | `{REF_LIG}.pdb`, `{REF_LIG}.itp`, `{REF_LIG}.gro` | `work/input/lig/ref/` |
| **Target Ligands** | `{LIG_N}.pdb`, `{LIG_N}.itp`, `{LIG_N}.gro` | `work/input/lig/new/` |
| **Force Field** | Custom FF files (`*.itp`, `*.ff/`) | `work/input/ff/` |
| **MD Parameters** | `*.mdp` files (em, nvt, npt, prod) | `work/input/mdp/` |
| **Docking Config** | `gnina.cfg` (optional) | `work/input/dock/` |

---

## Agent Responsibilities

This workflow is designed for agent-assisted execution. Agents reference this document and AGENTS.md for guidance.

### Agent Types (from AGENTS.md)

| Agent | Role | Workflow Stages |
|-------|------|-----------------|
| **Orchestrator** | Manages overall workflow state, handles checkpoints, spawns other agents | All stages (coordination) |
| **Runner** | Executes stage scripts, handles parameters | Stages 0-9 (execution) |
| **Analyzer** | Runs standard analysis (RMSD, contacts, plots), custom analysis | Stages 2-3, 7-9 (analysis) |
| **Checker** | Validates results, generates warnings/suggestions | On-demand after each stage |
| **Debugger** | Diagnoses failures, follows GSD workflow | On-demand when failures occur |

### Notes for Agents

**Safety Constraints:**
- **No `rm` commands except in test directories** — report any deletion and seek explicit approval
- **Never require sudo permission** — all operations within conda environment
- **Source `./scripts/setenv.sh` before operations** — ensures environment is loaded
- **Conda environment only** — do not modify system-wide Python installations
- **Report task summaries** — write to md files for session continuity

**Operational Guidelines:**
- Primary testing location: `work/test/` directory
- User-provided inputs: `./work/input/`
- Reference outputs: `./expected/` (same structure as work/input)
- Maintain backward compatibility with core workflows
- Prefer configuration-driven approach over hardcoded values
- Preserve multi-job manager support in shell scripts
- Ensure I/O format and code style consistency across conversations

**Agent Support Status:** Experimental — agent automation is secondary to validated human workflow.

---

## Stage 0: Input Validation & Setup

**Requirements:** CHECK-01 (stage checkpoints), CHECK-02 (human verification), EXEC-01 (local execution)

**Purpose:** Verify all required inputs exist and are properly formatted.

**Working Directory:** `{WORKSPACE}/`

**Prerequisites:**
- Source environment: `source ./scripts/setenv.sh`

**Input Detection:**
```bash
# Check receptor
[ -f work/input/rec/raw/{RECEPTOR}.pdb ] || echo "ERROR: Missing receptor PDB"

# Check reference ligand
[ -f work/input/lig/ref/{REF_LIG}.pdb ] || echo "ERROR: Missing ref ligand PDB"
[ -f work/input/lig/ref/{REF_LIG}.itp ] || echo "ERROR: Missing ref ligand ITP"
[ -f work/input/lig/ref/{REF_LIG}.gro ] || echo "ERROR: Missing ref ligand GRO"

# Check target ligands (one or more)
for lig in work/input/lig/new/*.pdb; do [ -f "$lig" ] || echo "ERROR: No target ligands"; done

# Check force field
[ -d work/input/ff/ ] || echo "ERROR: Missing force field directory"

# Check MDP files
[ -f work/input/mdp/em.mdp ] || echo "ERROR: Missing em.mdp"
[ -f work/input/mdp/nvt.mdp ] || echo "ERROR: Missing nvt.mdp"
[ -f work/input/mdp/npt.mdp ] || echo "ERROR: Missing npt.mdp"
[ -f work/input/mdp/prod.mdp ] || echo "ERROR: Missing prod.mdp"
```

**Script Execution:**
```bash
# Placeholder - script to be provided
# python scripts/validate_input.py --workspace {WORKSPACE} --config {CONFIG}
```

**Output Verification:**
- `[ ] All input files present`
- `[ ] File formats valid`
- `[ ] Topology files compatible`

**Next:** Proceed to Stage 1 only if all validations pass.

---

## Stage 1: Receptor Preparation

**Requirements:** SCRIPT-01 (receptor scripts), CHECK-01 (stage checkpoints), EXEC-01 (local execution)

**Purpose:** Process receptor structure for docking and MD.

**Working Directory:** `cd {WORKSPACE}/rec/`

**Input Detection:**
```bash
[ -f work/input/rec/raw/{RECEPTOR}.pdb ]
```

**Script Execution:**
```bash
# Step 1.1: Clean receptor
# SCRIPT: scripts/rec_clean.sh | scripts/rec_clean.py
# INPUT: work/input/rec/raw/{RECEPTOR}.pdb
# OUTPUT: {WORKSPACE}/rec/cleaned/{RECEPTOR}_clean.pdb

# Step 1.2: Add hydrogens
# SCRIPT: scripts/rec_addH.sh | scripts/rec_addH.py
# INPUT: {WORKSPACE}/rec/cleaned/{RECEPTOR}_clean.pdb
# OUTPUT: {WORKSPACE}/rec/prepared/{RECEPTOR}_H.pdb

# Step 1.3: Generate topology
# SCRIPT: scripts/rec_topol.sh | scripts/rec_topol.py
# INPUT: {WORKSPACE}/rec/prepared/{RECEPTOR}_H.pdb
# OUTPUT: {WORKSPACE}/rec/topology/{RECEPTOR}.top, {RECEPTOR}.gro
```

**Analysis:**
- Verify protein structure completeness
- Check hydrogen addition success
- Validate topology generation

**Output Verification:**
```bash
[ -f {WORKSPACE}/rec/prepared/{RECEPTOR}_H.pdb ]
[ -f {WORKSPACE}/rec/topology/{RECEPTOR}.top ]
[ -f {WORKSPACE}/rec/topology/{RECEPTOR}.gro ]
```

**Checkpoint:** Human verifies receptor preparation before ensemble generation.

---

## Stage 2: Ensemble Generation (MD-based Conformer Sampling)

**Requirements:** SCRIPT-01 (receptor scripts), CHECK-01 (stage checkpoints), EXEC-01 (local execution)

**Purpose:** Generate structural ensemble for docking flexibility.

**Working Directory:** `cd {WORKSPACE}/rec/ensemble/`

**Input Detection:**
```bash
[ -f {WORKSPACE}/rec/topology/{RECEPTOR}.gro ]
[ -f {WORKSPACE}/rec/topology/{RECEPTOR}.top ]
[ -f work/input/mdp/em.mdp ]
[ -f work/input/mdp/nvt.mdp ]
[ -f work/input/mdp/npt.mdp ]
[ -f work/input/mdp/prod.mdp ]
```

**Script Execution:**
```bash
# Step 2.1: Energy minimization
# SCRIPT: scripts/md_em.sh | scripts/md_em.py
# INPUT: {WORKSPACE}/rec/topology/{RECEPTOR}.gro, {RECEPTOR}.top, em.mdp
# OUTPUT: {WORKSPACE}/rec/ensemble/em/{RECEPTOR}_em.gro, {RECEPTOR}_em.log

# Step 2.2: NVT equilibration
# SCRIPT: scripts/md_nvt.sh | scripts/md_nvt.py
# INPUT: {WORKSPACE}/rec/ensemble/em/{RECEPTOR}_em.gro, {RECEPTOR}.top, nvt.mdp
# OUTPUT: {WORKSPACE}/rec/ensemble/nvt/{RECEPTOR}_nvt.gro, {RECEPTOR}_nvt.trr, {RECEPTOR}_nvt.log

# Step 2.3: NPT equilibration
# SCRIPT: scripts/md_npt.sh | scripts/md_npt.py
# INPUT: {WORKSPACE}/rec/ensemble/nvt/{RECEPTOR}_nvt.gro, {RECEPTOR}.top, npt.mdp
# OUTPUT: {WORKSPACE}/rec/ensemble/npt/{RECEPTOR}_npt.gro, {RECEPTOR}_npt.trr, {RECEPTOR}_npt.log

# Step 2.4: Production MD
# SCRIPT: scripts/md_prod.sh | scripts/md_prod.py
# INPUT: {WORKSPACE}/rec/ensemble/npt/{RECEPTOR}_npt.gro, {RECEPTOR}.top, prod.mdp
# OUTPUT: {WORKSPACE}/rec/ensemble/prod/{RECEPTOR}_prod.xtc, {RECEPTOR}_prod.log

# Step 2.5: Extract frames
# SCRIPT: scripts/ensemble_extract.sh | scripts/ensemble_extract.py
# INPUT: {WORKSPACE}/rec/ensemble/prod/{RECEPTOR}_prod.xtc
# OUTPUT: {WORKSPACE}/rec/ensemble/frames/frame_{N}.pdb (N frames)
```

**Analysis:**
- RMSD convergence check (threshold: <3Å)
- RMSF analysis for flexible regions
- Trajectory visual inspection

**Output Verification:**
```bash
[ -f {WORKSPACE}/rec/ensemble/prod/{RECEPTOR}_prod.xtc ]
[ $(ls {WORKSPACE}/rec/ensemble/frames/*.pdb 2>/dev/null | wc -l) -ge N_FRAMES ]
```

**Checkpoint:** Human verifies MD stability before clustering.

---

## Stage 3: Ensemble Clustering & Selection

**Requirements:** SCRIPT-01 (receptor scripts), CHECK-01 (stage checkpoints), EXEC-01 (local execution)

**Purpose:** Select representative conformers from MD trajectory.

**Working Directory:** `cd {WORKSPACE}/rec/ensemble/`

**Input Detection:**
```bash
[ -f {WORKSPACE}/rec/ensemble/prod/{RECEPTOR}_prod.xtc ]
[ -d {WORKSPACE}/rec/ensemble/frames/ ]
```

**Script Execution:**
```bash
# Step 3.1: RMSD-based clustering
# SCRIPT: scripts/cluster_rmsd.sh | scripts/cluster_rmsd.py
# INPUT: {WORKSPACE}/rec/ensemble/frames/*.pdb
# OUTPUT: {WORKSPACE}/rec/ensemble/clustered/cluster_{N}.pdb

# Step 3.2: Select representatives
# SCRIPT: scripts/ensemble_select.sh | scripts/ensemble_select.py
# INPUT: {WORKSPACE}/rec/ensemble/clustered/
# OUTPUT: {WORKSPACE}/rec/ensemble/selected/rep_{N}.pdb (N representatives)
```

**Analysis:**
- Cluster population distribution
- Representative structure quality

**Output Verification:**
```bash
[ $(ls {WORKSPACE}/rec/ensemble/selected/*.pdb | wc -l) -ge N_REPRESENTATIVES ]
```

---

## Stage 4: Reference Redocking (Validation)

**Requirements:** SCRIPT-03 (docking scripts), CHECK-01 (stage checkpoints), CHECK-02 (human verification), EXEC-05 (parallel jobs)

**Purpose:** Validate docking protocol using reference ligand with known pose.

**Working Directory:** `cd {WORKSPACE}/dock/ref/`

**Input Detection:**
```bash
[ -f {WORKSPACE}/rec/ensemble/selected/rep_*.pdb ]
[ -f work/input/lig/ref/{REF_LIG}.pdb ]
[ -f work/input/dock/gnina.cfg ]  # optional
```

**Script Execution:**
```bash
# Step 4.1: Prepare receptor grids (one per ensemble member)
# SCRIPT: scripts/dock_prep_grid.sh | scripts/dock_prep_grid.py
# INPUT: {WORKSPACE}/rec/ensemble/selected/rep_{N}.pdb
# OUTPUT: {WORKSPACE}/dock/grids/rep_{N}/grid.nii

# Step 4.2: Dock reference ligand to all ensemble members
# SCRIPT: scripts/dock_gnina.sh | scripts/dock_gnina.py
# INPUT: grids/, {REF_LIG}.pdb, gnina.cfg
# OUTPUT: {WORKSPACE}/dock/ref/rep_{N}_dock.sdf

# Step 4.3: Calculate RMSD to reference pose
# SCRIPT: scripts/dock_rmsd.sh | scripts/dock_rmsd.py
# INPUT: {WORKSPACE}/dock/ref/rep_{N}_dock.sdf, {REF_LIG}.pdb
# OUTPUT: {WORKSPACE}/dock/ref/rmsd_summary.csv
```

**Analysis:**
- RMSD distribution across ensemble
- Best pose RMSD <2.0Å indicates protocol validity

**Output Verification:**
```bash
[ -f {WORKSPACE}/dock/ref/rmsd_summary.csv ]
```

**Checkpoint:** Human validates docking protocol if RMSD < 2.0Å for reference ligand.

---

## Stage 5: Target Ligand Docking

**Requirements:** SCRIPT-03 (docking scripts), CHECK-01 (stage checkpoints), CHECK-02 (human verification), EXEC-05 (parallel jobs)

**Purpose:** Dock all target ligands to ensemble representatives.

**Working Directory:** `cd {WORKSPACE}/dock/new/`

**Input Detection:**
```bash
[ -d {WORKSPACE}/dock/grids/ ]
[ $(ls work/input/lig/new/*.pdb | wc -l) -gt 0 ]
```

**Script Execution:**
```bash
# Step 5.1: Dock all ligands to all ensemble members (parallel)
# SCRIPT: scripts/dock_ligands.sh | scripts/dock_ligands.py
# INPUT: grids/, work/input/lig/new/*.pdb, gnina.cfg
# OUTPUT: {WORKSPACE}/dock/new/{LIG}/rep_{N}_dock.sdf
# OPTIONS: --parallel N_JOBS, --slurm (for HPC)

# Step 5.2: Aggregate docking results
# SCRIPT: scripts/dock_aggregate.sh | scripts/dock_aggregate.py
# INPUT: {WORKSPACE}/dock/new/*/*.sdf
# OUTPUT: {WORKSPACE}/dock/new/summary/docking_summary.csv
```

**Analysis:**
- CNN score distribution per ligand
- Pose diversity across ensemble members

**Output Verification:**
```bash
[ -f {WORKSPACE}/dock/new/summary/docking_summary.csv ]
```

---

## Stage 6: Complex Preparation (for MD Rescoring)

**Requirements:** SCRIPT-04 (MD setup scripts), SCRIPT-05 (MD production scripts), CHECK-01 (stage checkpoints), EXEC-02 (Slurm)

**Purpose:** Prepare protein-ligand complexes for MD simulation.

**Working Directory:** `cd {WORKSPACE}/com_md/`

**Input Detection:**
```bash
[ -f {WORKSPACE}/rec/topology/{RECEPTOR}.top ]
[ -f {WORKSPACE}/dock/new/summary/docking_summary.csv ]
[ -f work/input/lig/new/{LIG}.itp ]
[ -f work/input/lig/new/{LIG}.gro ]
```

**Script Execution:**
```bash
# Step 6.1: Select top poses for MD
# SCRIPT: scripts/com_select_poses.sh | scripts/com_select_poses.py
# INPUT: docking_summary.csv, N_POSES
# OUTPUT: {WORKSPACE}/com_md/selected/{LIG}_pose_{M}.pdb

# Step 6.2: Build complex topology
# SCRIPT: scripts/com_build_topol.sh | scripts/com_build_topol.py
# INPUT: {RECEPTOR}.top, {LIG}.itp, {LIG}.gro
# OUTPUT: {WORKSPACE}/com_md/{LIG}/complex.top, complex.gro

# Step 6.3: Solvate and add ions
# SCRIPT: scripts/com_solvate.sh | scripts/com_solvate.py
# INPUT: complex.top, complex.gro
# OUTPUT: {WORKSPACE}/com_md/{LIG}/solvated/complex_solv.top, complex_solv.gro
```

**Output Verification:**
```bash
[ -f {WORKSPACE}/com_md/{LIG}/solvated/complex_solv.top ]
[ -f {WORKSPACE}/com_md/{LIG}/solvated/complex_solv.gro ]
```

---

## Stage 7: MD Simulation (Rescoring)

**Requirements:** SCRIPT-04 (MD setup scripts), SCRIPT-05 (MD production scripts), CHECK-01 (stage checkpoints), EXEC-02 (Slurm)

**Purpose:** Run MD simulations for binding free energy calculation.

**Working Directory:** `cd {WORKSPACE}/com_md/{LIG}/`

**Input Detection:**
```bash
[ -f {WORKSPACE}/com_md/{LIG}/solvated/complex_solv.top ]
[ -f {WORKSPACE}/com_md/{LIG}/solvated/complex_solv.gro ]
```

**Script Execution:**
```bash
# Step 7.1: Energy minimization
# SCRIPT: scripts/md_em_complex.sh | scripts/md_em_complex.py
# INPUT: complex_solv.top, complex_solv.gro, em.mdp
# OUTPUT: {WORKSPACE}/com_md/{LIG}/em/complex_em.gro

# Step 7.2: Equilibration (NVT + NPT)
# SCRIPT: scripts/md_equilibrate.sh | scripts/md_equilibrate.py
# INPUT: complex_em.gro, complex_solv.top, nvt.mdp, npt.mdp
# OUTPUT: {WORKSPACE}/com_md/{LIG}/equilibrated/complex_eq.gro

# Step 7.3: Production MD
# SCRIPT: scripts/md_prod_complex.sh | scripts/md_prod_complex.py
# INPUT: complex_eq.gro, complex_solv.top, prod.mdp
# OUTPUT: {WORKSPACE}/com_md/{LIG}/prod/complex_prod.xtc
# OPTIONS: --slurm, --parallel N_LIGANDS
```

**Analysis:**
- RMSD stability check
- Ligand-protein interactions
- Trajectory convergence

**Output Verification:**
```bash
[ -f {WORKSPACE}/com_md/{LIG}/prod/complex_prod.xtc ]
```

---

## Stage 8: MMPBSA Binding Free Energy

**Requirements:** SCRIPT-06 (MMPBSA scripts), CHECK-01 (stage checkpoints), EXEC-02 (Slurm), EXEC-05 (parallel jobs)

**Purpose:** Calculate binding free energies using MM/PBSA.

**Working Directory:** `cd {WORKSPACE}/com_md/{LIG}/`

**Input Detection:**
```bash
[ -f {WORKSPACE}/com_md/{LIG}/prod/complex_prod.xtc ]
[ -f {WORKSPACE}/com_md/{LIG}/solvated/complex_solv.top ]
```

**Script Execution:**
```bash
# Step 8.1: Generate AMBER topologies
# SCRIPT: scripts/mmpbsa_prep.sh | scripts/mmpbsa_prep.py
# INPUT: complex_solv.top, complex_prod.xtc
# OUTPUT: {WORKSPACE}/com_md/{LIG}/mmpbsa/*.prmtop, *.inpcrd

# Step 8.2: Run MM/PBSA calculation
# SCRIPT: scripts/mmpbsa_run.sh | scripts/mmpbsa_run.py
# INPUT: *.prmtop, *.inpcrd, mmpbsa.in
# OUTPUT: {WORKSPACE}/com_md/{LIG}/mmpbsa/FINAL_RESULTS_MMPBSA.dat
# OPTIONS: --slurm, --parallel N_JOBS

# Step 8.3: Aggregate results
# SCRIPT: scripts/mmpbsa_aggregate.sh | scripts/mmpbsa_aggregate.py
# INPUT: {WORKSPACE}/com_md/*/mmpbsa/FINAL_RESULTS_MMPBSA.dat
# OUTPUT: {WORKSPACE}/results/mmpbsa_summary.csv
```

**Analysis:**
- Binding free energy per ligand
- Entropy contributions (if calculated)
- Per-residue decomposition

**Output Verification:**
```bash
[ -f {WORKSPACE}/results/mmpbsa_summary.csv ]
```

**Checkpoint:** Human reviews final ranking before publication.

---

## Stage 9: Final Analysis & Reporting

**Requirements:** SCRIPT-07 (analysis scripts), DOC-01 (README documentation), DOC-02 (agent-optimized docs)

**Purpose:** Generate comprehensive analysis report.

**Working Directory:** `cd {WORKSPACE}/results/`

**Script Execution:**
```bash
# Step 9.1: Generate ranking table
# SCRIPT: scripts/analysis_ranking.py
# INPUT: mmpbsa_summary.csv, docking_summary.csv
# OUTPUT: {WORKSPACE}/results/ranking.csv

# Step 9.2: Generate plots
# SCRIPT: scripts/analysis_plots.py
# INPUT: ranking.csv, trajectories/
# OUTPUT: {WORKSPACE}/results/figures/*.png

# Step 9.3: Generate report
# SCRIPT: scripts/analysis_report.py
# INPUT: ranking.csv, figures/
# OUTPUT: {WORKSPACE}/results/report.pdf
```

**Output:**
- `{WORKSPACE}/results/ranking.csv` - Final ligand ranking
- `{WORKSPACE}/results/figures/` - Analysis figures
- `{WORKSPACE}/results/report.pdf` - Summary report

---

## On-Demand Stages

### Checker Agent

**Trigger:** User invokes `/check` command or agent flags potential issue.

**Purpose:** Investigate results and provide warnings/suggestions.

**Working Directory:** `cd {WORKSPACE}/`

**Script Execution:**
```bash
# SCRIPT: scripts/check_{STAGE}.sh | scripts/check_{STAGE}.py
# INPUT: Stage-specific outputs
# OUTPUT: {WORKSPACE}/logs/check_{STAGE}.log
```

### Debugger Agent

**Trigger:** Stage failure or user invokes `/debug` command.

**Purpose:** Diagnose and fix issues following GSD debugger workflow.

**Working Directory:** `cd {WORKSPACE}/`

**Script Execution:**
```bash
# SCRIPT: scripts/debug_{STAGE}.sh | scripts/debug_{STAGE}.py
# INPUT: Error logs, failed outputs
# OUTPUT: {WORKSPACE}/logs/debug_{STAGE}.log, fix recommendations
```

---

## Parallel Execution Options

For multi-ligand workflows, the following stages support parallel execution:

| Stage | Parallel Mode | Max Workers |
|-------|---------------|-------------|
| Stage 5 (Docking) | Per-ligand | N_LIGANDS |
| Stage 6 (Complex Prep) | Per-ligand | N_LIGANDS |
| Stage 7 (MD Sim) | Per-ligand | N_LIGANDS |
| Stage 8 (MMPBSA) | Per-ligand | N_LIGANDS |

**Slurm Integration:**
```bash
# For HPC clusters, use --slurm flag
./scripts/dock_ligands.py --slurm --array {LIGAND_LIST}
./scripts/md_prod_complex.py --slurm --array {LIGAND_LIST}
```

---

## Workflow Summary Diagram

```
INPUT                    RECEPTOR                    ENSEMBLE
  │                        │                            │
  ├─► Stage 0: Validate    │                            │
  │                        │                            │
  └─► Stage 1: Prepare ────┴──► Stage 2: MD ────────────┴──► Stage 3: Cluster
                                    │
                                    ▼
                              ENSEMBLE FRAMES
                                    │
         LIGANDS                    │
            │                       │
            ▼                       ▼
      Stage 4: Ref Dock ◄───── Stage 4: Grids
            │
            ▼
      Stage 5: Target Dock ────► DOCKING RESULTS
                                        │
                                        ▼
                              Stage 6: Complex Prep
                                        │
                                        ▼
                              Stage 7: MD Simulation
                                        │
                                        ▼
                              Stage 8: MMPBSA
                                        │
                                        ▼
                              Stage 9: Analysis
```

---

## Placeholders to Fill

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `{WORKSPACE}` | Root working directory | `work/run_001/` |
| `{RECEPTOR}` | Receptor filename prefix | `protein`, `rec` |
| `{REF_LIG}` | Reference ligand filename prefix | `ref_lig`, `crystal_lig` |
| `{LIG}` | Target ligand filename prefix | `lig_001`, `compound_A` |
| `{LIG_N}` | Nth target ligand | `lig_001`, `lig_002` |
| `N_FRAMES` | Number of frames to extract | `100` |
| `N_REPRESENTATIVES` | Number of cluster representatives | `5` |
| `N_POSES` | Number of poses per ligand for MD | `3` |
| `N_LIGANDS` | Number of target ligands | `10` |
| `N_JOBS` | Number of parallel jobs | `4` |

---

## Scripts Status

| Script | Status | Location |
|--------|--------|----------|
| `validate_input.py` | PLACEHOLDER | `scripts/` |
| `rec_clean.sh/py` | PLACEHOLDER | `scripts/` |
| `rec_addH.sh/py` | PLACEHOLDER | `scripts/` |
| `rec_topol.sh/py` | PLACEHOLDER | `scripts/` |
| `md_em.sh/py` | PLACEHOLDER | `scripts/` |
| `md_nvt.sh/py` | PLACEHOLDER | `scripts/` |
| `md_npt.sh/py` | PLACEHOLDER | `scripts/` |
| `md_prod.sh/py` | PLACEHOLDER | `scripts/` |
| `ensemble_extract.sh/py` | PLACEHOLDER | `scripts/` |
| `cluster_rmsd.sh/py` | PLACEHOLDER | `scripts/` |
| `ensemble_select.sh/py` | PLACEHOLDER | `scripts/` |
| `dock_prep_grid.sh/py` | PLACEHOLDER | `scripts/` |
| `dock_gnina.sh/py` | PLACEHOLDER | `scripts/` |
| `dock_rmsd.sh/py` | PLACEHOLDER | `scripts/` |
| `dock_ligands.sh/py` | PLACEHOLDER | `scripts/` |
| `dock_aggregate.sh/py` | PLACEHOLDER | `scripts/` |
| `com_select_poses.sh/py` | PLACEHOLDER | `scripts/` |
| `com_build_topol.sh/py` | PLACEHOLDER | `scripts/` |
| `com_solvate.sh/py` | PLACEHOLDER | `scripts/` |
| `md_em_complex.sh/py` | PLACEHOLDER | `scripts/` |
| `md_equilibrate.sh/py` | PLACEHOLDER | `scripts/` |
| `md_prod_complex.sh/py` | PLACEHOLDER | `scripts/` |
| `mmpbsa_prep.sh/py` | PLACEHOLDER | `scripts/` |
| `mmpbsa_run.sh/py` | PLACEHOLDER | `scripts/` |
| `mmpbsa_aggregate.sh/py` | PLACEHOLDER | `scripts/` |
| `analysis_ranking.py` | PLACEHOLDER | `scripts/` |
| `analysis_plots.py` | PLACEHOLDER | `scripts/` |
| `analysis_report.py` | PLACEHOLDER | `scripts/` |

---

*Last updated: 2026-03-23*
*Status: DRAFT - TO BE FINALIZED*