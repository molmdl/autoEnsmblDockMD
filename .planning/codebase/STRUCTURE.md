# Codebase Structure

**Analysis Date:** 2026-04-19

## Directory Layout

```text
autoEnsmblDockMD/
├── scripts/              # Pipeline entrypoints, stage scripts, shared infra, agents, slash-command bridges
├── docs/                 # Human-facing configuration and experimental-operation guides
├── work/                 # Example inputs, test config, and runtime workspace roots
├── expected/             # Reference force-field/example assets used by workflow examples
├── .opencode/            # Skill definitions and local OpenCode assets
├── .planning/            # Project state, phase plans, and generated codebase maps
├── .reference/           # Supporting external reference materials
├── .github/              # Repository automation metadata
├── README.md             # Quick-start overview and project entry document
├── WORKFLOW.md           # Authoritative stage-by-stage script map
├── AGENTS.md             # Agent roles, boundaries, and namespaced command mapping
├── environment.yml       # Root Conda environment definition
└── opencode.json         # OpenCode model and permission configuration
```

## Directory Purposes

**`scripts/`:**
- Purpose: Keep executable workflow logic and orchestration code in one tree.
- Contains: Pipeline entrypoints, subsystem stage scripts, shared infra helpers, Python agents, and namespaced command wrappers.
- Key files: `scripts/run_pipeline.sh`, `scripts/setenv.sh`, `scripts/config.ini.template`, `scripts/run_oc.sh`, `scripts/CONTEXT.md`

**`scripts/rec/`:**
- Purpose: Hold receptor-ensemble generation stages.
- Contains: Receptor preparation, receptor production MD submission, receptor analysis, clustering, and alignment scripts.
- Key files: `scripts/rec/0_prep.sh`, `scripts/rec/1_pr_rec.sh`, `scripts/rec/3_ana.sh`, `scripts/rec/4_cluster.sh`, `scripts/rec/5_align.py`

**`scripts/dock/`:**
- Purpose: Hold docking preparation, gnina execution, reporting, and dock-to-complex conversion logic.
- Contains: Ligand conversion helpers, receptor prep for docking, gnina launcher, ranking utilities, and multiple dock2com topology utilities.
- Key files: `scripts/dock/0_gro2mol2.sh`, `scripts/dock/0_gro_itp_to_mol2.py`, `scripts/dock/1_rec4dock.sh`, `scripts/dock/2_gnina.sh`, `scripts/dock/4_dock2com.sh`, `scripts/dock/4_dock2com_2.2.1.py`

**`scripts/com/`:**
- Purpose: Hold complex setup, production MD, MM/PBSA, and analysis stages.
- Contains: Complex assembly, production submission, MM/PBSA orchestration, advanced trajectory analysis, fingerprint helpers, and rerun/archive helpers.
- Key files: `scripts/com/0_prep.sh`, `scripts/com/1_pr_prod.sh`, `scripts/com/2_run_mmpbsa.sh`, `scripts/com/3_ana.sh`, `scripts/com/3_com_ana_trj.py`, `scripts/com/4_cal_fp.sh`

**`scripts/infra/`:**
- Purpose: Centralize shared config, logging, execution, state, checkpoint, and verification utilities.
- Contains: Bash helper libraries and Python infra modules.
- Key files: `scripts/infra/common.sh`, `scripts/infra/config_loader.sh`, `scripts/infra/config.py`, `scripts/infra/state.py`, `scripts/infra/checkpoint.py`, `scripts/infra/verification.py`

**`scripts/agents/`:**
- Purpose: Implement the experimental role-based orchestration layer.
- Contains: Agent registry, CLI entrypoint, base class, orchestrator/runner/analyzer/checker/debugger roles, schemas, and routing helpers.
- Key files: `scripts/agents/__main__.py`, `scripts/agents/__init__.py`, `scripts/agents/base.py`, `scripts/agents/orchestrator.py`, `scripts/agents/runner.py`, `scripts/agents/schemas/handoff.py`

