# Codebase Structure

**Analysis Date:** 2026-04-19

## Directory Layout

```text
autoEnsmblDockMD/
├── scripts/              # Core pipeline scripts, infra helpers, agent code, slash-command bridges
├── docs/                 # Human-facing usage and experimental-operation docs
├── work/                 # Example inputs, test config, and run workspaces
├── expected/             # Reference force-field and expected-output assets
├── .opencode/            # OpenCode skills and local tool configuration assets
├── .planning/            # Planning artifacts and generated codebase mapping docs
├── .reference/           # External/reference materials used for implementation support
├── README.md             # Project overview and quick start
├── WORKFLOW.md           # Authoritative stage-by-stage script map
├── AGENTS.md             # Agent roles, boundaries, and slash-command mapping
├── environment.yml       # Conda environment definition
└── opencode.json         # OpenCode agent/model/permission configuration
```

## Directory Purposes

**`scripts/`:**
- Purpose: Keep executable workflow logic and supporting orchestration code in one place.
- Contains: Core stage scripts, shared infra, agent implementations, slash-command bridge scripts, environment bootstrap.
- Key files: `scripts/run_pipeline.sh`, `scripts/setenv.sh`, `scripts/config.ini.template`, `scripts/infra/common.sh`, `scripts/agents/__main__.py`

**`scripts/rec/`:**
- Purpose: Hold receptor-ensemble generation stages.
- Contains: Ordered receptor preparation, production, analysis, clustering, and alignment scripts.
- Key files: `scripts/rec/0_prep.sh`, `scripts/rec/1_pr_rec.sh`, `scripts/rec/3_ana.sh`, `scripts/rec/4_cluster.sh`, `scripts/rec/5_align.py`

**`scripts/dock/`:**
- Purpose: Hold docking preparation, gnina execution, reporting, and dock-to-complex conversion logic.
- Contains: Format converters, receptor preparation for docking, gnina launcher, ranking utilities, topology assembly helpers.
- Key files: `scripts/dock/0_gro2mol2.sh`, `scripts/dock/2_gnina.sh`, `scripts/dock/3_dock_report.sh`, `scripts/dock/4_dock2com.sh`, `scripts/dock/4_dock2com_2.py`

**`scripts/com/`:**
- Purpose: Hold complex preparation, production MD, MM/PBSA, and trajectory analysis stages.
- Contains: Complex setup wrappers, production job submission, MM/PBSA orchestration, advanced trajectory analysis, optional utility workflows.
- Key files: `scripts/com/0_prep.sh`, `scripts/com/1_pr_prod.sh`, `scripts/com/2_run_mmpbsa.sh`, `scripts/com/3_ana.sh`, `scripts/com/3_com_ana_trj.py`

**`scripts/infra/`:**
- Purpose: Centralize reusable plumbing shared across shell scripts and agents.
- Contains: Shell helpers, config loading, execution helpers, state persistence, checkpointing, log monitoring, verification gates.
- Key files: `scripts/infra/common.sh`, `scripts/infra/config_loader.sh`, `scripts/infra/config.py`, `scripts/infra/executor.py`, `scripts/infra/verification.py`

**`scripts/agents/`:**
- Purpose: Implement experimental role-based orchestration around the same pipeline.
- Contains: Agent registry, base class, role implementations, routing helpers, handoff/state schemas.
- Key files: `scripts/agents/__main__.py`, `scripts/agents/__init__.py`, `scripts/agents/base.py`, `scripts/agents/orchestrator.py`, `scripts/agents/runner.py`

**`scripts/commands/`:**
- Purpose: Provide slash-command bridge scripts that convert command-style inputs into agent invocations.
- Contains: One small wrapper per command plus a shared dispatcher helper.
- Key files: `scripts/commands/common.sh`, `scripts/commands/rec-ensemble.sh`, `scripts/commands/dock-run.sh`, `scripts/commands/status.sh`

**`docs/`:**
- Purpose: Hold detailed user documentation outside the quick-start files.
- Contains: Usage guide and experimental operation notes.
- Key files: `docs/GUIDE.md`, `docs/EXPERIMENTAL.md`

**`work/`:**
- Purpose: Hold sample inputs and run-specific working directories.
- Contains: `work/input/` seed inputs, `work/test/config.ini` sample runtime config, and workspace roots referenced by `[general] workdir`.
- Key files: `work/input/README.md`, `work/test/config.ini`, `work/workspace/README.md`

**`expected/`:**
- Purpose: Store reference assets and expected scientific resources used by the workflow.
- Contains: Example force-field trees and expected data such as `expected/amb/amber19SB_OL21_OL3_lipid17.ff/`.
- Key files: `expected/amb/amber19SB_OL21_OL3_lipid17.ff/forcefield.itp`, `expected/amb/amber19SB_OL21_OL3_lipid17.ff/ffnonbonded.itp`

**`.planning/`:**
- Purpose: Store project planning state and generated mapping artifacts consumed by other GSD commands.
- Contains: State, roadmap, phase plans/summaries, and generated codebase docs.
- Key files: `.planning/STATE.md`, `.planning/PROJECT.md`, `.planning/codebase/`

## Key File Locations

