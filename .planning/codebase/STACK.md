# Technology Stack

**Analysis Date:** 2026-04-19

## Languages

**Primary:**
- Bash - primary workflow orchestration language for stage runners in `scripts/run_pipeline.sh`, `scripts/rec/*.sh`, `scripts/dock/*.sh`, `scripts/com/*.sh`, and `scripts/commands/*.sh`
- Python >=3.11 - analysis, conversion, agent, and infrastructure code in `scripts/agents/*.py`, `scripts/infra/*.py`, `scripts/rec/5_align.py`, `scripts/dock/*.py`, and `scripts/com/*.py`; version floor is declared in `scripts/env.yml`

**Secondary:**
- INI - runtime configuration format in `scripts/config.ini.template` and workspace configs such as `work/test/config.ini`
- YAML - Conda environment and automation metadata in `scripts/env.yml` and `.github/dependabot.yml`
- JSON - OpenCode configuration in `opencode.json` and Node plugin metadata in `.opencode/package.json`
- Markdown - operational and workflow documentation in `README.md`, `WORKFLOW.md`, `AGENTS.md`, and `docs/GUIDE.md`

## Runtime

**Environment:**
- Conda-managed scientific CLI/runtime environment named `autoEnsmblDockMD` from `scripts/env.yml`; activated by `scripts/setenv.sh`
- Python >=3.11 for Python modules and CLIs loaded by `python -m scripts.agents` in `scripts/commands/common.sh` and direct Python stage scripts in `scripts/run_pipeline.sh`
- POSIX shell environment with `bash` entrypoints throughout `scripts/`

**Package Manager:**
- Conda - version not pinned in repo; environment spec is `scripts/env.yml`
- pip - secondary installer inside `scripts/env.yml` for `gmx_MMPBSA` and related Amber/MM-PBSA packages
- npm - plugin-only package manager for OpenCode support under `.opencode/package.json`
- Lockfile: present for Node plugin layer in `.opencode/package-lock.json`; Conda environment is pinned by package versions in `scripts/env.yml`

## Frameworks

**Core:**
- No web framework detected; use the script-first pipeline orchestrated by `scripts/run_pipeline.sh`
- MDAnalysis 2.7.0 - trajectory analysis and structure alignment in `scripts/com/3_com_ana_trj.py`, `scripts/com/4_fp.py`, and `scripts/rec/5_align.py`; pinned in `scripts/env.yml`
- OpenCode agent layer - experimental orchestration configured by `opencode.json`, `.opencode/package.json`, and Python agent entrypoint `scripts/agents/__main__.py`

**Testing:**
- Not detected in repository manifests or root-level test config files; no `pytest`, `vitest`, `jest`, or GitHub Actions test workflow is present in the explored files

**Build/Dev:**
- Conda environment spec in `scripts/env.yml` - reproducible scientific runtime setup
- Dependabot for Conda dependency maintenance in `.github/dependabot.yml`
- No compiled build pipeline, bundler, or packaging step detected for the main workflow code

## Key Dependencies

**Critical:**
- `mdanalysis=2.7.0` - core Python analysis/alignment library used by `scripts/rec/5_align.py`, `scripts/com/3_com_ana_trj.py`, and `scripts/com/4_fp.py`
- `numpy=1.26.4` - numeric backbone for trajectory metrics and fingerprint matrices in `scripts/com/3_com_ana_trj.py` and `scripts/com/4_fp.py`
- `matplotlib=3.7.3` - plot generation for analysis outputs in `scripts/com/3_com_ana_trj.py` and `scripts/com/4_fp.py`
- `ambertools=23.6` - Amber ecosystem tooling required by the MM/PBSA path declared in `scripts/env.yml`
- `gmx_MMPBSA` - MM/PBSA engine invoked by `scripts/com/2_mmpbsa.sh`; installed through the `pip` block in `scripts/env.yml`

**Infrastructure:**
- `gnina` - external docking engine required by `scripts/dock/2_gnina.sh`; documented in `README.md` and `WORKFLOW.md`
- `GROMACS >= 2022` - external MD engine required across receptor, complex, and analysis scripts such as `scripts/rec/0_prep.sh`, `scripts/com/1_pr_prod.sh`, and `scripts/com/3_ana.sh`
- `pdb2pqr` and `propka` - receptor protonation tooling used by `scripts/rec/0_prep.sh`; available through `scripts/env.yml`
- `jq` - shell JSON assembly/parsing helper in `scripts/commands/common.sh` and `scripts/commands/status.sh`
- `@opencode-ai/plugin@1.4.0` - OpenCode plugin dependency declared in `.opencode/package.json`
- Optional `obabel` / Open Babel - ligand conversion fallback used by `scripts/dock/0_sdf2gro.sh` and `scripts/dock/4_dock2com_1.py`; documented as optional in `README.md` and `WORKFLOW.md`
- Optional `rdkit` - runtime fallback for SDF-to-GRO conversion in `scripts/dock/4_dock2com_1.py`; not pinned in `scripts/env.yml`

## Configuration

**Environment:**
- Source `scripts/setenv.sh` before running scripts; it activates the `autoEnsmblDockMD` Conda environment
- Copy `scripts/config.ini.template` into a workspace config such as `work/test/config.ini`; the runtime expects sections `[general]`, `[slurm]`, `[receptor]`, `[dock]`, `[docking]`, `[dock2com]`, `[dock2com_ref]`, `[complex]`, `[production]`, `[mmpbsa]`, and `[analysis]`
- Bash scripts load INI values through `scripts/infra/config_loader.sh`; environment-variable overrides are supported by generated names such as `GENERAL_WORKDIR`, `SLURM_PARTITION`, `DOCKING_MODE`, and `MMPBSA_MPI_RANKS`
- Python agents load the same INI file through `scripts/infra/config.py` and `scripts/agents/__main__.py`

**Build:**
- Runtime manifests: `scripts/env.yml`, `.opencode/package.json`
- Workflow entrypoints: `scripts/run_pipeline.sh`, `scripts/commands/*.sh`, `scripts/agents/__main__.py`
- OpenCode config: `opencode.json`
- Automation config: `.github/dependabot.yml`

## Platform Requirements

**Development:**
- Conda environment from `scripts/env.yml`
- `bash`, `python`, and `jq` available for script and agent entrypoints in `scripts/commands/common.sh` and `scripts/run_pipeline.sh`
- Scientific executables available on `PATH`: `gmx`, `gnina`, `gmx_MMPBSA`, and `pdb2pqr`; optional `obabel` for conversion helpers

**Production:**
- Primary execution target is a local or HPC filesystem workspace driven by `scripts/run_pipeline.sh`
- Heavy compute stages assume Slurm availability via `sbatch`, `squeue`, and `sacct` in `scripts/infra/common.sh`, `scripts/dock/2_gnina.sh`, `scripts/rec/0_prep.sh`, and `scripts/com/1_pr_prod.sh`
- GPU-capable GROMACS/gnina environment is expected for docking and MD stages, as documented in `README.md`, `WORKFLOW.md`, and `docs/GUIDE.md`

---

*Stack analysis: 2026-04-19*
