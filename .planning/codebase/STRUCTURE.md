# Codebase Structure

**Analysis Date:** 2026-04-29

## Directory Layout

```text
autoEnsmblDockMD/
├── scripts/              # Pipeline scripts, shared infra, agents, and command bridges
├── docs/                 # User-facing workflow and experimental-operation guides
├── tests/                # Shell integration test entrypoints
├── work/                 # Committed input fixtures and sample workspace roots
├── expected/             # Reference assets and example force-field outputs
├── .opencode/            # Skill definitions and local OpenCode assets
├── .planning/            # Planning state and generated mapping documents
├── .reference/           # Supporting reference material
├── .github/              # Repository automation metadata
├── README.md             # Top-level quick start and pipeline summary
├── WORKFLOW.md           # Authoritative stage map and execution reference
├── AGENTS.md             # Agent roles, constraints, and command mapping
├── environment.yml       # Root Conda environment file
└── opencode.json         # OpenCode runtime configuration
```

## Directory Purposes

**`scripts/`:**
- Purpose: Keep all executable workflow logic under one top-level tree.
- Contains: Pipeline entrypoints, scientific stage scripts, shared infrastructure, agent implementations, command wrappers, MDP assets, and environment bootstrap.
- Key files: `scripts/run_pipeline.sh`, `scripts/setenv.sh`, `scripts/config.ini.template`, `scripts/CONTEXT.md`, `scripts/run_oc.sh`

**`scripts/rec/`:**
- Purpose: Hold receptor ensemble generation stages.
- Contains: Receptor preparation, production MD, trajectory analysis, clustering, and alignment scripts.
- Key files: `scripts/rec/0_prep.sh`, `scripts/rec/1_pr_rec.sh`, `scripts/rec/3_ana.sh`, `scripts/rec/4_cluster.sh`, `scripts/rec/5_align.py`

**`scripts/dock/`:**
- Purpose: Hold docking preparation, docking execution, reporting, and dock-to-complex conversion logic.
- Contains: Ligand conversion wrappers, gnina runner, report generation, and dock2com helper modules.
- Key files: `scripts/dock/0_gro2mol2.sh`, `scripts/dock/0_gro_itp_to_mol2.py`, `scripts/dock/1_rec4dock.sh`, `scripts/dock/2_gnina.sh`, `scripts/dock/3_dock_report.sh`, `scripts/dock/4_dock2com.sh`

**`scripts/com/`:**
- Purpose: Hold complex setup, production MD, MM/PBSA, and trajectory analysis stages.
- Contains: Complex preparation, production submission, MM/PBSA wrappers, advanced analysis helpers, fingerprint utilities, and rerun/archive helpers.
- Key files: `scripts/com/0_prep.sh`, `scripts/com/1_pr_prod.sh`, `scripts/com/2_run_mmpbsa.sh`, `scripts/com/3_ana.sh`, `scripts/com/3_com_ana_trj.py`, `scripts/com/4_fp.py`

**`scripts/infra/`:**
- Purpose: Hold cross-stage infrastructure shared by shell scripts, Python agents, and plugins.
- Contains: Shell helper libraries, Python config/state/checkpoint/monitoring modules, and plugin utilities under `scripts/infra/plugins/`.
- Key files: `scripts/infra/common.sh`, `scripts/infra/config_loader.sh`, `scripts/infra/config.py`, `scripts/infra/state.py`, `scripts/infra/checkpoint.py`, `scripts/infra/verification.py`

**`scripts/infra/plugins/`:**
- Purpose: Hold focused Python utilities invoked by wrapper commands instead of the main agent registry.
- Contains: Preflight validation, workspace initialization, handoff inspection, group ID checking, conversion cache, and dry-run audit helpers.
- Key files: `scripts/infra/plugins/preflight.py`, `scripts/infra/plugins/workspace_init.py`, `scripts/infra/plugins/handoff_inspect.py`, `scripts/infra/plugins/group_id_check.py`, `scripts/infra/plugins/conversion_cache.py`

**`scripts/agents/`:**
- Purpose: Hold the experimental role-based orchestration implementation.
- Contains: Agent CLI entrypoint, registry, base class, orchestrator/runner/analyzer/checker/debugger roles, schemas, and routing helpers.
- Key files: `scripts/agents/__main__.py`, `scripts/agents/__init__.py`, `scripts/agents/base.py`, `scripts/agents/orchestrator.py`, `scripts/agents/runner.py`, `scripts/agents/analyzer.py`