**`scripts/commands/`:**
- Purpose: Provide namespaced slash-command bridge scripts.
- Contains: One wrapper per `aedmd-*` command and a shared helper library.
- Key files: `scripts/commands/common.sh`, `scripts/commands/aedmd-status.sh`, `scripts/commands/aedmd-rec-ensemble.sh`, `scripts/commands/aedmd-dock-run.sh`, `scripts/commands/aedmd-com-setup.sh`, `scripts/commands/aedmd-orchestrator-resume.sh`

**`docs/`:**
- Purpose: Hold detailed user documentation outside the top-level quick-start docs.
- Contains: Workflow configuration guide and agent-support caveats.
- Key files: `docs/GUIDE.md`, `docs/EXPERIMENTAL.md`

**`work/`:**
- Purpose: Hold example inputs and committed test/workspace assets.
- Contains: Input receptors/ligands in `work/input/`, sample config and test assets in `work/test/`, and workspace guidance in `work/workspace/README.md`.
- Key files: `work/input/README.md`, `work/test/config.ini`, `work/test/infrastructure/test_infra.py`, `work/workspace/README.md`

**`expected/`:**
- Purpose: Store reference force-field/example assets consumed or mirrored by the workflow.
- Contains: AMBER and CHARMM reference trees plus README/examples.
- Key files: `expected/README.md`, `expected/amb/amber19SB_OL21_OL3_lipid17.ff/forcefield.itp`, `expected/chm/`

**`.opencode/`:**
- Purpose: Store OpenCode-specific project assets.
- Contains: Skill definitions under `.opencode/skills/aedmd-*/SKILL.md`.
- Key files: `.opencode/skills/aedmd-status/SKILL.md`, `.opencode/skills/aedmd-dock-run/SKILL.md`, `.opencode/skills/aedmd-com-setup/SKILL.md`

**`.planning/`:**
- Purpose: Store planning state and generated mapping artifacts consumed by GSD commands.
- Contains: Project state, requirements, phase plans/summaries, research, and `.planning/codebase/*.md` outputs.
- Key files: `.planning/STATE.md`, `.planning/scancode.md`, `.planning/PROJECT.md`, `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/STRUCTURE.md`

## Key File Locations

**Entry Points:**
- `scripts/run_pipeline.sh`: Canonical full-pipeline and single-stage dispatcher.
- `scripts/agents/__main__.py`: Canonical Python entrypoint for agent execution.
- `scripts/commands/aedmd-status.sh`: Workspace status command wrapper with `--workdir` handling.
- `scripts/commands/aedmd-orchestrator-resume.sh`: Orchestrator resume command wrapper.
- `scripts/run_oc.sh`: Convenience wrapper for launching `opencode`.

**Configuration:**
- `scripts/config.ini.template`: Canonical runtime INI template.
- `work/test/config.ini`: Committed example instantiated runtime config.
- `scripts/setenv.sh`: Environment bootstrap sourced before running scripts/commands.
- `environment.yml`: Root Conda environment specification.
- `opencode.json`: OpenCode model/permission settings.

**Core Logic:**
- `scripts/rec/`: Receptor ensemble workflow implementation.
- `scripts/dock/`: Docking and dock-to-complex implementation.
- `scripts/com/`: Complex prep, MD, MM/PBSA, and analysis implementation.
- `scripts/infra/`: Shared config/logging/state/execution helpers.
- `scripts/agents/`: Experimental orchestration logic.

**Testing:**
- `work/test/infrastructure/test_infra.py`: Current committed Python test file.
- `work/test/`: Current location for committed test config and test-oriented assets.

## Naming Conventions

**Files:**
- Numeric prefixes for ordered scientific stages: `scripts/rec/0_prep.sh`, `scripts/dock/2_gnina.sh`, `scripts/com/3_ana.sh`, `scripts/dock/4_dock2com_2.py`, `scripts/com/5_rerun_sel.sh`.
- Snake_case for Python modules and helper scripts: `scripts/infra/config_loader.sh`, `scripts/agents/orchestrator.py`, `scripts/com/3_selection_defaults.py`, `scripts/dock/dock2com_2_1.py`.
- Namespaced hyphenated command wrappers under `scripts/commands/`: `scripts/commands/aedmd-status.sh`, `scripts/commands/aedmd-rec-ensemble.sh`, `scripts/commands/aedmd-com-mmpbsa.sh`.
- Uppercase root/planning docs: `README.md`, `WORKFLOW.md`, `AGENTS.md`, `.planning/STATE.md`.

