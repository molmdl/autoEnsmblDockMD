# Architecture

**Analysis Date:** 2026-04-29

## Pattern Overview

**Overall:** Configuration-driven, script-first staged workflow with an experimental agent and slash-command orchestration overlay.

**Key Characteristics:**
- Use `scripts/run_pipeline.sh` as the canonical dispatcher for the scientific pipeline.
- Keep domain execution logic in ordered stage scripts under `scripts/rec/`, `scripts/dock/`, and `scripts/com/`, with shared helpers in `scripts/infra/`.
- Treat `scripts/commands/*.sh` and `scripts/agents/*.py` as wrappers around the same stage scripts, not as a separate execution engine.

## Layers

**Documentation layer:**
- Purpose: Define workflow contracts, operator guidance, and architecture boundaries.
- Location: `README.md`, `WORKFLOW.md`, `AGENTS.md`, `docs/GUIDE.md`, `docs/EXPERIMENTAL.md`
- Contains: Stage descriptions, operating rules, mode definitions, and command mapping.
- Depends on: Implemented scripts in `scripts/` and committed workspace examples in `work/`.
- Used by: Human operators, planning commands, and agent workflows.

**Pipeline entry layer:**
- Purpose: Expose full-pipeline and single-stage CLI execution.
- Location: `scripts/run_pipeline.sh`, `scripts/setenv.sh`, `scripts/run_oc.sh`
- Contains: Stage registry arrays, CLI parsing, config-section validation, and environment bootstrap.
- Depends on: `scripts/infra/common.sh`, `scripts/infra/config_loader.sh`, and stage scripts referenced in `scripts/run_pipeline.sh`.
- Used by: Manual runs from `README.md`, `WORKFLOW.md`, and workspace configs such as `work/test/config.ini`.

**Shared infrastructure layer:**
- Purpose: Centralize config access, logging, validation, job execution, monitoring, state, checkpoints, and verification gates.
- Location: `scripts/infra/common.sh`, `scripts/infra/config_loader.sh`, `scripts/infra/config.py`, `scripts/infra/executor.py`, `scripts/infra/monitor.py`, `scripts/infra/state.py`, `scripts/infra/checkpoint.py`, `scripts/infra/verification.py`, `scripts/infra/plugins/`
- Contains: Shell helpers, Python config readers, log monitoring, persistent JSON state, and plugin-style validation utilities.
- Depends on: Workspace files, Conda/tool environment from `scripts/setenv.sh`, and external commands such as `gmx`, `sbatch`, `squeue`, and `sacct`.
- Used by: `scripts/run_pipeline.sh`, stage scripts, agent roles, and command wrappers.

**Scientific stage layer:**
- Purpose: Execute the receptor → docking → complex → MM/PBSA → analysis workflow.
- Location: `scripts/rec/`, `scripts/dock/`, `scripts/com/`
- Contains: Ordered shell and Python stage scripts such as `scripts/rec/0_prep.sh`, `scripts/dock/2_gnina.sh`, `scripts/dock/4_dock2com_2.py`, `scripts/com/0_prep.sh`, `scripts/com/2_run_mmpbsa.sh`, and `scripts/com/3_com_ana_trj.py`.
- Depends on: `scripts/config.ini.template`, active workspace contents under `work/` or user-defined `workdir`, and shared helpers from `scripts/infra/`.
- Used by: `scripts/run_pipeline.sh` directly and agent/command wrappers indirectly.

**Agent orchestration layer:**
- Purpose: Provide role-based execution, handoffs, resumability, and review gates.
- Location: `scripts/agents/__main__.py`, `scripts/agents/base.py`, `scripts/agents/orchestrator.py`, `scripts/agents/runner.py`, `scripts/agents/analyzer.py`, `scripts/agents/checker.py`, `scripts/agents/debugger.py`, `scripts/agents/schemas/`, `scripts/agents/utils/routing.py`
- Contains: Agent registry, role implementations, handoff schema, stage enum, and stage-to-agent routing.
- Depends on: `scripts/infra/config.py`, `scripts/infra/state.py`, `scripts/infra/checkpoint.py`, `scripts/infra/verification.py`, and workspace-local `.handoffs/` output.
- Used by: `scripts/commands/aedmd-*.sh` wrappers and experimental agent workflows documented in `AGENTS.md`.

**Slash-command bridge layer:**
- Purpose: Convert `aedmd-*` wrapper invocations into workspace-aware agent or plugin execution.
- Location: `scripts/commands/common.sh`, `scripts/commands/aedmd-*.sh`
- Contains: Shared flag parsing, workspace discovery, stage-to-script mapping, handoff inspection, and wrapper-specific dispatch logic.
- Depends on: `scripts/agents/__main__.py`, `scripts/infra/plugins/*.py`, `scripts/setenv.sh`, and workspace `.handoffs/*.json` files.
- Used by: Slash commands mapped in `AGENTS.md`.

