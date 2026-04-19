# External Integrations

**Analysis Date:** 2026-04-19

## APIs & External Services

**Computational engines:**
- GROMACS - molecular system preparation, equilibration, production MD, and built-in analysis
  - SDK/Client: CLI `gmx`
  - Auth: None detected
  - Integration points: `scripts/rec/0_prep.sh`, `scripts/rec/1_pr_rec.sh`, `scripts/com/0_prep.sh`, `scripts/com/1_pr_prod.sh`, `scripts/com/2_trj4mmpbsa.sh`, `scripts/com/3_ana.sh`
- gnina - docking engine for `blind`, `targeted`, and `test` docking modes
  - SDK/Client: CLI `gnina`
  - Auth: None detected
  - Integration points: `scripts/dock/2_gnina.sh`, with configuration described in `scripts/config.ini.template`
- gmx_MMPBSA - binding free-energy calculations over prepared chunk trajectories
  - SDK/Client: CLI `gmx_MMPBSA` invoked through `mpirun`
  - Auth: None detected
  - Integration points: `scripts/com/2_mmpbsa.sh`, input template `scripts/com/mmpbsa.in`

**Structure-prep and conversion tools:**
- pdb2pqr / pdb2pqr30 - receptor protonation before GROMACS topology generation
  - SDK/Client: CLI `pdb2pqr` or `pdb2pqr30`
  - Auth: None detected
  - Integration points: `scripts/rec/0_prep.sh`
- Open Babel - optional SDF/GRO conversion path
  - SDK/Client: CLI `obabel`
  - Auth: None detected
  - Integration points: `scripts/dock/0_sdf2gro.sh`, fallback branch in `scripts/dock/4_dock2com_1.py`
- RDKit - optional in-process fallback for SDF-to-GRO conversion
  - SDK/Client: Python import `rdkit`
  - Auth: None detected
  - Integration points: `scripts/dock/4_dock2com_1.py`

**Job scheduling / execution platform:**
- Slurm - batch submission and job-state polling for receptor prep, docking, MD, MM/PBSA, and rerun helpers
  - SDK/Client: CLI `sbatch`, `squeue`, `sacct`
  - Auth: Cluster/account auth is external to repo; no credentials are stored in code
  - Integration points: `scripts/infra/common.sh`, `scripts/rec/0_prep.sh`, `scripts/dock/2_gnina.sh`, `scripts/com/0_prep.sh`, `scripts/com/1_pr_prod.sh`, `scripts/com/2_sub_mmpbsa.sh`, `scripts/com/5_rerun_sel.sh`

**Agent and repository tooling:**
- OpenCode - experimental slash-command and agent orchestration layer
  - SDK/Client: `@opencode-ai/plugin` in `.opencode/package.json`
  - Auth: Not stored in repo; any editor/platform auth is external
  - Integration points: `opencode.json`, `.opencode/package.json`, `scripts/commands/common.sh`, `scripts/agents/__main__.py`
- GitHub Dependabot - automated Conda dependency update service
  - SDK/Client: `.github/dependabot.yml`
  - Auth: Managed by GitHub outside repo contents

## Data Storage

**Databases:**
- Not detected
  - Connection: Not applicable
  - Client: Not applicable

**File Storage:**
- Local filesystem workspace only
  - Primary storage roots: `work/`, `expected/`, `.planning/`, and stage output directories defined from `[general] workdir` in `scripts/config.ini.template`
  - Runtime examples: `work/test/config.ini`, stage layout documented in `WORKFLOW.md`

**Caching:**
- None detected as a dedicated cache service

## Authentication & Identity

**Auth Provider:**
- None detected for the workflow itself
  - Implementation: The codebase does not define login flows, API tokens, OAuth clients, or user/session models; integrations are CLI tools and local/HPC execution only

## Monitoring & Observability

**Error Tracking:**
- None detected as an external SaaS integration

**Logs:**
- Shell-stage logs are written to stdout/stderr through helpers in `scripts/infra/common.sh`
- Agent handoffs are persisted as JSON in workspace `.handoffs/*.json` by `scripts/commands/common.sh` and `scripts/agents/*`
- Debug reports are persisted in `.debug_reports/*.json` by `scripts/agents/debugger.py`

## CI/CD & Deployment

**Hosting:**
- Not detected for an application service; this repository is an execution toolkit run from local or HPC workspaces via `scripts/run_pipeline.sh`

**CI Pipeline:**
- No GitHub Actions or other CI workflow files detected under `.github/workflows/`
- Dependency automation only: `.github/dependabot.yml` updates the Conda ecosystem

## Environment Configuration

**Required env vars:**
- `CONDA_DEFAULT_ENV` - operationally expected to be `autoEnsmblDockMD` after sourcing `scripts/setenv.sh`
- `SLURM_JOB_ID` - read by `scripts/infra/config.py` to auto-detect `slurm` backend when present
- Optional config override variables follow the `[section] key` → `SECTION_KEY` rule implemented in `scripts/infra/config_loader.sh`; examples include `GENERAL_WORKDIR`, `SLURM_PARTITION`, `DOCKING_MODE`, and `COMPLEX_FF`

**Secrets location:**
- No secret store or secret-bearing env vars are detected in the explored code
- Operational configuration lives in `config.ini` files created from `scripts/config.ini.template`

## Webhooks & Callbacks

**Incoming:**
- None detected

**Outgoing:**
- None detected

---

*Integration audit: 2026-04-19*
