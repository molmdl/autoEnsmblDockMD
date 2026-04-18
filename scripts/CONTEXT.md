# Scripts Context - Generalized Ensemble Docking Pipeline

This document records the **implemented script inventory** for the v1 pipeline and its unified orchestration entrypoint.

## Script Naming Convention
- Numeric prefixes indicate execution order (`0_`, `1_`, `2_`, ...)
- Stage scripts are grouped by subsystem: `rec/`, `dock/`, `com/`
- Shared libraries and infrastructure helpers are in `infra/`
- Wrapper entrypoint is `scripts/run_pipeline.sh`

## Wrapper Entry Point

- `run_pipeline.sh` - Unified pipeline wrapper
  - Supports `--stage`, `--config`, `--ligand`, `--dry-run`, `--help`, `--list-stages`
  - Dispatches to all implemented stage scripts across `rec/`, `dock/`, and `com/`
  - Validates required config sections per stage
  - Logs stage start/end timestamps

## Receptor Ensemble Generation (`scripts/rec/`) — IMPLEMENTED

- `0_prep.sh` - Prepare receptor, protonate, solvate/ionize, and submit equilibration
- `1_pr_rec.sh` - Submit parallel receptor production MD (Slurm array)
- `3_ana.sh` - Receptor trajectory conversion + RMSD/RMSF analysis
- `4_cluster.sh` - Cluster merged trajectory and export ensemble conformations
- `5_align.py` - Align receptor ensemble structures to a reference using MDAnalysis

## Docking Workflow (`scripts/dock/`) — IMPLEMENTED

### Ligand Conversion
- `0_gro2mol2.sh` - Batch GRO(+ITP/TOP) to MOL2 conversion wrapper
- `0_gro_itp_to_mol2.py` - Generalized GRO+ITP/TOP to MOL2 converter core
- `gro_itp_to_mol2.py` - Import compatibility wrapper module
- `0_sdf2gro.sh` - Batch SDF to GRO conversion wrapper (Open Babel)

### Receptor Preparation
- `1_rec4dock.sh` - Copy/symlink receptor ensemble into docking workspace; GRO→PDB conversion

### Docking Execution
- `2_gnina.sh` - Unified gnina launcher for `blind`, `targeted`, and `test` modes

### Post-Docking Analysis
- `3_dock_report.sh` - Parse SDF scores and generate ranked docking reports (csv/text)

### Docking-to-Complex Conversion
- `4_dock2com.sh` - New-ligand docked-pose to complex topology wrapper
- `4_dock2com_ref.sh` - Reference-ligand docked-pose to complex topology wrapper
- `4_dock2com_1.py` - SDF pose selection and conversion helper
- `4_dock2com_2.py` - Topology assembly core
- `4_dock2com_2.1.py` - ITP parsing utilities
- `4_dock2com_2.2.1.py` - Position restraint generation utility
- `dock2com_2_1.py` - Import compatibility wrapper module

## Complex MD / MM-PBSA / Analysis (`scripts/com/`) — IMPLEMENTED

### System Preparation and Production
- `0_prep.sh` - Unified AMBER/CHARMM complex preparation
- `1_pr_prod.sh` - Equilibration + production MD submission with dependencies

### MM/PBSA Pipeline
- `2_run_mmpbsa.sh` - Orchestrator for trajectory prep + MM/PBSA submissions
- `2_trj4mmpbsa.sh` - Trajectory and index preparation for MM/PBSA chunks
- `2_sub_mmpbsa.sh` - Slurm array submission for MM/PBSA chunks
- `2_mmpbsa.sh` - Chunk-level MM/PBSA execution wrapper

### Complex Trajectory Analysis
- `3_ana.sh` - Unified GROMACS + MDAnalysis analysis entrypoint
- `3_com_ana_trj.py` - Advanced trajectory analysis core
- `3_selection_defaults.py` - Standard analysis selection presets

### Supporting Utilities
- `bypass_angle_type3.py` - AMBER topology angle-type bypass utility
- `4_fp.py` - Fingerprint analysis utility core
- `4_cal_fp.sh` - Fingerprint pipeline wrapper
- `5_arc_sel.sh` - Archive-selection workflow helper
- `5_rerun_sel.sh` - Rerun-selection workflow helper

## Infrastructure / Shared Utilities (`scripts/infra/`)

- `common.sh` - Common shell helpers (logging, validation, execution, Slurm helpers)
- `config_loader.sh` - INI loader and accessors (`load_config`, `get_config`, `require_config`)
- Python infra modules from Phase 1 are retained under `scripts/infra/*.py`

## Config Template Reference

- `config.ini.template` is the canonical parameter reference for v1 pipeline runs.
- It documents all currently used sections:
  - `[general]`
  - `[slurm]`
  - `[receptor]`
  - `[dock]`
  - `[docking]`
  - `[dock2com]`
  - `[dock2com_ref]`
  - `[complex]`
  - `[production]`
  - `[mmpbsa]`
  - `[analysis]`
- It also includes optional utility sections consumed by implemented helper scripts:
  - `[fingerprint]`
  - `[archive]`
  - `[rerun]`

## Implementation Status Summary

- Receptor scripts implemented: **5**
- Docking scripts/modules implemented: **14** (excluding `__init__.py`)
- Complex scripts/modules implemented: **14**
- Unified wrapper implemented: **1** (`run_pipeline.sh`)

**v1 core pipeline scope gaps:** None.
