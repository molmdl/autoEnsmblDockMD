# Phase 7: Complete Targeted Docking Workflow

**Researched:** 2026-05-04
**Domain:** Ensemble docking → complex MD → MM/PBSA pipeline
**Confidence:** HIGH

## Summary

The targeted docking workflow consists of 7 major stages (0-6) with 16 sub-stages, managed by 9 specialized skills. Three stages submit asynchronous Slurm jobs that require completion verification before downstream progression. The critical missing stage in the current Phase 7 plan is **Stage 1: Receptor Ensemble Preparation** (`aedmd-rec-ensemble`), which must complete BEFORE docking.

**Primary recommendation:** Restructure Phase 7 to start with receptor ensemble preparation (Plan 07-03), not docking. Current Plan 07-03 should become Plan 07-04.

---

## Complete Stage Sequence

### Overview

```
Stage 0: Initialization & Preflight (Plans 07-01, 07-02)
    ↓
Stage 1: Receptor Ensemble Preparation (MISSING - needs Plan 07-03)
    ↓
Stage 2: Docking (current Plan 07-03 - should become 07-04)
    ↓
Stage 3: Complex Setup (current Plan 07-04)
    ↓
Stage 4: Complex MD (current Plan 07-05)
    ↓
Stage 5: MM/PBSA (current Plan 07-06)
    ↓
Stage 6: Analysis & Validation (current Plans 07-07, 07-08)
```

---

## Stage 0: Initialization & Preflight

### 0a: Workspace Initialization
**Skill:** `aedmd-workspace-init`
**Stage token:** `workspace_initialization`
**Execution mode:** Synchronous
**Duration:** < 1 minute

**Purpose:**
- Copy `work/input` template to isolated workspace (`work/test` or `work/run_DATE`)
- Create deterministic directory structure
- Verify template contains required files

**Inputs:**
- Template directory: `work/input/`
- Template must contain:
  - `config.ini` (copied from `scripts/config.ini.template`)
  - `mdp/rec/` directory with receptor MDP files
  - `mdp/com/` directory with complex MDP files
  - `ref/` directory with reference ligand (for targeted mode)

**Outputs:**
- Target workspace: `work/test/` or `work/run_YYYY-MM-DD/`
- Workspace structure:
  ```
  work/test/
  ├── rec/
  ├── dock/
  ├── com/
  ├── mdp/rec/
  ├── mdp/com/
  ├── ref/
  └── config.ini
  ```
- Handoff record: `.handoffs/workspace_init.json`

**Dependencies:**
- None (first stage)

---

### 0b: Preflight Validation
**Skill:** `aedmd-preflight`
**Stage token:** `preflight_validation`
**Execution mode:** Synchronous
**Duration:** < 1 minute

**Purpose:**
- Validate config sections exist
- Verify required tools available (`gmx`, `gnina`, `gmx_MMPBSA`)
- Check input files present
- Validate mode-specific settings (targeted vs blind)

**Inputs:**
- Workspace path
- `config.ini` with required sections:
  - `[general]`, `[slurm]`, `[receptor]`, `[dock]`, `[docking]`
  - `[dock2com]`, `[complex]`, `[production]`, `[mmpbsa]`, `[analysis]`

**Outputs:**
- Handoff record: `.handoffs/preflight_validation.json`
- Status values:
  - `success`: All checks passed
  - `needs_review`: Warnings present (non-blocking)
  - `failure`: Blocking errors found

**Mode-specific validation:**
- **Targeted mode:** Requires `reference_ligand` path, autobox settings
- **Blind mode:** Requires autobox configuration

**Dependencies:**
- Requires: Stage 0a (workspace initialization)

---

## Stage 1: Receptor Ensemble Preparation

**This stage is MISSING from current Phase 7 plan structure.**

### 1a: Receptor Preparation
**Skill:** `aedmd-rec-ensemble`
**Script:** `scripts/rec/0_prep.sh`
**Stage token:** `receptor_prep`
**Execution mode:** Synchronous (submits equilibration job)
**Duration:** 
- Preparation: ~5 minutes
- Equilibration (async): 1-4 hours (configurable)

**Purpose:**
- Protonate receptor (if needed)
- Generate topology with force field
- Solvate and ionize system
- Submit equilibration job

