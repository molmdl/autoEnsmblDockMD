# Technology Stack

**Analysis Date:** 2026-04-19

## Languages

**Primary:**
- Bash Not pinned - primary workflow orchestration in `scripts/run_pipeline.sh`, `scripts/rec/*.sh`, `scripts/dock/*.sh`, `scripts/com/*.sh`, `scripts/infra/*.sh`, and `scripts/commands/*.sh`
- Python >=3.11 - analysis, conversion, agent, and infrastructure code in `scripts/com/*.py`, `scripts/dock/*.py`, `scripts/rec/5_align.py`, `scripts/agents/*.py`, and `scripts/infra/*.py`; version floor is declared in `scripts/env.yml`

**Secondary:**
- INI Not pinned - runtime configuration format in `scripts/config.ini.template`, loaded by `scripts/infra/config_loader.sh` and `scripts/infra/config.py`
- YAML Not pinned - Conda/runtime metadata in `scripts/env.yml` and dependency automation config in `.github/dependabot.yml`
- JSON Not pinned - OpenCode/editor configuration in `opencode.json`, `.opencode/package.json`, and `.opencode/package-lock.json`

## Runtime

**Environment:**
- Conda environment `autoEnsmblDockMD` from `scripts/env.yml`; activated by `scripts/setenv.sh`
- Bash-driven local/HPC shell runtime for all stage entrypoints under `scripts/`
- Python CLI runtime for agent dispatch in `scripts/commands/common.sh` and Python stage scripts launched by `scripts/run_pipeline.sh`

**Package Manager:**
- Conda Version not pinned - primary environment manager defined by `scripts/env.yml`
- pip Version not pinned - secondary installer inside `scripts/env.yml` for `gmx_MMPBSA` and related Amber packages
- npm Version not pinned - plugin-only package manager for `.opencode/package.json`
- Lockfile: present in `.opencode/package-lock.json`; no root-level Node or Python lockfile is detected for the main workflow code

## Frameworks

**Core:**
- Script-first pipeline Not applicable - the main execution model is the stage wrapper `scripts/run_pipeline.sh`, not a web/application framework
- MDAnalysis 2.7.0 - structure alignment and trajectory analysis in `scripts/rec/5_align.py`, `scripts/com/3_com_ana_trj.py`, `scripts/com/4_fp.py`, and `scripts/com/3_selection_defaults.py`
- OpenCode agent layer via `@opencode-ai/plugin` 1.4.0 - experimental orchestration configured in `opencode.json`, `.opencode/package.json`, `AGENTS.md`, and `scripts/commands/*.sh`

**Testing:**
- Not detected - no `pytest`, `jest`, `vitest`, `unittest` runner config, or `.github/workflows/*` CI test workflow is present in the explored repository files

**Build/Dev:**
- Conda environment spec Not pinned - reproducible scientific runtime setup in `scripts/env.yml`
- Dependabot Not pinned - dependency update automation for the Conda ecosystem in `.github/dependabot.yml`
- No compiled build step detected - there is no Dockerfile, Makefile, packaging backend, or frontend bundler in the explored root files

## Key Dependencies

**Critical:**
- `mdanalysis=2.7.0` - required for receptor alignment and advanced complex analysis in `scripts/rec/5_align.py`, `scripts/com/3_com_ana_trj.py`, `scripts/com/4_fp.py`, and `scripts/com/3_selection_defaults.py`
- `numpy=1.26.4` - numeric backbone for RMSD/RMSF/contact and fingerprint calculations in `scripts/com/3_com_ana_trj.py` and `scripts/com/4_fp.py`
- `matplotlib=3.7.3` - non-interactive plot generation in `scripts/com/3_com_ana_trj.py` and `scripts/com/4_fp.py`
- `ambertools=23.6` - Amber-side topology/MM-PBSA support declared in `scripts/env.yml` and used with the AMBER branch documented in `scripts/com/0_prep.sh` and `scripts/com/2_mmpbsa.sh`
- `gmx_MMPBSA` Version not pinned - MM/PBSA engine invoked by `scripts/com/2_mmpbsa.sh`
- `@opencode-ai/plugin@1.4.0` - OpenCode integration dependency declared in `.opencode/package.json`

