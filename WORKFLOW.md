# autoEnsmblDockMD Workflow Reference

Definitive end-to-end reference for running the docking → MD → MM/PBSA pipeline manually.
This document maps workflow stages to script entrypoints, required inputs, expected outputs,
and Mode A/Mode B differences.

## 1) Overview

autoEnsmblDockMD supports two production workflow modes:

- **Mode A (targeted/reference pocket, AMBER-style)**
  - Reference ligand defines docking box (gnina autobox).
  - Typically uses AMBER protein FF + ligand params (GAFF-like workflow).
  - Includes reference redocking and often alignment to preserve pocket geometry.
- **Mode B (blind docking, CHARMM36m/CGenFF)**
  - Docking uses receptor-wide/autobox-from-receptor behavior.
  - Uses CHARMM/CGenFF-style ligand parameterization.

Primary wrapper: `scripts/run_pipeline.sh` (stages via `--stage`, full run without `--stage`).
All scripts expect environment setup first: `source ./scripts/setenv.sh`.

## 2) Prerequisites

Provide these before execution:

- Receptor PDB in receptor workspace (`[receptor] input_pdb`)
- Ligand inputs (Mode-dependent):
  - Mode A: reference ligand + new ligands, with topology files as needed
  - Mode B: ligand directories for blind docking input
- Force-field files and ligand parameter files
- MDP files for receptor and complex stages (`[receptor] mdp_dir`, `[complex] mdp_dir`)
- Config file copied from `scripts/config.ini.template`

Software/tooling:

- GROMACS (>2022), gnina, gmx_MMPBSA
- Python packages required by script modules (MDAnalysis, etc.)
- Optional Open Babel for conversion helpers (`0_sdf2gro.sh`)

## 3) Workspace Structure

Typical run root (example from `[general] workdir`):

```text
work/test/
├── rec/                    # receptor prep, receptor MD, clustering outputs
├── dock/                   # receptor conformers + docking outputs per ligand
├── com/                    # complex MD, MM/PBSA, analysis outputs
├── mdp/rec/                # receptor MDPs
├── mdp/com/                # complex/production MDPs
├── ref/                    # (optional) reference ligand parameter assets
└── config.ini              # copied from scripts/config.ini.template
```

Scripts live under:

- `scripts/rec/`
- `scripts/dock/`
- `scripts/com/`
- shared infra: `scripts/infra/`

## 4) Stage Reference

### Stage 0 — Input Preparation (user-provided files)

**Purpose:** Ensure directory layout, config, force fields, and ligand/receptor files are in place.

**Scripts:**

- `scripts/infra/config_loader.sh` (INI parsing helpers)
- `scripts/infra/common.sh` (logging, validation, command helpers)
- `scripts/run_pipeline.sh --list-stages` (sanity check stage wiring)

**Required inputs:**

- `scripts/config.ini.template` copied to runtime config
- `[general] workdir`, `[receptor] input_pdb`, relevant FF/MDP files

**Expected outputs:**

- Validated directory tree and config resolution for downstream stages

**Mode notes:**

- **Mode A:** prepare reference ligand assets and AMBER-compatible topology inputs
- **Mode B:** prepare CHARMM36m/CGenFF ligand assets for blind docking flow

### Stage 1 — Receptor Ensemble Generation

**Purpose:** Build receptor system, run receptor MD sampling, analyze and cluster conformers.

**Scripts (execution order):**

1. `scripts/rec/0_prep.sh` (pdb2pqr/pdb2gmx + solvation/ions + equilibration submission)
2. `scripts/rec/1_pr_rec.sh` (parallel receptor production trials)
3. `scripts/rec/3_ana.sh` (trajectory conversion, RMSD/RMSF, merged outputs)
4. `scripts/rec/4_cluster.sh` (cluster to ensemble conformers)
5. `scripts/rec/5_align.py` (optional/Mode A-typical structural alignment)

**Required inputs/config keys:**

- `[receptor] workdir, input_pdb, ff, water_model, mdp_dir, n_trials, ensemble_size`
- `[receptor] cluster_*`, `align_*`, `analysis_*`
- `[slurm] partition, ntomp, gpus`