**Inputs from config:**
- `receptor.input_pdb`: Input receptor structure
- `receptor.ff`: Force field (`charmm36` or `amber`)
- `receptor.water_model`: Solvent model
- `receptor.workdir`: Output directory
- `slurm.partition`: Target partition
- `slurm.ntomp`: OpenMP threads

**Outputs:**
- `rec/prot.gro`: Processed receptor coordinates
- `rec/topol.top`: Receptor topology
- `rec/index.ndx`: GROMACS index file
- `rec/pr.tpr`: Equilibration TPR file
- Handoff record: `.handoffs/receptor_prep.json`

**Dependencies:**
- Requires: Stage 0b (preflight validation)

---

### 1b: Receptor Production MD
**Script:** `scripts/rec/1_pr_rec.sh`
**Stage token:** `receptor_md`
**Execution mode:** **ASYNC** (Slurm array job)
**Duration:** 4-24 hours per trial (configurable)

**Purpose:**
- Submit parallel receptor production MD trials
- Generate trajectory ensemble for clustering

**Inputs from config:**
- `receptor.n_trials`: Number of independent trials (default: 4)
- `receptor.mdp_dir`: Directory with production MDP files
- `slurm.gpus`: GPU count per job
- `slurm.ntomp`: OpenMP threads

**Outputs:**
- `rec/pr_*/prod.xtc`: Production trajectories per trial
- `rec/pr_*/prod.tpr`: TPR files per trial
- Slurm job ID(s) in handoff record

**Dependencies:**
- Requires: Stage 1a (receptor preparation)
- **Critical:** Verify job completion with `squeue`/`sacct` before Stage 1c

**Async verification:**
```bash
# Check if jobs completed
squeue -u "$USER"
sacct -j <jobid> --format=JobID,State,Elapsed,ExitCode

# Verify trajectories exist
ls -lh rec/pr_*/prod.xtc
```

---

### 1c: Receptor Trajectory Analysis
**Script:** `scripts/rec/3_ana.sh`
**Stage token:** N/A (internal to rec-ensemble skill)
**Execution mode:** Synchronous
**Duration:** 10-30 minutes

**Purpose:**
- Convert trajectories to unified format
- Calculate RMSD/RMSF for quality assessment
- Merge trajectories for clustering

**Inputs:**
- Production trajectories from Stage 1b
- `receptor.analysis_*` settings (if configured)

**Outputs:**
- `rec/merged.xtc`: Merged trajectory
- `rec/fit.xtc`: Fitted trajectory
- RMSD/RMSF analysis results
- Handoff record: `.handoffs/receptor_ana.json`

**Dependencies:**
- **Requires:** Stage 1b COMPLETED (all trials finished)

---

### 1d: Receptor Clustering
**Script:** `scripts/rec/4_cluster.sh`
**Stage token:** `receptor_cluster`
**Execution mode:** Synchronous
**Duration:** 5-15 minutes

**Purpose:**
- Cluster merged trajectory
- Extract representative conformers
- Generate receptor ensemble

**Inputs from config:**
- `receptor.ensemble_size`: Number of conformers (default: 10)
- `receptor.cluster_method`: Clustering algorithm
- `receptor.cluster_cutoff`: Distance cutoff

**Outputs:**
- `rec/rec*.pdb`: Ensemble PDB files (e.g., `rec1.pdb` through `rec10.pdb`)
- Clustering statistics
- Handoff record: `.handoffs/receptor_cluster.json`

**Dependencies:**
- Requires: Stage 1c (trajectory analysis)

---

### 1e: Receptor Alignment
**Script:** `scripts/rec/5_align.py`
**Stage token:** N/A (optional in pipeline, but part of rec-ensemble skill)
**Execution mode:** Synchronous
**Duration:** 2-5 minutes

**Purpose:**
- Align ensemble structures to reference complex
- Prepare receptors for consistent docking

**Inputs from config:**
- `receptor.align_reference`: Reference structure path
- `receptor.align_structures`: Structures to align

**Outputs:**
- `rec/aligned/rec_*.pdb`: Aligned ensemble PDBs
- Alignment statistics
- Handoff record: `.handoffs/receptor_align.json`

**Dependencies:**
- Requires: Stage 1d (clustering)
- Requires: Reference structure (from `ref/` directory)

---

## Stage 2: Docking

### 2a: Ligand Conversion
**Script:** `scripts/dock/0_gro2mol2.sh`
**Stage token:** `docking_prep`
**Execution mode:** Synchronous
**Duration:** 1-5 minutes