**`scripts/commands/`:**
- Purpose: Hold namespaced `aedmd-*` wrapper commands.
- Contains: One shell wrapper per command plus a shared helper file.
- Key files: `scripts/commands/common.sh`, `scripts/commands/aedmd-status.sh`, `scripts/commands/aedmd-dock-run.sh`, `scripts/commands/aedmd-com-setup.sh`, `scripts/commands/aedmd-preflight.sh`, `scripts/commands/aedmd-workspace-init.sh`

**`docs/`:**
- Purpose: Hold extended operator documentation.
- Contains: Detailed configuration guide, experimental agent notes, and troubleshooting references.
- Key files: `docs/GUIDE.md`, `docs/EXPERIMENTAL.md`, `docs/TROUBLESHOOTING.md`

**`tests/`:**
- Purpose: Hold repository-level test entrypoints.
- Contains: Shell integration tests.
- Key files: `tests/phase06_integration_test.sh`

**`work/`:**
- Purpose: Hold committed input fixtures and sample workspace content.
- Contains: Input assets in `work/input/`, sample config and infrastructure tests in `work/test/`, and a placeholder workspace directory in `work/workspace/`.
- Key files: `work/input/README.md`, `work/test/config.ini`, `work/test/infrastructure/test_infra.py`, `work/workspace/README.md`

**`expected/`:**
- Purpose: Hold reference example outputs and force-field assets.
- Contains: AMBER and CHARMM example trees plus a small README and sample Slurm output.
- Key files: `expected/README.md`, `expected/amb/`, `expected/chm/`, `expected/slurm-91652.out`

**`.planning/`:**
- Purpose: Hold planning state and generated analysis artifacts.
- Contains: Project requirements, state, research, phase plans, quick plans, and `.planning/codebase/*.md` documents.
- Key files: `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/REQUIREMENTS.md`, `.planning/scancode.md`, `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/STRUCTURE.md`

**`.opencode/`:**
- Purpose: Hold project-local OpenCode configuration and skill definitions.
- Contains: Skill directories under `.opencode/skills/aedmd-*/`.
- Key files: `.opencode/skills/aedmd-status/SKILL.md`, `.opencode/skills/aedmd-dock-run/SKILL.md`, `.opencode/skills/aedmd-com-setup/SKILL.md`

## Key File Locations

**Entry Points:**
- `scripts/run_pipeline.sh`: Canonical full-pipeline and single-stage dispatcher.
- `scripts/agents/__main__.py`: Canonical Python entrypoint for agent execution.
- `scripts/commands/aedmd-status.sh`: Workspace status wrapper.
- `scripts/commands/aedmd-orchestrator-resume.sh`: Orchestrator wrapper command.
- `scripts/commands/aedmd-preflight.sh`: Preflight validation wrapper.

**Configuration:**
- `scripts/config.ini.template`: Canonical runtime config template.
- `work/test/config.ini`: Committed sample instantiated config.
- `scripts/setenv.sh`: Environment bootstrap sourced before running scripts and commands.
- `environment.yml`: Root Conda environment specification.
- `opencode.json`: OpenCode runtime configuration.

**Core Logic:**
- `scripts/rec/`: Receptor workflow implementation.
- `scripts/dock/`: Docking and dock-to-complex implementation.
- `scripts/com/`: Complex prep, MD, MM/PBSA, and analysis implementation.
- `scripts/infra/`: Shared config, validation, monitoring, and persisted-state helpers.
- `scripts/agents/`: Experimental orchestration logic.

**Testing:**
- `tests/phase06_integration_test.sh`: Shell integration test for wrapper/plugin flows.
- `work/test/infrastructure/test_infra.py`: Python integration-style tests for infrastructure modules.

## Naming Conventions