**Infrastructure:**
- `gmx` External CLI - required across receptor prep, complex prep, MD, and analysis in `scripts/rec/0_prep.sh`, `scripts/com/0_prep.sh`, `scripts/com/1_pr_prod.sh`, `scripts/com/2_trj4mmpbsa.sh`, and `scripts/com/3_ana.sh`
- `gnina` External CLI - docking engine required by `scripts/dock/2_gnina.sh`
- `pdb2pqr` / `pdb2pqr30` External CLI - receptor protonation tool required by `scripts/rec/0_prep.sh`
- `propka` Version from Conda environment - bundled with the protonation toolchain in `scripts/env.yml`
- `obabel` Optional external CLI - ligand conversion helper used by `scripts/dock/0_sdf2gro.sh` and as fallback in `scripts/dock/4_dock2com_1.py`
- `rdkit` Optional Python package - in-process SDF-to-GRO conversion path in `scripts/dock/4_dock2com_1.py`; not pinned in `scripts/env.yml`
- `sbatch` / `squeue` / `sacct` External CLI - Slurm job submission and monitoring used by `scripts/infra/common.sh`, `scripts/dock/2_gnina.sh`, `scripts/rec/0_prep.sh`, and `scripts/com/1_pr_prod.sh`
- `mpirun` External CLI - MPI launcher used for `gmx_MMPBSA` in `scripts/com/2_mmpbsa.sh`
- `jq` External CLI - JSON assembly/parsing for slash-command bridges in `scripts/commands/common.sh` and `scripts/commands/aedmd-status.sh`

## Configuration

**Environment:**
- Source `scripts/setenv.sh` before running workflow or slash-command wrappers; it activates the `autoEnsmblDockMD` Conda environment declared in `scripts/env.yml`
- Create run configs from `scripts/config.ini.template`; active workspaces typically place the file at `work/test/config.ini` or another path passed to `scripts/run_pipeline.sh --config`
- Keep required sections aligned to `scripts/config.ini.template`: `[general]`, `[slurm]`, `[receptor]`, `[dock]`, `[docking]`, `[dock2com]`, `[dock2com_ref]`, `[complex]`, `[production]`, `[mmpbsa]`, and `[analysis]`
- Bash-stage overrides use environment variables generated by `scripts/infra/config_loader.sh`; follow the `SECTION_KEY` convention such as `GENERAL_WORKDIR`, `SLURM_PARTITION`, `DOCKING_MODE`, and `MMPBSA_MPI_RANKS`
- Python-side config loading uses `scripts/infra/config.py` and `scripts/agents/__main__.py`

**Build:**
- Runtime manifests: `scripts/env.yml`, `.opencode/package.json`, `.opencode/package-lock.json`
- Execution entrypoints: `scripts/run_pipeline.sh`, `scripts/commands/*.sh`, and `scripts/agents/__main__.py`
- OpenCode configuration: `opencode.json`
- Dependency automation config: `.github/dependabot.yml`

## Platform Requirements

**Development:**
- Linux/HPC shell environment with Conda available to create `scripts/env.yml`
- `bash`, `python`, and `jq` available for `scripts/run_pipeline.sh` and `scripts/commands/common.sh`
- Scientific executables on `PATH`: `gmx`, `gnina`, `gmx_MMPBSA`, `pdb2pqr`; optional `obabel`; optional `rdkit` for the Python fallback in `scripts/dock/4_dock2com_1.py`
- Workspace layout matching `WORKFLOW.md` and `docs/GUIDE.md`, with user inputs stored under `work/input` or a run-specific `workdir`

**Production:**
- Local filesystem workspace rooted by `[general] workdir` from `scripts/config.ini.template`
- Slurm-backed execution target for heavy stages, with GPU partitions used by `scripts/rec/0_prep.sh`, `scripts/dock/2_gnina.sh`, `scripts/com/0_prep.sh`, and `scripts/com/1_pr_prod.sh`
- CPU-oriented MM/PBSA batch execution through `scripts/com/2_sub_mmpbsa.sh` and MPI execution in `scripts/com/2_mmpbsa.sh`
- No container, SaaS deployment, or web-hosting target detected in `README.md`, `WORKFLOW.md`, or root configuration files

---

*Stack analysis: 2026-04-19*