**Purpose:**
- Convert ligand GRO+ITP/TOP to MOL2 format
- Prepare ligands for gnina docking

**Inputs from config:**
- `dock.ligand_dir`: Directory containing ligand files
- `dock.gro_pattern`: Pattern for GRO files
- `dock.converter_script`: Conversion script path

**Outputs:**
- `dock/ligands/*.mol2`: MOL2 ligand files
- Handoff record: `.handoffs/docking_prep.json`

**Dependencies:**
- Requires: Stage 1e (receptor alignment)

---

### 2b: Gnina Docking
**Skill:** `aedmd-dock-run`
**Script:** `scripts/dock/2_gnina.sh`
**Stage token:** `docking_run`
**Execution mode:** Synchronous (but may submit Slurm jobs)
**Duration:** 30 minutes - 4 hours per ligand

**Purpose:**
- Run gnina docking on receptor ensemble
- Generate poses and scores

**Inputs from config:**
- `docking.mode`: `targeted`, `test`, or `blind`
- `docking.dock_dir`: Workspace for docking artifacts
- `docking.ligands_dir`: Ligand directory
- `docking.receptor_dir`: Receptor ensemble directory
- `docking.receptor_prefix`: Receptor file prefix
- **Targeted mode specific:**
  - `docking.reference_ligand`: Path to reference ligand
  - `docking.autobox_ligand`: Autobox source (typically `${docking:reference_ligand}`)
- `docking.exhaustiveness`: Search thoroughness (default: 100)
- `docking.num_modes`: Maximum poses (default: 32)
- `docking.autobox_add`: Box padding in Å (default: 4)

**Outputs:**
- `dock/LIGAND_ID/rec_*/docked.sdf`: Docking poses per receptor
- `dock/LIGAND_ID/rec_*/gnina.log`: Log files
- Handoff record: `.handoffs/docking_run.json`

**Dependencies:**
- Requires: Stage 2a (ligand conversion)
- Requires: Stage 1e (receptor ensemble ready)

---

### 2c: Docking Report
**Script:** `scripts/dock/3_dock_report.sh`
**Stage token:** N/A (internal to dock-run skill)
**Execution mode:** Synchronous
**Duration:** 1-5 minutes

**Purpose:**
- Parse SDF scores
- Generate ranked docking report
- Select top poses

**Inputs:**
- Docking SDF files from Stage 2b
- `docking.report_output`: Report file path

**Outputs:**
- Ranked CSV report: `dock/docking_report.csv`
- Top pose selections
- Handoff record: `.handoffs/docking_report.json`

**Dependencies:**
- Requires: Stage 2b (docking completed)

---

### 2d: Pose Selection (dock2com phase 1)
**Script:** `scripts/dock/4_dock2com_1.py`
**Stage token:** N/A (internal)
**Execution mode:** Synchronous
**Duration:** < 5 minutes

**Purpose:**
- Select top poses from docking results
- Prepare for complex topology assembly

**Inputs:**
- Docking report from Stage 2c
- `dock2com.pose_index`: Which pose to use

**Outputs:**
- Selected pose files
- Pose metadata

**Dependencies:**
- Requires: Stage 2c (docking report)

---

## Stage 3: Complex Setup

**Skill:** `aedmd-com-setup`
**Stage token:** `complex_prep`
**Execution mode:** Synchronous
**Duration:** 10-30 minutes per ligand

**Purpose:**
- Convert docked poses to MD-ready complexes
- Assemble receptor-ligand topology
- Solvate and ionize system
- Run minimization

**Sub-stages:**

### 3a: Topology Assembly
**Scripts:**
- `scripts/dock/4_dock2com.sh` (new ligand) or
- `scripts/dock/4_dock2com_ref.sh` (reference ligand)
- `scripts/dock/4_dock2com_2.py` (topology assembly core)
- `scripts/dock/4_dock2com_2.1.py` (ITP parsing)
- `scripts/dock/4_dock2com_2.2.1.py` (position restraints)

**Inputs from config:**
- `dock2com.mode`: `amber` or `charmm`
- `dock2com.rec_top`: Receptor topology
- `dock2com.pose_index`: Which pose to use
- Ligand ITP/TOP files