**Expected outputs:**

- receptor topology/coordinates, per-trial trajectories, merged/fit trajectories
- clustered receptor conformers (e.g., `rec0..recN`) and optional aligned structures

**Mode notes:**

- **Mode A:** alignment strongly recommended to preserve reference pocket orientation
- **Mode B:** clustering outputs feed blind docking receptor set directly

### Stage 2 — Docking (conversion → ensemble docking → scoring → pose selection)

**Purpose:** Convert ligand inputs, prepare receptor docking files, run gnina, and rank poses.

**Scripts (execution order):**

1. `scripts/dock/0_gro2mol2.sh` (batch wrapper)
2. `scripts/dock/0_gro_itp_to_mol2.py` (conversion core)
3. `scripts/dock/0_sdf2gro.sh` (optional reverse conversion helper)
4. `scripts/dock/1_rec4dock.sh` (copy/symlink receptor conformers; GRO→PDB)
5. `scripts/dock/2_gnina.sh` (modes: `test|targeted|blind`)
6. `scripts/dock/3_dock_report.sh` (aggregate/rank scores)
7. `scripts/dock/4_dock2com_1.py` (pose extraction/selection for complex setup)

**Required inputs/config keys:**

- `[dock] ligand_dir, output_dir, gro_pattern, converter_script`
- `[docking] dock_dir, ligands_dir, mode, receptor_dir, reference_ligand, autobox_*`
- receptor conformers from Stage 1 and ligand source files

**Expected outputs:**

- docking-ready ligand MOL2 files, receptor PDB conformers, gnina SDF outputs/logs
- ranked report (`[docking] report_output`) and selected poses for dock2com

**Mode notes:**

- **Mode A:** use `mode=targeted`/`mode=test`, `autobox_ligand` as reference ligand
- **Mode B:** use `mode=blind`, box behavior driven by receptor setup

### Stage 3 — Complex Setup (dock2com → topology assembly → solvation/ions/minimization)

**Purpose:** Transform docked pose into MD-ready receptor-ligand complex systems.

**Scripts (execution order):**

1. `scripts/dock/4_dock2com.sh` (new ligands) and/or `scripts/dock/4_dock2com_ref.sh` (reference)
2. `scripts/dock/4_dock2com_2.py` (topology assembly core)
3. `scripts/dock/4_dock2com_2.1.py` (ITP parsing utility)
4. `scripts/dock/4_dock2com_2.2.1.py` (ligand position restraints)
5. `scripts/com/0_prep.sh` (complex solvation, ions, minimization, restrained equil.)
6. `scripts/com/bypass_angle_type3.py` (AMBER compatibility helper when needed)

**Required inputs/config keys:**

- `[dock2com]` and `[dock2com_ref]` sections (FF mode, rec_top, ligand patterns)
- `[complex] mode, receptor_gro, receptor_top, ff_include, mdp_dir, em_mdp, pr_pos_mdp`

**Expected outputs:**

- ligand-specific complex directories with `com.gro`, `sys.top`, `index.ndx`, minimized/equil files
- `posre_lig.itp` and bypass-adjusted topology artifacts where applicable

**Mode notes:**

- **Mode A:** `ff=amber`; bypass utility frequently relevant
- **Mode B:** `ff=charmm`; CGenFF-style topology path

### Stage 4 — MD Simulation (equilibration → production)

**Purpose:** Run post-setup equilibration chain and production MD trajectories.

**Scripts:**

- `scripts/com/1_pr_prod.sh`

**Required inputs/config keys:**

- `[production] n_trials, n_equilibration_stages, pr0_mdp, pr_mdp_prefix, production_mdp`
- `[slurm]` and per-production resource keys

**Expected outputs:**

- per-ligand production trajectory sets (`prod_*.xtc`, `prod_*.tpr`) and logs

**Mode notes:**

- Same stage layout for A/B; force-field differences come from prior topology setup

### Stage 5 — MM/PBSA (trajectory processing → binding energy calculation)

**Purpose:** Prepare chunked trajectories and launch MM/PBSA jobs.