**Entry Points:**
- `scripts/run_pipeline.sh`: Canonical full-pipeline and single-stage execution wrapper.
- `scripts/agents/__main__.py`: Canonical Python entrypoint for role-based agent execution.
- `scripts/commands/status.sh`: Slash-command bridge for workspace status inspection.
- `scripts/commands/orchestrator-resume.sh`: Slash-command bridge for orchestrator resume.
- `scripts/run_oc.sh`: Convenience wrapper for launching `opencode` from the repository.

**Configuration:**
- `scripts/config.ini.template`: Canonical INI template for all runtime sections and path conventions.
- `environment.yml`: Conda environment definition for the Python/scientific stack.
- `scripts/setenv.sh`: Environment activation bootstrap sourced before running project scripts.
- `opencode.json`: OpenCode agent, model, and permission settings.
- `work/test/config.ini`: Example instantiated runtime config.

**Core Logic:**
- `scripts/rec/`: Receptor-ensemble workflow implementation.
- `scripts/dock/`: Docking and dock-to-complex workflow implementation.
- `scripts/com/`: Complex MD, MM/PBSA, and analysis workflow implementation.
- `scripts/infra/`: Shared config/logging/execution/persistence modules.
- `scripts/agents/`: Experimental agent orchestration logic.

**Testing:**
- `work/test/infrastructure/test_infra.py`: Current repository test file covering infrastructure behavior.
- `work/test/`: Current location for test-oriented config and validation workspace assets.

## Naming Conventions

**Files:**
- Numeric stage prefixes for ordered scientific scripts: `0_prep.sh`, `1_pr_rec.sh`, `2_gnina.sh`, `3_ana.sh`, `4_dock2com_2.py`, `5_align.py`.
- Snake_case for Python modules and shell helpers: `config_loader.sh`, `dock2com_2_1.py`, `bypass_angle_type3.py`, `orchestrator.py`.
- Hyphenated names for slash-command bridge scripts: `scripts/commands/rec-ensemble.sh`, `scripts/commands/dock-run.sh`, `scripts/commands/com-mmpbsa.sh`.
- Uppercase project-level docs and planning files: `README.md`, `WORKFLOW.md`, `AGENTS.md`, `.planning/STATE.md`.

**Directories:**
- Short subsystem names for core pipeline partitions: `scripts/rec/`, `scripts/dock/`, `scripts/com/`, `scripts/infra/`, `scripts/agents/`.
- Workspace directories mirror stage outputs: `rec/`, `dock/`, `com/`, with optional `ref/` and `mdp/` subtrees under the configured workdir.

## Where to Add New Code

**New Feature:**
- Primary code: Put new stage logic in the matching subsystem under `scripts/rec/`, `scripts/dock/`, or `scripts/com/`; put reusable helpers in `scripts/infra/`; put orchestration-only logic in `scripts/agents/`.
- Tests: Add Python tests near current test assets under `work/test/infrastructure/` unless a new dedicated test tree is introduced.

**New Component/Module:**
- Implementation: Use `scripts/infra/` for shared config/state/execution utilities, `scripts/agents/` for role or schema additions, and subsystem directories like `scripts/dock/` for stage-specific scientific helpers.

**Utilities:**
- Shared helpers: Add shell helpers to `scripts/infra/common.sh` or `scripts/infra/config_loader.sh`; add Python utilities to `scripts/infra/*.py` or subsystem-local Python files like `scripts/com/3_selection_defaults.py` when the logic is stage-specific.

## Special Directories

**`work/`:**
- Purpose: Run-local inputs and outputs.
- Generated: Mixed.
- Committed: Yes.

**`.planning/`:**
- Purpose: Planning state, summaries, and generated codebase docs.
- Generated: Yes.
- Committed: Yes.

**`.opencode/skills/`:**
- Purpose: Skill definitions used by OpenCode agents and slash-command workflows.
- Generated: No.
- Committed: Yes.

**`.oc_session/`:**
- Purpose: Local OpenCode session artifacts.
- Generated: Yes.
- Committed: No.

**`expected/`:**
- Purpose: Reference assets and example expected scientific resources.
- Generated: No.
- Committed: Yes.

**`.reference/`:**
- Purpose: Supporting reference material for implementation and troubleshooting.
- Generated: No.
- Committed: Yes.

## Placement Guidance by Existing Flow

**Add a new pipeline stage:**
- Add the executable script under the relevant subsystem in `scripts/rec/`, `scripts/dock/`, or `scripts/com/`.
- Register the stage in `scripts/run_pipeline.sh` by updating `STAGE_DESC`, `STAGE_CMD`, `STAGE_SECTIONS`, `STAGE_LIGAND_MODE`, and the ordered stage arrays.
- Add any new config keys to `scripts/config.ini.template` and document them in `docs/GUIDE.md` and `WORKFLOW.md`.

**Add a new slash command:**
- Add the bridge script to `scripts/commands/<name>.sh` using the pattern in `scripts/commands/rec-ensemble.sh` and `scripts/commands/dock-run.sh`.
- If the command introduces a new role or behavior, register the implementation in `scripts/agents/__init__.py` and route stages through `scripts/agents/utils/routing.py`.

**Add new persisted workflow metadata:**
- Put agent/session state in workspace-local JSON managed by `scripts/infra/state.py`, `scripts/infra/checkpoint.py`, or `scripts/infra/verification.py`.
- Do not hardcode state into source files; follow the existing file-backed pattern under the active workspace.

---

*Structure analysis: 2026-04-19*