**Workspace artifact layer:**
- Purpose: Persist user inputs, stage outputs, run state, and orchestration metadata.
- Location: `work/input/`, `work/test/`, configured `[general] workdir` trees from `scripts/config.ini.template`
- Contains: `config.ini`, `rec/`, `dock/`, `com/`, optional `ref/` and `mdp/` directories, plus `.agent_state.json`, `.checkpoints/`, `.gates/`, and `.handoffs/` in active workspaces.
- Depends on: Stage scripts and agents writing deterministic files to the selected workspace.
- Used by: Every stage and wrapper.

## Data Flow

**Manual pipeline flow:**

1. Start from `scripts/run_pipeline.sh` with `--config <file>` and optional `--stage` or `--ligand`.
2. `scripts/run_pipeline.sh` validates required INI sections using `config_has_section()` and resolves the executable path from `STAGE_CMD`.
3. The target script under `scripts/rec/`, `scripts/dock/`, or `scripts/com/` runs with `--config` and writes outputs into the active workspace defined by `[general] workdir` in `scripts/config.ini.template`.

**Receptor-to-docking flow:**

1. `scripts/rec/0_prep.sh`, `scripts/rec/1_pr_rec.sh`, `scripts/rec/3_ana.sh`, `scripts/rec/4_cluster.sh`, and `scripts/rec/5_align.py` build receptor systems, run receptor MD, analyze trajectories, cluster conformers, and write aligned ensemble outputs.
2. `scripts/dock/0_gro2mol2.sh`, `scripts/dock/0_gro_itp_to_mol2.py`, `scripts/dock/0_sdf2gro.sh`, `scripts/dock/1_rec4dock.sh`, and `scripts/dock/2_gnina.sh` prepare ligand and receptor docking assets.
3. `scripts/dock/3_dock_report.sh` and `scripts/dock/4_dock2com*.sh` plus `scripts/dock/4_dock2com_*.py` convert ranked poses into complex-ready inputs.

**Complex-to-analysis flow:**

1. `scripts/com/0_prep.sh` assembles receptor-ligand systems and writes files such as `com.gro`, `sys.top`, and `index.ndx` in ligand-specific directories.
2. `scripts/com/1_pr_prod.sh` runs or submits equilibration and production MD; `scripts/com/2_run_mmpbsa.sh` orchestrates trajectory preparation and MM/PBSA chunk submission.
3. `scripts/com/3_ana.sh`, `scripts/com/3_com_ana_trj.py`, `scripts/com/4_cal_fp.sh`, `scripts/com/4_fp.py`, `scripts/com/5_arc_sel.sh`, and `scripts/com/5_rerun_sel.sh` transform simulation outputs into analysis artifacts.

**Agent handoff flow:**

1. A wrapper such as `scripts/commands/aedmd-dock-run.sh` sources `scripts/commands/common.sh`, resolves the workspace root, and calls `dispatch_agent`.
2. `scripts/commands/common.sh` resolves the canonical stage script from `STAGE_SCRIPT_MAP` and invokes `python -m scripts.agents` through `scripts/agents/__main__.py`.
3. The selected agent writes standardized handoffs through `scripts/agents/schemas/handoff.py` and persists state/checkpoints/gates through `scripts/infra/state.py`, `scripts/infra/checkpoint.py`, and `scripts/infra/verification.py`.

**Plugin validation flow:**

1. Wrapper commands such as `scripts/commands/aedmd-preflight.sh` and `scripts/commands/aedmd-workspace-init.sh` call Python plugins in `scripts/infra/plugins/`.
2. Those plugins write result JSON into `.handoffs/*.json` inside the active workspace.
3. `check_handoff_result` in `scripts/commands/common.sh` normalizes wrapper exit behavior from handoff `status`.

**State Management:**
- Keep run configuration in INI files derived from `scripts/config.ini.template` and loaded by `scripts/infra/config_loader.sh` or `scripts/infra/config.py`.
- Keep workflow state on disk with `.agent_state.json` via `scripts/infra/state.py`, `.checkpoints/*` via `scripts/infra/checkpoint.py`, `.gates/*` via `scripts/infra/verification.py`, and `.handoffs/*.json` via `scripts/commands/common.sh` or plugin wrappers.
- Use workspace stage directories such as `rec/`, `dock/`, and `com/` as the main artifact bus between stages.

## Key Abstractions

**Stage registry:**
- Purpose: Define stage order, script path, required config sections, and ligand forwarding behavior.
- Examples: `scripts/run_pipeline.sh`
- Pattern: Parallel associative arrays `STAGE_DESC`, `STAGE_CMD`, `STAGE_SECTIONS`, and `STAGE_LIGAND_MODE`, plus ordered arrays `ALL_STAGES` and `DEFAULT_PIPELINE_STAGES`.

**Subsystem partitioning:**
- Purpose: Separate receptor, docking, and complex work into stable domains.
- Examples: `scripts/rec/`, `scripts/dock/`, `scripts/com/`
- Pattern: Numeric prefixes communicate execution order, for example `0_prep.sh`, `1_pr_rec.sh`, `2_run_mmpbsa.sh`, and `3_ana.sh`.