**Scripts (execution order):**

1. `scripts/com/2_run_mmpbsa.sh` (orchestrator)
2. `scripts/com/2_trj4mmpbsa.sh` (trajectory/index prep)
3. `scripts/com/2_sub_mmpbsa.sh` (array submission)
4. `scripts/com/2_mmpbsa.sh` (per-chunk execution)

**Required inputs/config keys:**

- `[mmpbsa] n_chunks, chunk_dir_prefix, source_xtc_pattern, source_tpr_pattern, mmpbsa_input`
- topology mode keys: `amber_topology_file` / `charmm_topology_file`

**Expected outputs:**

- chunk directories (`mmpbsa_0..N`), processed trajectories, MM/PBSA energy outputs

**Mode notes:**

- **Mode A:** uses AMBER-side topology selection
- **Mode B:** uses CHARMM-side topology selection

### Stage 6 — Analysis (RMSD, RMSF, contacts, H-bonds, fingerprints)

**Purpose:** Produce standard trajectory metrics and optional comparison utilities.

**Scripts (execution order):**

1. `scripts/com/3_ana.sh` (GROMACS + MDAnalysis analysis entrypoint)
2. `scripts/com/3_com_ana_trj.py` (advanced metrics/plots)
3. `scripts/com/3_selection_defaults.py` (selection presets)
4. `scripts/com/4_cal_fp.sh` + `scripts/com/4_fp.py` (fingerprint metrics)
5. Optional utilities: `scripts/com/5_arc_sel.sh`, `scripts/com/5_rerun_sel.sh`

**Required inputs/config keys:**

- `[analysis] run_rmsd, run_rmsf, run_hbond, run_advanced, contact_cutoff, selections`
- optional utility sections: `[fingerprint]`, `[archive]`, `[rerun]`

**Expected outputs:**

- per-ligand analysis directory (RMSD/RMSF/H-bond outputs, advanced plots, contacts)
- optional fingerprint matrices/heatmaps and archive/rerun helper artifacts

**Mode notes:**

- Analysis scripts are shared across A/B; interpretation depends on docking mode and FF context

## 5) Pipeline Flow Diagram

```text
User Inputs + config.ini
        |
        v
[Stage 0] Input preparation / config validation
        |
        v
[Stage 1] Receptor ensemble generation
  (0_prep -> 1_pr_rec -> 3_ana -> 4_cluster -> 5_align)
        |
        v
     Mode Decision
   +-------------------+
   | A: targeted/test  |---- uses reference ligand autobox
   | B: blind          |---- receptor-wide/blind mode
   +-------------------+
        |
        v
[Stage 2] Docking
  (0_gro2mol2 -> 1_rec4dock -> 2_gnina -> 3_dock_report -> pose selection)
        |
        v
[Stage 3] Complex setup
  (4_dock2com* -> 0_prep [+ bypass_angle_type3 when needed])
        |
        v
[Stage 4] MD simulation
  (1_pr_prod)
        |
        v
[Stage 5] MM/PBSA
  (2_run_mmpbsa -> 2_trj4mmpbsa -> 2_sub_mmpbsa -> 2_mmpbsa)
        |
        v
[Stage 6] Analysis
  (3_ana -> 3_com_ana_trj -> 4_cal_fp/4_fp -> optional archive/rerun tools)
        |
        v
Final outputs: ranked docking + MD trajectories + MM/PBSA + analysis reports
```

## Script Inventory Coverage Notes

The following modules exist for import compatibility and are intentionally referenced here:

- `scripts/dock/gro_itp_to_mol2.py` (wrapper around `0_gro_itp_to_mol2.py`)
- `scripts/dock/dock2com_2_1.py` (wrapper around `4_dock2com_2.1.py`)
- `scripts/dock/__init__.py` (package marker for dock Python modules)

Infrastructure Python modules retained for orchestration/checkpoint support:

- `scripts/infra/config.py`, `scripts/infra/state.py`, `scripts/infra/checkpoint.py`
- `scripts/infra/executor.py`, `scripts/infra/monitor.py`, `scripts/infra/verification.py`
- `scripts/infra/__init__.py`