**Directories:**
- Short subsystem directories for pipeline partitions: `scripts/rec/`, `scripts/dock/`, `scripts/com/`, `scripts/infra/`, `scripts/agents/`, `scripts/commands/`.
- Workspace directories mirror stage outputs and support files: `rec/`, `dock/`, `com/`, `ref/`, and `mdp/` under the active `workdir` defined in `scripts/config.ini.template`.

## Where to Add New Code

**New Feature:**
- Primary code: Put new scientific stage logic in the matching subsystem under `scripts/rec/`, `scripts/dock/`, or `scripts/com/`; put reusable plumbing in `scripts/infra/`; put orchestration-only behavior in `scripts/agents/` or `scripts/commands/`.
- Tests: Add Python tests alongside the current committed pattern under `work/test/infrastructure/` unless a dedicated top-level test tree is introduced.

**New Component/Module:**
- Implementation: Use `scripts/infra/` for shared config/state/execution modules, `scripts/agents/` for role/schema/routing additions, and subsystem-specific directories like `scripts/dock/` for stage-scoped helpers.

**Utilities:**
- Shared helpers: Add bash utilities to `scripts/infra/common.sh` or `scripts/infra/config_loader.sh`; add Python utilities to `scripts/infra/*.py` for cross-stage reuse or to subsystem-local files such as `scripts/com/3_selection_defaults.py` when the logic is stage-specific.

## Special Directories

**`work/`:**
- Purpose: Committed sample inputs plus runtime-style workspace assets.
- Generated: Mixed.
- Committed: Yes.

**`.planning/`:**
- Purpose: Planning state, phase artifacts, and generated codebase docs.
- Generated: Yes.
- Committed: Yes.

**`.opencode/skills/`:**
- Purpose: Namespaced OpenCode skill definitions.
- Generated: No.
- Committed: Yes.

**`.oc_session/`:**
- Purpose: Local OpenCode session artifacts.
- Generated: Yes.
- Committed: No.

**`expected/`:**
- Purpose: Reference force-field/example assets.
- Generated: No.
- Committed: Yes.

**`.reference/`:**
- Purpose: External supporting reference material.
- Generated: No.
- Committed: Yes.

## Placement Guidance by Existing Flow

**Add a new pipeline stage:**
- Add the executable script to `scripts/rec/`, `scripts/dock/`, or `scripts/com/` using the numeric-prefix pattern already used by nearby stages.
- Register the stage in `scripts/run_pipeline.sh` by updating `STAGE_DESC`, `STAGE_CMD`, `STAGE_SECTIONS`, `STAGE_LIGAND_MODE`, and either `DEFAULT_PIPELINE_STAGES` or optional-stage handling.
- Add required config keys to `scripts/config.ini.template` and document the new stage in `WORKFLOW.md` and `docs/GUIDE.md`.

**Add a new namespaced slash command:**
- Add the wrapper to `scripts/commands/aedmd-<name>.sh` using the shared pattern in `scripts/commands/aedmd-rec-ensemble.sh`, `scripts/commands/aedmd-dock-run.sh`, and `scripts/commands/aedmd-orchestrator-resume.sh`.
- Add or update the related skill under `.opencode/skills/aedmd-<name>/SKILL.md` and keep `AGENTS.md` slash-command mapping aligned.

**Add new agent state or persisted review metadata:**
- Put state in workspace-local JSON handled by `scripts/infra/state.py`, `scripts/infra/checkpoint.py`, or `scripts/infra/verification.py`.
- Keep persisted runtime artifacts under the active workspace, not in repository source directories.

---

*Structure analysis: 2026-04-19*