**Dual config access model:**
- Purpose: Read the same runtime config from bash and Python.
- Examples: `scripts/infra/config_loader.sh`, `scripts/infra/config.py`, `scripts/config.ini.template`
- Pattern: Shell uses `load_config`, `get_config`, and `require_config`; Python uses `ConfigManager`.

**Agent role model:**
- Purpose: Standardize orchestration behavior across roles.
- Examples: `scripts/agents/base.py`, `scripts/agents/orchestrator.py`, `scripts/agents/runner.py`, `scripts/agents/analyzer.py`
- Pattern: `BaseAgent` supplies checkpoint/state/handoff helpers and each role implements `execute()`.

**Workflow stage vocabulary:**
- Purpose: Give wrappers and agents canonical stage names.
- Examples: `scripts/agents/schemas/state.py`, `scripts/agents/utils/routing.py`, `scripts/commands/common.sh`
- Pattern: `WorkflowStage` enum values such as `receptor_prep`, `docking_run`, and `complex_analysis` are mapped to roles and scripts.

**Handoff contract:**
- Purpose: Serialize agent outputs into a consistent machine-readable record.
- Examples: `scripts/agents/schemas/handoff.py`, `scripts/commands/common.sh`
- Pattern: JSON payload with `from_agent`, `to_agent`, `status`, `stage`, `data`, `warnings`, `errors`, and `recommendations`.

**Verification gate:**
- Purpose: Require explicit approval before later stages proceed.
- Examples: `scripts/infra/verification.py`, `scripts/agents/orchestrator.py`
- Pattern: File-backed state machine with `pending`, `approved`, `rejected`, and `paused` states under `.gates/`.

## Entry Points

**Full pipeline CLI:**
- Location: `scripts/run_pipeline.sh`
- Triggers: Manual execution such as `bash scripts/run_pipeline.sh --config work/test/config.ini`.
- Responsibilities: Print stage inventory, validate config sections, dispatch either one stage or the default stage sequence, and log stage boundaries.

**Scientific stage scripts:**
- Location: `scripts/rec/*.sh`, `scripts/rec/*.py`, `scripts/dock/*.sh`, `scripts/dock/*.py`, `scripts/com/*.sh`, `scripts/com/*.py`
- Triggers: Dispatch from `scripts/run_pipeline.sh` or direct manual invocation.
- Responsibilities: Perform scientific computation and write workspace artifacts.

**Agent CLI:**
- Location: `scripts/agents/__main__.py`
- Triggers: `python -m scripts.agents --agent <role> --workspace <dir> --config <file> --input <json> --output <json>`.
- Responsibilities: Load config and handoff input, instantiate a role from `scripts/agents/__init__.py`, execute it, and emit JSON output.

**Slash-command wrappers:**
- Location: `scripts/commands/aedmd-*.sh`
- Triggers: Namespaced commands such as `scripts/commands/aedmd-dock-run.sh`, `scripts/commands/aedmd-com-setup.sh`, `scripts/commands/aedmd-status.sh`, and `scripts/commands/aedmd-orchestrator-resume.sh`.
- Responsibilities: Source environment, locate workspace root, parse shared flags, dispatch agents or plugins, and report handoff status.

**Plugin commands:**
- Location: `scripts/commands/aedmd-preflight.sh`, `scripts/commands/aedmd-workspace-init.sh`, `scripts/commands/aedmd-group-id-check.sh`, `scripts/commands/aedmd-handoff-inspect.sh`
- Triggers: Validation and workspace-management command execution.
- Responsibilities: Run plugin modules in `scripts/infra/plugins/` and persist handoff results.

## Error Handling

**Strategy:** Fail fast at shell and Python boundaries, then persist structured status for review and resume.

**Patterns:**
- Use `set -euo pipefail` in shell entrypoints such as `scripts/run_pipeline.sh`, `scripts/commands/common.sh`, and wrapper scripts in `scripts/commands/`.
- Validate prerequisites early with `require_file`, `require_dir`, and `require_cmd` in `scripts/infra/common.sh`, plus config-section checks in `scripts/run_pipeline.sh`.
- Encode workflow outcomes through `HandoffStatus` in `scripts/agents/schemas/handoff.py` and wrapper-level `check_handoff_result` in `scripts/commands/common.sh`.

## Cross-Cutting Concerns

**Logging:** Use timestamped shell logs from `scripts/infra/common.sh` (`log_info`, `log_warn`, `log_error`) and JSON metadata in handoff/checkpoint records from `scripts/agents/` and `scripts/infra/`.

**Validation:** Validate config structure in `scripts/run_pipeline.sh`, config values through `scripts/infra/config_loader.sh` and `scripts/infra/config.py`, file/tool prerequisites in `scripts/infra/common.sh`, and human review status in `scripts/infra/verification.py`.

**Authentication:** Not applicable as application auth. Execution trust is based on local filesystem access, Conda environment activation in `scripts/setenv.sh`, and scheduler identity for Slurm-backed commands.

---

*Architecture analysis: 2026-04-29*
