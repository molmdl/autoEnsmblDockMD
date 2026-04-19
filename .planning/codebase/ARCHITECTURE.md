# Architecture

**Analysis Date:** 2026-04-19

## Pattern Overview

**Overall:** Configuration-driven, script-first staged scientific workflow with an experimental agent/slash-command orchestration overlay.

**Key Characteristics:**
- Use `scripts/run_pipeline.sh` as the canonical pipeline dispatcher for receptor preparation, docking, complex setup, production MD, MM/PBSA, and analysis.
- Keep scientific stage logic in ordered subsystem scripts under `scripts/rec/`, `scripts/dock/`, and `scripts/com/`, with shared plumbing in `scripts/infra/`.
- Treat `scripts/commands/*.sh`, `scripts/agents/*.py`, and `.opencode/skills/aedmd-*/SKILL.md` as a namespaced orchestration layer around the same pipeline, not as a replacement for the shell-script workflow.

## Layers

**Documentation and planning layer:**
- Purpose: Define workflow intent, operating rules, stage contracts, and planning context.
- Location: `README.md`, `WORKFLOW.md`, `AGENTS.md`, `docs/GUIDE.md`, `docs/EXPERIMENTAL.md`, `.planning/STATE.md`, `.planning/scancode.md`
- Contains: Human workflow guides, agent constraints, current project-state context, and generated codebase maps.
- Depends on: Current script inventory in `scripts/` and workspace conventions in `work/`.
- Used by: Human operators, GSD planning/execution commands, and OpenCode skill consumers.

**Pipeline entrypoint layer:**
- Purpose: Expose stable CLI entrypoints for whole-pipeline or stage-specific execution.
- Location: `scripts/run_pipeline.sh`, `scripts/setenv.sh`, `scripts/run_oc.sh`
- Contains: Stage registry arrays, CLI parsing, environment bootstrap, and OpenCode launcher convenience script.
- Depends on: `scripts/infra/common.sh`, `scripts/infra/config_loader.sh`, and stage scripts under `scripts/rec/`, `scripts/dock/`, and `scripts/com/`.
- Used by: Manual runs from `README.md`, `WORKFLOW.md`, and workspace configs such as `work/test/config.ini`.

**Infrastructure layer:**
- Purpose: Centralize config loading, logging, filesystem validation, Slurm integration, and persisted workflow state.
- Location: `scripts/infra/common.sh`, `scripts/infra/config_loader.sh`, `scripts/infra/config.py`, `scripts/infra/state.py`, `scripts/infra/checkpoint.py`, `scripts/infra/verification.py`, `scripts/infra/executor.py`, `scripts/infra/monitor.py`
- Contains: INI readers, shell guard helpers, job submission/wait helpers, JSON-backed state/checkpoint/gate managers, and Python execution utilities.
- Depends on: Filesystem state under the active workspace, Conda/tooling from `scripts/setenv.sh`, and cluster commands such as `sbatch`, `squeue`, and `sacct` when batch execution is used.
- Used by: `scripts/run_pipeline.sh`, subsystem scripts, and agents in `scripts/agents/`.

**Scientific stage layer:**
- Purpose: Execute domain-specific receptor, docking, complex, MM/PBSA, and analysis work.
- Location: `scripts/rec/`, `scripts/dock/`, `scripts/com/`
- Contains: Ordered shell/Python stage scripts such as `scripts/rec/0_prep.sh`, `scripts/dock/2_gnina.sh`, `scripts/dock/4_dock2com_2.2.1.py`, `scripts/com/0_prep.sh`, `scripts/com/2_run_mmpbsa.sh`, and `scripts/com/3_com_ana_trj.py`.
- Depends on: Runtime config in `scripts/config.ini.template`, workspace inputs under `work/`, external scientific tools, and shared helpers from `scripts/infra/`.
- Used by: `scripts/run_pipeline.sh` directly and the runner/analyzer paths in `scripts/agents/` indirectly.