**Outputs:**
- `com/LIGAND_ID/lig.gro`: Ligand coordinates
- `com/LIGAND_ID/lig.itp`: Ligand topology
- `com/LIGAND_ID/com.gro`: Complex coordinates
- `com/LIGAND_ID/sys.top`: System topology
- `com/LIGAND_ID/index.ndx`: GROMACS index

---

### 3b: System Preparation
**Script:** `scripts/com/0_prep.sh`
**Stage token:** `complex_prep` (continued)
**Execution mode:** Synchronous
**Duration:** 5-15 minutes per ligand

**Inputs from config:**
- `complex.mode`: `amber` or `charmm`
- `complex.receptor_gro`: Receptor coordinates
- `complex.receptor_top`: Receptor topology
- `complex.ff_include`: Force field include paths
- `complex.mdp_dir`: MDP file directory
- `complex.em_mdp`: Minimization MDP
- `complex.box_distance`: Solvation box size
- `complex.solvent_coordinates`: Solvent model

**Outputs:**
- `com/LIGAND_ID/sys.gro`: Solvated system
- `com/LIGAND_ID/sys.top`: Complete topology
- `com/LIGAND_ID/index.ndx`: Updated index
- `com/LIGAND_ID/em.tpr`: Minimization TPR
- `com/LIGAND_ID/em.gro`: Minimized structure
- `com/LIGAND_ID/posre_lig.itp`: Position restraints (if needed)
- Handoff record: `.handoffs/complex_prep.json`

**Dependencies:**
- Requires: Stage 2d (pose selection)

---

## Stage 4: Complex MD

**Skill:** `aedmd-com-md`
**Script:** `scripts/com/1_pr_prod.sh`
**Stage token:** `complex_md`
**Execution mode:** **ASYNC** (Slurm job)
**Duration:** 12-48 hours per trial (configurable)

**Purpose:**
- Run equilibration chain
- Run production MD trials
- Generate trajectories for analysis

**Inputs from config:**
- `production.n_trials`: Number of independent trials (default: 4)
- `production.n_equilibration_stages`: Equilibration steps (default: 1)
- `production.pr0_mdp`: First equilibration MDP
- `production.pr_mdp_prefix`: Equilibration MDP prefix
- `production.production_mdp`: Production MDP
- `production.ntomp`: OpenMP threads
- `production.partition`: Slurm partition
- `production.gpus`: GPU count

**Outputs:**
- `com/LIGAND_ID/pr_*/prod.xtc`: Production trajectories
- `com/LIGAND_ID/pr_*/prod.tpr`: TPR files
- `com/LIGAND_ID/pr_*/md.log`: MD logs
- Slurm job ID(s) in handoff record
- Handoff record: `.handoffs/complex_md.json`

**Dependencies:**
- Requires: Stage 3b (system preparation)
- **Critical:** Verify job completion before Stage 5

**Async verification:**
```bash
# Check if jobs completed
squeue -u "$USER"
sacct -j <jobid> --format=JobID,State,Elapsed,ExitCode

# Verify trajectories exist
ls -lh com/LIGAND_ID/pr_*/prod.xtc
```

---

## Stage 5: MM/PBSA

**Skill:** `aedmd-com-mmpbsa`
**Stage token:** `complex_mmpbsa`
**Execution mode:** **ASYNC** (Slurm array jobs)
**Duration:** 2-8 hours per chunk (configurable)

**Purpose:**
- Preprocess trajectories for MM/PBSA
- Chunk trajectories for parallel processing
- Calculate binding free energies

**Sub-stages:**

### 5a: Trajectory Preparation
**Script:** `scripts/com/2_trj4mmpbsa.sh`
**Execution mode:** Synchronous
**Duration:** 10-30 minutes

**Inputs from config:**
- `mmpbsa.source_xtc_pattern`: Source trajectory pattern
- `mmpbsa.source_tpr_pattern`: Source TPR pattern
- `mmpbsa.group_ids_file`: Group ID mapping file

**Outputs:**
- Processed trajectories
- Updated index files with receptor/ligand groups

---

### 5b: Chunk Submission
**Script:** `scripts/com/2_sub_mmpbsa.sh`
**Execution mode:** **ASYNC** (Slurm array)
**Duration:** See 5c

**Purpose:**
- Submit MM/PBSA chunk jobs

**Inputs from config:**
- `mmpbsa.n_chunks`: Number of chunks (default: 4)
- `mmpbsa.chunk_dir_prefix`: Chunk directory prefix

**Outputs:**
- Slurm job ID(s) for chunk array

