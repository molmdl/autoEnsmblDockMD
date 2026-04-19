# autoEnsmblDockMD Workflow Reference

Definitive script-level guide for manual execution of receptor → docking → complex MD → MM/PBSA.

## Overview

The pipeline supports two modes:

- **Mode A (reference pocket, AMBER-oriented):** targeted/test docking around a reference ligand, AMBER-like topology handling.
- **Mode B (blind docking, CHARMM36m/CGenFF-oriented):** blind docking and CHARMM-style topology handling.

Primary orchestrator: `scripts/run_pipeline.sh`.
Always initialize environment before running stage scripts:

```bash
source ./scripts/setenv.sh
```

## Prerequisites

### Required software

- **Conda** (recommended environment manager)
  - [Miniconda](https://www.anaconda.com/docs/getting-started/miniconda/install/overview)) 
- **GROMACS ≥ 2022** (note: the Amber FF provided in the example is for gromacs < 2025, tested with 2023.5)
  - [GROMACS official website](https://www.gromacs.org/)
- **gnina** (tested with v1.1, since our hardware CUDA does not support newer version)
  - [Gnina github](https://github.com/gnina/gnina)
- **gmx_MMPBSA** (automatically installed if you create the conda environment using env.yml)
  - [gmx_MMPBSA Documentation](https://valdes-tresanco-ms.github.io/gmx_MMPBSA/dev/)
- Python dependencies used by scripts (e.g., MDAnalysis), also automatically installed with env.yml.
- Optional: Open Babel for `scripts/dock/0_sdf2gro.sh`

### Required user inputs

- Receptor PDB (`[receptor] input_pdb`)
- Ligand inputs for chosen mode (plus topology assets as needed)
- Force-field files and ligand parameter files
- MDP files for receptor and complex stages (`[receptor] mdp_dir`, `[complex] mdp_dir`)
- Runtime config copied from `scripts/config.ini.template`

### Required config sections

`[general]`, `[slurm]`, `[receptor]`, `[dock]`, `[docking]`, `[dock2com]`, `[dock2com_ref]`,
`[complex]`, `[production]`, `[mmpbsa]`, `[analysis]`.

Optional utility sections: `[fingerprint]`, `[archive]`, `[rerun]`.

## Workspace Structure

Typical workspace (`[general] workdir`, e.g. `./work/test`):

```text
work/test/
├── rec/
├── dock/
├── com/
├── mdp/rec/
├── mdp/com/
├── ref/                  # optional reference ligand assets
└── config.ini
```

Script roots:

- `scripts/rec/`
- `scripts/dock/`
- `scripts/com/`
- `scripts/infra/`

## Stage Reference

### Stage 0 — Input preparation

**Purpose:** validate config, paths, and file readiness before compute-heavy steps.

**Scripts:** `scripts/infra/config_loader.sh`, `scripts/infra/common.sh`, `scripts/run_pipeline.sh --list-stages`.

**Inputs:** `config.ini` from `scripts/config.ini.template`; valid `[general] workdir`, `[receptor] input_pdb`, MDP/FF paths.

**Outputs:** validated preconditions and resolved configuration for downstream stages.

**Mode notes:** A needs reference-ligand assets; B needs blind-docking ligand/CHARMM assets.

### Stage 1 — Receptor ensemble generation

**Purpose:** build receptor system, sample trajectories, and extract ensemble conformers.

**Scripts (order):**

1. `scripts/rec/0_prep.sh`
2. `scripts/rec/1_pr_rec.sh`
3. `scripts/rec/3_ana.sh`
4. `scripts/rec/4_cluster.sh`
5. `scripts/rec/5_align.py` (optional)

**Inputs/config:** `[receptor] workdir, input_pdb, ff, water_model, mdp_dir, n_trials, ensemble_size`, plus `analysis_*`, `cluster_*`, `align_*`; `[slurm] partition, ntomp, gpus`.

**Outputs:** receptor topology/coordinates, per-trial trajectories, merged/fit trajectories, clustered `rec*` conformers, optional aligned structures.

**Mode notes:** A often requires alignment to stabilize pocket frame; B uses clustered conformers directly.

### Stage 2 — Docking (conversion → gnina → scoring → pose selection)

**Purpose:** prepare docking inputs, run gnina on receptor ensemble, and rank/select poses.

**Scripts (order):**

1. `scripts/dock/0_gro2mol2.sh`
2. `scripts/dock/0_gro_itp_to_mol2.py`
3. `scripts/dock/0_sdf2gro.sh` (optional utility)
4. `scripts/dock/1_rec4dock.sh`
5. `scripts/dock/2_gnina.sh`
6. `scripts/dock/3_dock_report.sh`
7. `scripts/dock/4_dock2com_1.py`

**Inputs/config:** `[dock] ligand_dir, output_dir, gro_pattern, converter_script`; `[docking] dock_dir, ligands_dir, mode, receptor_dir, receptor_prefix, autobox_*`; `[docking] reference_ligand` for Mode A targeted/test.

**Outputs:** MOL2 docking inputs, receptor PDB conformers, gnina SDF/log outputs, ranked docking report, selected pose files.

**Mode notes:** A uses `mode=targeted`/`mode=test`; B uses `mode=blind`.

### Stage 3 — Complex setup (dock2com → topology assembly → solvation/ions/minimization)

**Purpose:** convert selected docked poses into MD-ready receptor-ligand complex systems.

**Scripts (order):**

1. `scripts/dock/4_dock2com.sh`
2. `scripts/dock/4_dock2com_ref.sh`
3. `scripts/dock/4_dock2com_2.py`
4. `scripts/dock/4_dock2com_2.1.py`
5. `scripts/dock/4_dock2com_2.2.1.py`
6. `scripts/com/0_prep.sh`
7. `scripts/com/bypass_angle_type3.py` (when needed)

**Inputs/config:** `[dock2com]` / `[dock2com_ref]` (FF mode, patterns, rec_top, pose_index); `[complex] mode, receptor_gro, receptor_top, ff_include, mdp_dir, em_mdp, pr_pos_mdp`.

**Outputs:** ligand-specific complex folders with `com.gro`, `sys.top`, `index.ndx`, minimized/equilibrated structures, `posre_lig.itp`, and bypassed topologies if required.

**Mode notes:** A usually uses AMBER branch and bypass helper; B uses CHARMM/CGenFF branch.

### Stage 4 — MD simulation (equilibration chain + production)

**Purpose:** run complex equilibration chain and production trajectories per ligand/trial.

**Script:** `scripts/com/1_pr_prod.sh`.

**Inputs/config:** `[production] n_trials, n_equilibration_stages, pr0_mdp, pr_mdp_prefix, production_mdp, ntomp, partition, gpus`.

**Outputs:** production trajectories/topologies (`prod_*.xtc`, `prod_*.tpr`) and run logs.

**Mode notes:** mechanics are shared; topology differences originate from Stage 3.

### Stage 5 — MM/PBSA (trajectory processing → binding energies)

**Purpose:** preprocess trajectories and run chunked MM/PBSA calculations.

**Scripts (order):**

1. `scripts/com/2_run_mmpbsa.sh`
2. `scripts/com/2_trj4mmpbsa.sh`
3. `scripts/com/2_sub_mmpbsa.sh`
4. `scripts/com/2_mmpbsa.sh`

**Inputs/config:** `[mmpbsa] workdir, ligand_dir, n_chunks, chunk_dir_prefix, source_xtc_pattern, source_tpr_pattern, mmpbsa_input, amber_topology_file, charmm_topology_file`.

**Outputs:** chunk folders (`mmpbsa_*`), processed trajectories, MM/PBSA result files/summaries.

**Mode notes:** A resolves AMBER topology path; B resolves CHARMM topology path.

### Stage 6 — Analysis (RMSD, RMSF, contacts, H-bonds, fingerprints)

**Purpose:** generate standard and optional advanced metrics for complex trajectories.

**Scripts (order):**

1. `scripts/com/3_ana.sh`
2. `scripts/com/3_com_ana_trj.py`
3. `scripts/com/3_selection_defaults.py`
4. `scripts/com/4_cal_fp.sh`
5. `scripts/com/4_fp.py`
6. `scripts/com/5_arc_sel.sh` (optional)
7. `scripts/com/5_rerun_sel.sh` (optional)

**Inputs/config:** `[analysis] run_rmsd, run_rmsf, run_hbond, run_advanced, contact_cutoff, selections`; optional `[fingerprint]`, `[archive]`, `[rerun]`.

**Outputs:** per-ligand analysis outputs/plots, optional fingerprint matrices/heatmaps, optional archive/rerun helper outputs.

**Mode notes:** same analysis scripts in A/B; interpretation depends on upstream mode/FF branch.

## Script Inventory Completeness Notes

Additional modules included in implemented inventory:

- `scripts/dock/gro_itp_to_mol2.py`
- `scripts/dock/dock2com_2_1.py`
- `scripts/dock/__init__.py`
- `scripts/infra/config.py`
- `scripts/infra/state.py`
- `scripts/infra/checkpoint.py`
- `scripts/infra/executor.py`
- `scripts/infra/monitor.py`
- `scripts/infra/verification.py`
- `scripts/infra/__init__.py`

## Pipeline Flow Diagram

```text
Inputs (receptor + ligands + FF + MDP + config.ini)
                    |
                    v
[0] Input preparation
   scripts/infra/config_loader.sh + scripts/infra/common.sh
                    |
                    v
[1] Receptor ensemble generation
   scripts/rec/0_prep.sh -> 1_pr_rec.sh -> 3_ana.sh -> 4_cluster.sh -> 5_align.py(optional)
                    |
                    v
              Mode decision
          +--------------------+
          | A: targeted/test   |
          | B: blind           |
          +--------------------+
                    |
                    v
[2] Docking
   scripts/dock/0_gro2mol2.sh -> 0_gro_itp_to_mol2.py -> 1_rec4dock.sh
   -> 2_gnina.sh -> 3_dock_report.sh -> 4_dock2com_1.py
                    |
                    v
[3] Complex setup
   scripts/dock/4_dock2com*.sh -> 4_dock2com_2*.py -> scripts/com/0_prep.sh
   -> scripts/com/bypass_angle_type3.py (if needed)
                    |
                    v
[4] MD simulation
   scripts/com/1_pr_prod.sh
                    |
                    v
[5] MM/PBSA
   scripts/com/2_run_mmpbsa.sh -> 2_trj4mmpbsa.sh -> 2_sub_mmpbsa.sh -> 2_mmpbsa.sh
                    |
                    v
[6] Analysis
   scripts/com/3_ana.sh -> 3_com_ana_trj.py -> 3_selection_defaults.py
   -> 4_cal_fp.sh/4_fp.py -> optional 5_arc_sel.sh and 5_rerun_sel.sh
                    |
                    v
Outputs: docking ranks + complex MD trajectories + MM/PBSA energies + analysis reports
```

## Minimal Execution Examples

```bash
bash scripts/run_pipeline.sh --config config.ini --list-stages
bash scripts/run_pipeline.sh --config config.ini
bash scripts/run_pipeline.sh --config config.ini --stage dock_run
```