**Agent orchestration layer:**
- Purpose: Add resumable role-based execution, validation, debugging, and workflow status inspection.
- Location: `scripts/agents/__main__.py`, `scripts/agents/base.py`, `scripts/agents/orchestrator.py`, `scripts/agents/runner.py`, `scripts/agents/analyzer.py`, `scripts/agents/checker.py`, `scripts/agents/debugger.py`, `scripts/agents/schemas/`, `scripts/agents/utils/routing.py`
- Contains: Agent registry, role implementations, workflow-stage enums, handoff schema, and stage-to-agent routing.
- Depends on: `scripts/infra/state.py`, `scripts/infra/checkpoint.py`, `scripts/infra/verification.py`, and workspace-local JSON artifacts.
- Used by: Namespaced command bridges under `scripts/commands/` and experimental workflows documented in `AGENTS.md` and `docs/EXPERIMENTAL.md`.

**Slash-command bridge layer:**
- Purpose: Translate namespaced slash-command invocations into workspace-aware agent calls.
- Location: `scripts/commands/common.sh`, `scripts/commands/aedmd-status.sh`, `scripts/commands/aedmd-rec-ensemble.sh`, `scripts/commands/aedmd-dock-run.sh`, `scripts/commands/aedmd-com-setup.sh`, `scripts/commands/aedmd-com-md.sh`, `scripts/commands/aedmd-com-mmpbsa.sh`, `scripts/commands/aedmd-com-analyze.sh`, `scripts/commands/aedmd-checker-validate.sh`, `scripts/commands/aedmd-debugger-diagnose.sh`, `scripts/commands/aedmd-orchestrator-resume.sh`
- Contains: Common flag parsing, workspace discovery, environment sourcing, handoff file writing, and direct status inspection.
- Depends on: `scripts/agents/__main__.py`, `scripts/setenv.sh`, and `.handoffs/*.json` inside the active workspace.
- Used by: OpenCode slash commands listed in `AGENTS.md` and `.opencode/skills/aedmd-*/SKILL.md`.

**Workspace artifact layer:**
- Purpose: Persist run inputs, stage outputs, handoffs, checkpoints, and review gates.
- Location: `work/input/`, `work/test/`, `work/workspace/`, and configured runtime trees under `[general] workdir` in `scripts/config.ini.template`
- Contains: Input receptors/ligands, `config.ini`, generated `rec/`, `dock/`, `com/`, optional `ref/` and `mdp/` subtrees, plus orchestration files such as `.agent_state.json`, `.checkpoints/*`, `.gates/*`, and `.handoffs/*.json`.
- Depends on: Stage scripts and agent utilities writing deterministic files to the active workspace.
- Used by: Every stage script, the status wrapper `scripts/commands/aedmd-status.sh`, and human review.

## Data Flow

**Pipeline execution flow:**

1. `scripts/run_pipeline.sh` loads a runtime INI file such as `work/test/config.ini`, validates required sections per stage, and resolves the stage script path from `STAGE_CMD`.
2. The selected script in `scripts/rec/`, `scripts/dock/`, or `scripts/com/` runs with `--config` and optional ligand targeting, using `scripts/infra/common.sh` and `scripts/infra/config_loader.sh` for bootstrap and config access.
3. Generated outputs are written into the configured workspace under paths like `work/test/rec`, `work/test/dock`, and `work/test/com`, where downstream stages consume them.

**Receptor-to-docking flow:**

1. `scripts/rec/0_prep.sh`, `scripts/rec/1_pr_rec.sh`, `scripts/rec/3_ana.sh`, `scripts/rec/4_cluster.sh`, and optional `scripts/rec/5_align.py` produce receptor conformers and aligned structures.
2. `scripts/dock/0_gro2mol2.sh`, `scripts/dock/1_rec4dock.sh`, and `scripts/dock/2_gnina.sh` prepare ligands/receptors and generate docked pose outputs.
3. `scripts/dock/3_dock_report.sh`, `scripts/dock/4_dock2com.sh`, `scripts/dock/4_dock2com_ref.sh`, and the `scripts/dock/4_dock2com_*.py` helpers transform selected poses into complex-ready inputs for `scripts/com/0_prep.sh`.