**Files:**
- Use numeric prefixes for ordered scientific stage files, for example `scripts/rec/0_prep.sh`, `scripts/dock/2_gnina.sh`, `scripts/com/2_run_mmpbsa.sh`, and `scripts/com/5_arc_sel.sh`.
- Use snake_case for Python modules and helper scripts, for example `scripts/infra/config_loader.sh`, `scripts/agents/orchestrator.py`, `scripts/com/3_selection_defaults.py`, and `scripts/infra/plugins/group_id_check.py`.
- Use namespaced hyphenated wrapper names under `scripts/commands/`, for example `scripts/commands/aedmd-dock-run.sh` and `scripts/commands/aedmd-workspace-init.sh`.
- Use uppercase top-level and planning reference documents, for example `README.md`, `WORKFLOW.md`, `AGENTS.md`, and `.planning/codebase/ARCHITECTURE.md`.

**Directories:**
- Use short subsystem directories inside `scripts/` to signal responsibility: `scripts/rec/`, `scripts/dock/`, `scripts/com/`, `scripts/infra/`, `scripts/agents/`, and `scripts/commands/`.
- Mirror pipeline artifacts in workspace directories using `rec/`, `dock/`, `com/`, optional `ref/`, and `mdp/` under the active `workdir` from `scripts/config.ini.template`.

## Where to Add New Code

**New Feature:**
- Primary code: Put receptor-stage logic in `scripts/rec/`, docking logic in `scripts/dock/`, complex/MD/MM-PBSA/analysis logic in `scripts/com/`, shared infrastructure in `scripts/infra/`, and orchestration-only behavior in `scripts/agents/` or `scripts/commands/`.
- Tests: Add wrapper/integration tests in `tests/` for command-level flows and add Python infrastructure tests alongside `work/test/infrastructure/test_infra.py` for infra modules.

**New Component/Module:**
- Implementation: Add reusable bash helpers to `scripts/infra/common.sh` or `scripts/infra/config_loader.sh`; add reusable Python support modules to `scripts/infra/`; add agent-specific code to `scripts/agents/`; add stage-local helpers beside the owning stage in `scripts/rec/`, `scripts/dock/`, or `scripts/com/`.

**Utilities:**
- Shared helpers: Put wrapper-facing validation and workspace utilities in `scripts/infra/plugins/` when they are invoked as standalone commands, and keep stage-scoped helpers beside the stage they support.

## Special Directories

**`work/`:**
- Purpose: Committed sample inputs and workspace-like artifacts.
- Generated: Mixed.
- Committed: Yes.

**`.planning/`:**
- Purpose: Planning state and generated codebase documentation.
- Generated: Yes.
- Committed: Yes.

**`.opencode/skills/`:**
- Purpose: Namespaced skill definitions used by wrappers and agents.
- Generated: No.
- Committed: Yes.

**`.oc_session/`:**
- Purpose: Local OpenCode session artifacts.
- Generated: Yes.
- Committed: No.

**`expected/`:**
- Purpose: Reference example outputs and force-field assets.
- Generated: No.
- Committed: Yes.

**`.reference/`:**
- Purpose: Supporting reference material.
- Generated: No.
- Committed: Yes.

## Placement Guidance by Existing Flow

**New pipeline stage:**
- Add the executable to the owning subsystem in `scripts/rec/`, `scripts/dock/`, or `scripts/com/` using the existing numeric-prefix convention.
- Register the stage in `scripts/run_pipeline.sh` by updating `STAGE_DESC`, `STAGE_CMD`, `STAGE_SECTIONS`, `STAGE_LIGAND_MODE`, and the ordered stage arrays.
- Add required config keys to `scripts/config.ini.template` and document the stage in `WORKFLOW.md` and `docs/GUIDE.md`.

**New slash command:**
- Add the wrapper to `scripts/commands/aedmd-<name>.sh` following the pattern used by `scripts/commands/aedmd-dock-run.sh`, `scripts/commands/aedmd-status.sh`, and `scripts/commands/aedmd-workspace-init.sh`.
- If the command dispatches an agent stage, update `scripts/commands/common.sh`; if it invokes standalone validation logic, place the implementation in `scripts/infra/plugins/`.
- Keep the skill mapping aligned in `.opencode/skills/aedmd-<name>/SKILL.md` and `AGENTS.md`.

**New persisted workflow metadata:**
- Put JSON-backed state in workspace-local files managed by `scripts/infra/state.py`, `scripts/infra/checkpoint.py`, or `scripts/infra/verification.py`.
- Keep generated runtime metadata in the active workspace, not under repository source directories.

---

*Structure analysis: 2026-04-29*
