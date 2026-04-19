# Critical Code Review Report

**Analysis Date:** 2026-04-19
**Method:** Static scan only. No workflow commands or simulations were executed.

## Critical Findings

### 1) `run_pipeline.sh` cannot target a single ligand for `com_ana`
- **Files:** `scripts/run_pipeline.sh:82-84`, `scripts/run_pipeline.sh:215-228`, `scripts/com/3_ana.sh:89-110`
- **Finding:** `run_pipeline.sh` marks `com_ana` as `target` mode and forwards `--target`, but `scripts/com/3_ana.sh` only accepts `--ligand`.
- **Impact:** `run_pipeline.sh --stage com_ana --ligand <id>` fails deterministically with `Unknown option: --target`.
- **Reasoning:** The CLI contract between dispatcher and callee is inconsistent.

### 2) Dock-to-complex wrappers require `com.gro`, but the wrapper chain does not create it
- **Files:** `scripts/dock/4_dock2com.sh:245-266`, `scripts/dock/4_dock2com_ref.sh:267-288`, `scripts/dock/4_dock2com_1.py:82-96`, `scripts/dock/4_dock2com_2.py:101-168`
- **Finding:** The wrappers run only SDF→GRO conversion and topology assembly, then require `com.gro`/`complex.gro`. Neither Python helper writes a complex coordinate file.
- **Impact:** New/reference dock-to-complex conversion can fail unless a pre-existing complex GRO is already present in the ligand folder.
- **Reasoning:** The wrapper validates an artifact that its own execution path never generates.

### 3) `com/0_prep.sh` builds `sys.top` without including receptor topology content
- **Files:** `scripts/com/0_prep.sh:106-107`, `scripts/com/0_prep.sh:265-281`, `scripts/com/0_prep.sh:312-335`
- **Finding:** `RECEPTOR_TOP` is required but never incorporated into `sys.top`. `build_sys_top()` writes only the force-field include and ligand ITP include, then declares `[ molecules ] Protein 1`.
- **Impact:** `gmx solvate`, `grompp`, and downstream MD can fail or use an invalid topology because the protein moleculetype/topology definition is missing from `sys.top`.
- **Reasoning:** The generated topology references a protein molecule count without including the receptor molecule definition.

### 4) MM/PBSA group selection is fixed while index creation is dynamic
- **Files:** `scripts/com/2_trj4mmpbsa.sh:140-167`, `scripts/com/2_trj4mmpbsa.sh:187-191`, `scripts/com/2_mmpbsa.sh:95-99`, `scripts/com/2_mmpbsa.sh:181-188`, `scripts/config.ini.template:282-285`
- **Finding:** `2_trj4mmpbsa.sh` dynamically creates the complex group in `index.ndx`, but `2_mmpbsa.sh` still passes fixed `-cg` values from config defaults (`1` and `12`).
- **Impact:** MM/PBSA can target the wrong receptor/ligand groups when index ordering changes across systems, causing silent science errors rather than clean failures.
- **Reasoning:** Dynamic index generation is not propagated to the consumer that requires exact group IDs.

## High-Risk Correctness Concerns

### 5) Ligand position restraints assume GRO atom numbering matches ligand ITP atom numbering
- **Files:** `scripts/dock/4_dock2com_2.2.1.py:15-42`, `scripts/dock/4_dock2com.sh:256-268`, `scripts/dock/4_dock2com_ref.sh:278-290`
- **Finding:** `posre_lig.itp` is generated from `best.gro` atom IDs only. There is no validation that SDF-derived GRO atom order matches the ligand ITP atom order used in `sys.top`.
- **Impact:** Position restraints can bind the wrong atoms if the SDF conversion order differs from the topology order.
- **Reasoning:** The workflow couples coordinate-derived atom IDs to topology-derived restraints without any atom-count or atom-order cross-check.

### 6) Advanced RMSD is not alignment-corrected
- **Files:** `scripts/com/3_com_ana_trj.py:90-105`, `scripts/com/3_ana.sh:162-187`
- **Finding:** `compute_rmsd()` measures displacement from the first frame directly and does not superpose frames before RMSD calculation.
- **Impact:** Reported `rmsd_timeseries.csv` can overstate motion and disagree with the aligned GROMACS RMSD produced by `3_ana.sh`.
- **Reasoning:** This is raw coordinate drift, not canonical structural RMSD.

## Performance / Scaling Findings

### 7) Contact analysis uses nested residue-by-frame distance loops
- **Files:** `scripts/com/3_com_ana_trj.py:142-149`, `scripts/com/4_fp.py:96-104`
- **Finding:** Both analyses iterate over every frame and every receptor residue, then run `MDAnalysis.lib.distances.distance_array(...)` per residue.
- **Impact:** Runtime scales poorly with long trajectories, large proteins, or many ligands; this is the main hot path for analysis slowdown.
- **Reasoning:** The implementation is effectively `O(frames × residues × residue_atoms × ligand_atoms)` and repeats small distance kernels thousands of times instead of vectorizing/contact-caching.

## Safety / Security Concerns

### 8) Config-derived shell fragments are embedded directly into generated batch scripts
- **Files:** `scripts/dock/2_gnina.sh:316-379`
- **Finding:** Values such as `SCORING`, `MIN_RMSD_FILTER`, `AUTOBOX_ADD`, `CPU`, and related config-derived fragments are interpolated directly into the Slurm heredoc command body.
- **Impact:** If config files are untrusted or user-supplied without validation, this becomes shell injection into submitted jobs.
- **Reasoning:** The script treats config as trusted code, not trusted data.

## Secondary Observations

### 9) `water_model` is configured but not actually used during solvation
- **Files:** `scripts/com/0_prep.sh:114`, `scripts/com/0_prep.sh:327-330`
- **Finding:** `water_model` is read from config, but `gmx solvate` is hard-wired to `-cs spc216`.
- **Impact:** Configuration can claim one solvent model while execution uses another, which is a unit/protocol consistency risk.

### 10) Environment bootstrap is brittle for non-interactive shells
- **Files:** `scripts/infra/common.sh:164-169`, `scripts/setenv.sh:9-10`
- **Finding:** `init_script()` always sources `scripts/setenv.sh`, and `setenv.sh` unconditionally runs `conda activate autoEnsmblDockMD`.
- **Impact:** Any shell without pre-initialized conda functions can fail before stage logic starts.
- **Reasoning:** Environment activation is assumed rather than validated.

## Recommended Priority Order
1. Fix `scripts/com/0_prep.sh` topology generation.
2. Fix `scripts/com/2_mmpbsa.sh` / `scripts/com/2_trj4mmpbsa.sh` group-ID propagation.
3. Fix `scripts/dock/4_dock2com*.sh` artifact contract around `com.gro`.
4. Fix `scripts/run_pipeline.sh` argument mismatch for `com_ana`.
5. Add ligand GRO↔ITP atom-order validation before generating `posre_lig.itp`.