**Complex-to-analysis flow:**

1. `scripts/com/0_prep.sh` assembles complex systems and writes core artifacts such as `com.gro`, `sys.top`, `index.ndx`, and ligand-specific preparation outputs.
2. `scripts/com/1_pr_prod.sh` produces production MD inputs and trajectories, while `scripts/com/2_run_mmpbsa.sh` orchestrates MM/PBSA preprocessing and chunk execution.
3. `scripts/com/3_ana.sh`, `scripts/com/3_com_ana_trj.py`, `scripts/com/4_cal_fp.sh`, `scripts/com/4_fp.py`, `scripts/com/5_arc_sel.sh`, and `scripts/com/5_rerun_sel.sh` convert simulation outputs into analysis artifacts.

**Agent handoff flow:**

1. A namespaced command bridge such as `scripts/commands/aedmd-dock-run.sh` or `scripts/commands/aedmd-com-md.sh` sources `scripts/commands/common.sh`, discovers the workspace root, and writes `.handoffs/<stage>.json`.
2. `python -m scripts.agents` enters through `scripts/agents/__main__.py`, loads the config via `scripts/infra/config.py`, normalizes input JSON, and instantiates a role from `scripts/agents/__init__.py`.
3. Agent roles persist state/checkpoints/gates through `scripts/infra/state.py`, `scripts/infra/checkpoint.py`, and `scripts/infra/verification.py`, then return standardized handoff payloads from `scripts/agents/schemas/handoff.py`.

**State Management:**
- Use filesystem-backed state as the source of truth: `.agent_state.json` via `scripts/infra/state.py`, `.checkpoints/*` via `scripts/infra/checkpoint.py`, `.gates/*` via `scripts/infra/verification.py`, and `.handoffs/*.json` via `scripts/commands/common.sh`.
- Keep runtime parameters in INI files derived from `scripts/config.ini.template` and loaded in bash/Python through `scripts/infra/config_loader.sh` and `scripts/infra/config.py`.
- Use stage workspace directories such as `rec/`, `dock/`, and `com/` as the primary artifact bus between compute stages.

## Key Abstractions

**Stage registry:**
- Purpose: Define stage identity, required config sections, ligand forwarding mode, and execution order.
- Examples: `scripts/run_pipeline.sh`
- Pattern: Parallel bash associative arrays `STAGE_DESC`, `STAGE_CMD`, `STAGE_SECTIONS`, and `STAGE_LIGAND_MODE`, plus `ALL_STAGES` and `DEFAULT_PIPELINE_STAGES`.

**Subsystem partitioning:**
- Purpose: Separate receptor, docking, and complex work into clear directories.
- Examples: `scripts/rec/`, `scripts/dock/`, `scripts/com/`
- Pattern: Numeric stage prefixes (`0_`, `1_`, `2_`, `3_`, `4_`, `5_`) inside each subsystem to preserve execution order.

**Config access abstraction:**
- Purpose: Read the same INI config model from shell and Python code.
- Examples: `scripts/infra/config_loader.sh`, `scripts/infra/config.py`, `scripts/config.ini.template`
- Pattern: Shell `load_config`/`get_config`/`require_config` and Python `ConfigManager` over section-key storage.

**Agent role abstraction:**
- Purpose: Standardize execution across orchestrator, runner, analyzer, checker, and debugger roles.
- Examples: `scripts/agents/base.py`, `scripts/agents/orchestrator.py`, `scripts/agents/runner.py`, `scripts/agents/analyzer.py`, `scripts/agents/checker.py`, `scripts/agents/debugger.py`
- Pattern: Shared `BaseAgent` plus role-specific `execute()` implementations selected from `scripts/agents/__init__.py`.

**Workflow-stage enum abstraction:**
- Purpose: Give agent orchestration a canonical stage vocabulary.
- Examples: `scripts/agents/schemas/state.py`, `scripts/agents/utils/routing.py`
- Pattern: Enum-based stage names mapped to handling roles by `STAGE_AGENT_MAP`.

