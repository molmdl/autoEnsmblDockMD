# External Integrations

**Analysis Date:** 2026-04-19

## APIs & External Services

**Computational chemistry engines:**
- GROMACS - system preparation, solvation, ionization, minimization, production MD, and built-in analyses
  - SDK/Client: CLI `gmx`
  - Auth: None detected
  - Integration points: `scripts/rec/0_prep.sh`, `scripts/rec/1_pr_rec.sh`, `scripts/com/0_prep.sh`, `scripts/com/1_pr_prod.sh`, `scripts/com/2_trj4mmpbsa.sh`, and `scripts/com/3_ana.sh`
- gnina - docking engine for `blind`, `targeted`, and `test` modes
  - SDK/Client: CLI `gnina`
  - Auth: None detected
  - Integration points: `scripts/dock/2_gnina.sh` and its config surface in `scripts/config.ini.template`
- gmx_MMPBSA - chunked binding free-energy calculations
  - SDK/Client: CLI `gmx_MMPBSA` launched through `mpirun`
  - Auth: None detected
  - Integration points: `scripts/com/2_mmpbsa.sh`, `scripts/com/2_sub_mmpbsa.sh`, and `scripts/com/mmpbsa.in`

**Structure preparation and conversion:**
- pdb2pqr / pdb2pqr30 - receptor protonation before `pdb2gmx`
  - SDK/Client: CLI `pdb2pqr` or `pdb2pqr30`
  - Auth: None detected
  - Integration points: `scripts/rec/0_prep.sh`
- Open Babel - optional format conversion for ligand preparation
  - SDK/Client: CLI `obabel`
  - Auth: None detected
  - Integration points: `scripts/dock/0_sdf2gro.sh` and the fallback branch in `scripts/dock/4_dock2com_1.py`
- RDKit - optional in-process SDF reader for pose-to-GRO conversion
  - SDK/Client: Python import `rdkit`
  - Auth: None detected
  - Integration points: `scripts/dock/4_dock2com_1.py`

**Cluster and execution platform:**
- Slurm - batch scheduling, dependency chaining, queue inspection, and status polling
  - SDK/Client: CLI `sbatch`, `squeue`, `sacct`, and `scancel`
  - Auth: Cluster identity/account handling is external to the repository
  - Integration points: `scripts/infra/common.sh`, `scripts/infra/executor.py`, `scripts/rec/0_prep.sh`, `scripts/dock/2_gnina.sh`, `scripts/com/0_prep.sh`, `scripts/com/1_pr_prod.sh`, `scripts/com/2_sub_mmpbsa.sh`, and `scripts/com/5_rerun_sel.sh`
- MPI runtime - multi-rank execution for MM/PBSA
  - SDK/Client: CLI `mpirun`
  - Auth: None detected
  - Integration points: `scripts/com/2_mmpbsa.sh`

**Agent/editor tooling:**
- OpenCode - experimental slash-command and agent orchestration layer
  - SDK/Client: `@opencode-ai/plugin` in `.opencode/package.json`
  - Auth: Not stored in the repository
  - Integration points: `opencode.json`, `.opencode/package.json`, `scripts/commands/common.sh`, `scripts/agents/__main__.py`, `AGENTS.md`, and namespaced slash-command wrappers in `scripts/commands/aedmd-*.sh`
- GitHub Dependabot - dependency update automation for the Conda manifest
  - SDK/Client: `.github/dependabot.yml`
  - Auth: Managed externally by GitHub

**Remote HTTP/SaaS APIs:**
- Not detected - explored Python and shell code under `scripts/` does not contain active `requests`, `urllib`, webhook, or external REST client usage

## Data Storage

**Databases:**
- Not detected
  - Connection: Not applicable
  - Client: Not applicable

**File Storage:**
- Local filesystem only
  - Primary locations: `work/`, `expected/`, `.planning/`, `.handoffs/`, `.gates/`, and `.debug_reports/`
  - Connection: Workspace paths derived from `[general] workdir` in `scripts/config.ini.template`
  - Client: Native shell/Python file I/O in `scripts/infra/common.sh`, `scripts/infra/verification.py`, and `scripts/agents/*.py`

**Caching:**
- None

## Authentication & Identity

**Auth Provider:**
- Custom / none
  - Implementation: the workflow uses local files, external CLIs, and HPC scheduler context; no login flow, token exchange, OAuth client, or user/session model is defined in `scripts/`, `README.md`, or `AGENTS.md`

## Monitoring & Observability

**Error Tracking:**
- None

**Logs:**
- Timestamped shell logging via `log_info`, `log_warn`, and `log_error` in `scripts/infra/common.sh`
- Structured log parsing utilities in `scripts/infra/monitor.py`
- Agent handoff records in workspace `.handoffs/*.json` written by `scripts/commands/common.sh`
- Verification-gate state in workspace `.gates/*_gate.json` managed by `scripts/infra/verification.py`
- Debug reports in workspace `.debug_reports/*.json` written by `scripts/agents/debugger.py`

## CI/CD & Deployment

**Hosting:**
- Not applicable
  - This repository is a local/HPC execution toolkit run via `scripts/run_pipeline.sh`, not a deployed service

**CI Pipeline:**
- None detected
  - No `.github/workflows/*` pipeline files are present
  - Dependency automation only: `.github/dependabot.yml`

## Environment Configuration

**Required env vars:**
- `CONDA_DEFAULT_ENV` - operationally expected to resolve to `autoEnsmblDockMD` after sourcing `scripts/setenv.sh`
- `SLURM_JOB_ID` - used for backend detection in `scripts/infra/config.py` and `scripts/infra/executor.py`
- `SLURM_TMPDIR` and `SLURM_NODELIST` - also used by `scripts/infra/executor.py` to detect Slurm execution context
- `SECTION_KEY`-style overrides generated by `scripts/infra/config_loader.sh`; use variables such as `GENERAL_WORKDIR`, `SLURM_PARTITION`, `DOCKING_MODE`, `COMPLEX_MODE`, and `MMPBSA_MPI_RANKS` when overriding INI values from the environment

**Secrets location:**
- Not detected
  - Runtime configuration lives in workspace `config.ini` files created from `scripts/config.ini.template`
  - No `.env`, credential JSON, token variables, or secret manager integration is present in the explored repository files

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None

---

*Integration audit: 2026-04-19*