---

### 5c: MM/PBSA Execution
**Script:** `scripts/com/2_mmpbsa.sh`
**Execution mode:** Per-chunk (async)
**Duration:** 2-8 hours per chunk

**Inputs from config:**
- `mmpbsa.mmpbsa_input`: MM/PBSA input file
- `mmpbsa.amber_topology_file`: AMBER topology (if `mode=amber`)
- `mmpbsa.charmm_topology_file`: CHARMM topology (if `mode=charmm`)
- `mmpbsa.receptor_group`: Receptor group name
- `mmpbsa.ligand_group`: Ligand group name
- `mmpbsa.mpi_ranks`: MPI ranks per job

**Outputs:**
- `com/LIGAND_ID/mmpbsa_*/`: Chunk directories
- `com/LIGAND_ID/mmpbsa_*/*_MMPBSA.dat`: Energy results
- Handoff record: `.handoffs/complex_mmpbsa.json`

**Dependencies:**
- Requires: Stage 4 COMPLETED (all MD trials finished)
- **Critical:** Verify all chunk jobs completed before Stage 6

**Async verification:**
```bash
# Check if all chunk jobs completed
squeue -u "$USER"
sacct -j <jobid> --format=JobID,State,Elapsed,ExitCode

# Verify all chunks produced results
ls -lh com/LIGAND_ID/mmpbsa_*/*_MMPBSA.dat
```

---

## Stage 6: Analysis & Validation

### 6a: Trajectory Analysis
**Skill:** `aedmd-com-analyze`
**Script:** `scripts/com/3_ana.sh`
**Stage token:** `complex_analysis`
**Execution mode:** Synchronous
**Duration:** 30 minutes - 2 hours per ligand

**Purpose:**
- Calculate RMSD/RMSF
- Analyze hydrogen bonds
- Generate contact maps
- Optional advanced analysis

**Inputs from config:**
- `analysis.run_rmsd`: Enable RMSD (default: true)
- `analysis.run_rmsf`: Enable RMSF (default: true)
- `analysis.run_hbond`: Enable H-bond analysis (default: true)
- `analysis.run_advanced`: Enable advanced metrics (default: true)
- `analysis.contact_cutoff`: Contact distance cutoff (default: 4.5 Å)
- `analysis.selections`: Atom selections for analysis
- `analysis.distance_reference`: Reference for distance metrics

**Outputs:**
- `com/LIGAND_ID/analysis/rmsd_*.xvg`: RMSD data
- `com/LIGAND_ID/analysis/rmsf_*.xvg`: RMSF data
- `com/LIGAND_ID/analysis/hbond_*.xvg`: H-bond data
- `com/LIGAND_ID/analysis/*.png`: Plots
- `com/LIGAND_ID/analysis/contacts.dat`: Contact analysis
- Handoff record: `.handoffs/complex_analysis.json`

**Dependencies:**
- Requires: Stage 4 COMPLETED
- Optional: Stage 5 COMPLETED (for MM/PBSA correlation)

---

### 6b: Quality Validation
**Skill:** `aedmd-checker-validate`
**Stage token:** `checker_validate`
**Execution mode:** Synchronous
**Duration:** 5-15 minutes

**Purpose:**
- Validate all stage outputs
- Check for anomalies and inconsistencies
- Generate final quality report

**Inputs:**
- All handoff records from previous stages
- Stage output files

**Outputs:**
- Validation report
- Pass/warn/fail findings
- Recommendations
- Handoff record: `.handoffs/checker_validate.json`

**Dependencies:**
- Requires: Stage 6a (analysis completed)

---

## Skill-to-Stage Mapping

| Skill | Stage Token(s) | Covers Stages | Async? |
|-------|----------------|---------------|--------|
| `aedmd-workspace-init` | `workspace_initialization` | 0a | No |
| `aedmd-preflight` | `preflight_validation` | 0b | No |
| `aedmd-rec-ensemble` | `receptor_prep`, `receptor_md`, `receptor_cluster` | 1a-1e | Yes (1b) |
| `aedmd-dock-run` | `docking_prep`, `docking_run` | 2a-2d | Maybe (2b) |
| `aedmd-com-setup` | `complex_prep` | 3a-3b | No |
| `aedmd-com-md` | `complex_md` | 4 | Yes |
| `aedmd-com-mmpbsa` | `complex_mmpbsa` | 5a-5c | Yes |
| `aedmd-com-analyze` | `complex_analysis` | 6a | No |
| `aedmd-checker-validate` | `checker_validate` | 6b | No |