**Handoff record abstraction:**
- Purpose: Serialize agent-to-agent and command-to-review communication.
- Examples: `scripts/agents/schemas/handoff.py`, `scripts/commands/common.sh`
- Pattern: Dataclass-backed JSON with `from_agent`, `to_agent`, `status`, `stage`, `data`, `warnings`, `errors`, and `recommendations`.

**Verification gate abstraction:**
- Purpose: Pause progression for human approval between workflow stages.
- Examples: `scripts/infra/verification.py`, `scripts/agents/orchestrator.py`
- Pattern: File-backed gate state machine using `pending`, `approved`, `rejected`, and `paused` states under `.gates/`.

## Entry Points

**Full pipeline CLI:**
- Location: `scripts/run_pipeline.sh`
- Triggers: Manual execution such as `bash scripts/run_pipeline.sh --config work/test/config.ini`.
- Responsibilities: List available stages, validate stage config sections, dispatch one stage or the default ordered pipeline, and log stage boundaries.

**Scientific stage scripts:**
- Location: `scripts/rec/*.sh`, `scripts/rec/*.py`, `scripts/dock/*.sh`, `scripts/dock/*.py`, `scripts/com/*.sh`, `scripts/com/*.py`
- Triggers: Dispatch from `scripts/run_pipeline.sh` or direct manual invocation.
- Responsibilities: Perform scientific work and write deterministic outputs into the active workspace.

**Agent CLI:**
- Location: `scripts/agents/__main__.py`
- Triggers: `python -m scripts.agents --agent <role> --workspace <dir> --config <file> --input <json> --output <json>`.
- Responsibilities: Parse CLI arguments, load config/input payloads, instantiate the requested role, execute it, and emit JSON output.

**Namespaced slash-command bridges:**
- Location: `scripts/commands/aedmd-*.sh`
- Triggers: Slash commands such as `/aedmd-status`, `/aedmd-dock-run`, `/aedmd-com-setup`, and `/aedmd-orchestrator-resume` referenced in `AGENTS.md`.
- Responsibilities: Source environment, resolve workspace root, parse shared flags, dispatch to agents through `scripts/commands/common.sh`, or inspect handoff state directly in the case of `scripts/commands/aedmd-status.sh`.

**Environment bootstrap:**
- Location: `scripts/setenv.sh`
- Triggers: Manual `source ./scripts/setenv.sh` and automatic sourcing from `scripts/infra/common.sh:init_script()` and `scripts/commands/common.sh:ensure_env()`.
- Responsibilities: Prepare the Conda-based project environment required by stage scripts and agent wrappers.

## Error Handling

**Strategy:** Fail fast in shell/Python entrypoints, then persist machine-readable status for review and resumption.

**Patterns:**
- Use `set -euo pipefail` in shell entrypoints such as `scripts/run_pipeline.sh`, `scripts/commands/common.sh`, `scripts/commands/aedmd-status.sh`, and stage scripts across `scripts/rec/`, `scripts/dock/`, and `scripts/com/`.
- Validate early with `require_file`, `require_dir`, and `require_cmd` from `scripts/infra/common.sh`, plus section checks in `scripts/run_pipeline.sh`.
- Encode orchestration outcomes through `HandoffStatus` in `scripts/agents/schemas/handoff.py` and persist checkpoints/gates through `scripts/infra/checkpoint.py` and `scripts/infra/verification.py`.

## Cross-Cutting Concerns

**Logging:** Use timestamped shell logging from `scripts/infra/common.sh` (`log_info`, `log_warn`, `log_error`) and JSON-serializable handoff/checkpoint metadata from `scripts/agents/` and `scripts/infra/`.

**Validation:** Validate config sections in `scripts/run_pipeline.sh`, config keys in `scripts/infra/config_loader.sh`, workspace/file existence in `scripts/infra/common.sh`, and human review gates in `scripts/infra/verification.py`.

**Authentication:** Not applicable as application auth. Trust boundaries are environment and filesystem based: Conda activation in `scripts/setenv.sh`, local workspace access, and batch-system identity through Slurm commands invoked by `scripts/infra/common.sh`.

---

*Architecture analysis: 2026-04-19*