---

## Async Stage Monitoring Pattern

For stages 1b, 4, and 5c (async Slurm jobs):

```bash
# After skill returns, check job status
JOB_ID=$(jq -r '.job_id // .data.job_id // empty' .handoffs/<stage>.json)

if [[ -n "$JOB_ID" ]]; then
    echo "Monitoring Slurm job: $JOB_ID"
    
    # Wait for completion
    while squeue -j "$JOB_ID" &>/dev/null; do
        sleep 60
    done
    
    # Verify success
    sacct -j "$JOB_ID" --format=JobID,State,Elapsed,ExitCode
    
    # Check outputs exist
    # (stage-specific verification)
fi
```

---

## Input Requirements Summary

### Stage 0: Initialization
- Template workspace (`work/input/`)
- `config.ini` with all required sections
- MDP files for receptor and complex stages
- Reference ligand structure (targeted mode)

### Stage 1: Receptor Ensemble
- Receptor PDB file
- Force field files
- MDP files for receptor MD
- Reference structure for alignment (optional)

### Stage 2: Docking
- Ligand GRO+ITP/TOP files
- Receptor ensemble PDBs
- Reference ligand (targeted mode only)

### Stage 3: Complex Setup
- Docking poses (SDF)
- Ligand topology/parameter files
- Receptor topology
- MDP files for equilibration

### Stage 4: Complex MD
- Prepared complex systems
- MDP files for production

### Stage 5: MM/PBSA
- Production trajectories
- System topology
- MM/PBSA configuration

### Stage 6: Analysis
- Production trajectories
- System topology
- MM/PBSA results (optional)

---

## Common Pitfalls

### 1. Missing Receptor Preparation
**What goes wrong:** Starting with docking without receptor ensemble.
**Why it happens:** Plan structure jumps from preflight to docking.
**How to avoid:** Always run `aedmd-rec-ensemble` before `aedmd-dock-run`.

### 2. Async Job Assumptions
**What goes wrong:** Proceeding to next stage before async job completes.
**Why it happens:** Skill returns immediately after `sbatch` submission.
**How to avoid:** Always verify job completion with `squeue`/`sacct` before dependent stages.

### 3. Group ID Drift (MM/PBSA)
**What goes wrong:** MM/PBSA uses wrong receptor/ligand group IDs.
**Why it happens:** Index regeneration changes group ordering.
**How to avoid:** Use `aedmd-group-id-check` skill to verify groups before MM/PBSA.

### 4. Workspace Confusion
**What goes wrong:** Running stages in wrong workspace.
**Why it happens:** Multiple `work/run_*` directories exist.
**How to avoid:** Always specify explicit workspace path; use `aedmd-status` to verify.

---

## Recommended Plan Structure

Based on this research, Phase 7 should be restructured as:

- **Plan 07-01:** Workspace initialization (dryrun) ✓
- **Plan 07-02:** Preflight validation ✓
- **Plan 07-03:** Receptor ensemble preparation (NEW - currently missing)
- **Plan 07-04:** Docking (current Plan 07-03)
- **Plan 07-05:** Complex setup (current Plan 07-04)
- **Plan 07-06:** Complex MD (current Plan 07-05)
- **Plan 07-07:** MM/PBSA (current Plan 07-06)
- **Plan 07-08:** Analysis (current Plan 07-07)
- **Plan 07-09:** Validation (current Plan 07-08)

---

## Sources

### Primary (HIGH confidence)
- `WORKFLOW.md` - Official workflow documentation
- `.opencode/skills/aedmd-*.md` - Skill specifications
- `scripts/run_pipeline.sh` - Stage definitions
- `scripts/agents/schemas/state.py` - WorkflowStage enum

### Secondary (MEDIUM confidence)
- `scripts/CONTEXT.md` - Script inventory

---

## Metadata

**Confidence breakdown:**
- Stage sequence: HIGH - Verified from WORKFLOW.md and run_pipeline.sh
- Skill mapping: HIGH - Verified from skill files
- Async patterns: HIGH - Documented in WORKFLOW.md and skill files
- Duration estimates: MEDIUM - Based on typical HPC workloads, actual times vary

**Research date:** 2026-05-04
**Valid until:** Pipeline architecture changes (stable)
