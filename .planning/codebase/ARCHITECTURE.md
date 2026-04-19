# Architecture

**Analysis Date:** 2026-04-19

## Pattern Overview

**Overall:** Configuration-driven, script-first staged scientific workflow with an optional agent orchestration layer.

**Key Characteristics:**
- Use `scripts/run_pipeline.sh` as the canonical end-to-end entrypoint for the receptor → docking → complex MD → MM/PBSA → analysis pipeline.
- Keep stage logic inside subsystem scripts under `scripts/rec/`, `scripts/dock/`, and `scripts/com/`; use `scripts/infra/` only for shared plumbing.
- Treat `scripts/agents/` and `scripts/commands/` as an orchestration overlay around the same underlying pipeline, not as a replacement for the core scripts.

## Layers

**Documentation and planning layer:**
- Purpose: Define workflow intent, operating constraints, and human-facing run guidance.
- Location: `README.md`, `WORKFLOW.md`, `docs/GUIDE.md`, `AGENTS.md`, `.planning/`
- Contains: Workflow reference, configuration guidance, planning state, phase artifacts.
- Depends on: Current script inventory and workspace conventions.
- Used by: Humans, slash-command agents, and future planning/execution tooling.

**Command entrypoint layer:**
- Purpose: Provide stable user-invoked entrypoints for full-pipeline and slash-command execution.
- Location: `scripts/run_pipeline.sh`, `scripts/commands/*.sh`, `scripts/run_oc.sh`
- Contains: Stage registry, CLI parsing, agent dispatch bridges, OpenCode launcher wrapper.
- Depends on: `scripts/infra/common.sh`, `scripts/agents/__main__.py`, stage scripts under `scripts/rec/`, `scripts/dock/`, `scripts/com/`.
- Used by: Manual CLI runs and slash-command wrappers such as `scripts/commands/rec-ensemble.sh` and `scripts/commands/dock-run.sh`.

**Infrastructure layer:**
- Purpose: Centralize config loading, environment bootstrap, logging, execution helpers, persistence, monitoring, and verification gates.
- Location: `scripts/infra/common.sh`, `scripts/infra/config_loader.sh`, `scripts/infra/config.py`, `scripts/infra/executor.py`, `scripts/infra/state.py`, `scripts/infra/checkpoint.py`, `scripts/infra/monitor.py`, `scripts/infra/verification.py`
- Contains: Bash helpers, Python config/state abstractions, Slurm/local execution support, log parsing, gate management.
- Depends on: Filesystem state, Slurm commands, external scientific executables, JSON/INI serialization.
- Used by: `scripts/run_pipeline.sh`, all major stage scripts, and agents in `scripts/agents/`.

**Stage workflow layer:**
- Purpose: Execute domain-specific scientific work for each pipeline stage.
- Location: `scripts/rec/`, `scripts/dock/`, `scripts/com/`
- Contains: Ordered shell and Python stage scripts with numeric prefixes such as `scripts/rec/0_prep.sh`, `scripts/dock/2_gnina.sh`, and `scripts/com/2_run_mmpbsa.sh`.
- Depends on: `scripts/infra/common.sh`, `scripts/config.ini.template`, workspace inputs under `work/`, and external tools like GROMACS and gnina.
- Used by: `scripts/run_pipeline.sh` directly and agent runner/analyzer flows indirectly.

**Agent orchestration layer:**
- Purpose: Add resumable, role-based orchestration, checking, debugging, and analysis around the pipeline.
- Location: `scripts/agents/`, `scripts/commands/*.sh`, `.opencode/skills/`
- Contains: Base agent abstraction, role registry, handoff schema, workflow-stage routing, checkpoint/state storage, bridge scripts.
- Depends on: `scripts/infra/` persistence utilities and workspace-local JSON artifacts such as `.agent_state.json`, `.checkpoints/`, `.gates/`, and handoff files.
- Used by: Slash-command workflows and experimental agent-driven operation described in `AGENTS.md`.

**Workspace artifact layer:**
- Purpose: Hold run-specific inputs, intermediate artifacts, outputs, checkpoints, and review state.
- Location: `work/`, especially `work/input/`, `work/test/`, and configured `workdir` trees like `work/test/rec`, `work/test/dock`, `work/test/com`
- Contains: Config files, copied inputs, generated topologies, trajectories, reports, handoffs, and verification artifacts.
- Depends on: The configured `[general] workdir` in `scripts/config.ini.template` and stage scripts writing deterministic outputs.
- Used by: Every stage script, monitor/checker logic, and human review.

## Data Flow

**Primary pipeline flow:**

1. Load runtime configuration from a file based on `scripts/config.ini.template` through `scripts/run_pipeline.sh` and `scripts/infra/config_loader.sh`.
2. Dispatch ordered stage scripts from `scripts/run_pipeline.sh` into `scripts/rec/`, `scripts/dock/`, and `scripts/com/` based on the built-in stage registry.
3. Write stage outputs into the configured workspace under paths such as `work/test/rec`, `work/test/dock`, and `work/test/com`, then feed those artifacts into downstream stages.

**Receptor-to-docking flow:**

1. `scripts/rec/0_prep.sh`, `scripts/rec/1_pr_rec.sh`, `scripts/rec/3_ana.sh`, `scripts/rec/4_cluster.sh`, and optionally `scripts/rec/5_align.py` generate receptor conformers in the receptor workspace.
2. `scripts/dock/1_rec4dock.sh` and `scripts/dock/2_gnina.sh` consume receptor conformers and ligand inputs to produce docking pose files and reports in the docking workspace.
3. `scripts/dock/4_dock2com.sh` and `scripts/dock/4_dock2com_ref.sh` convert selected docking poses into complex-ready files consumed by `scripts/com/0_prep.sh`.

**Complex-to-analysis flow:**

1. `scripts/com/0_prep.sh` assembles receptor-ligand systems, writes `com.gro`, `sys.top`, and index/topology artifacts, then submits equilibration work.
2. `scripts/com/1_pr_prod.sh` produces trial-based production trajectories and topologies such as `prod_*.xtc` and `prod_*.tpr`.
3. `scripts/com/2_run_mmpbsa.sh` and `scripts/com/3_ana.sh` branch from the complex workspace to compute energies and trajectory analysis products.

**Agent handoff flow:**

1. `scripts/commands/*.sh` assemble lightweight JSON input and invoke `python -m scripts.agents` through `scripts/commands/common.sh`.
2. `scripts/agents/__main__.py` loads config and handoff JSON, then instantiates a role from `scripts/agents/__init__.py`.
3. Agents persist state to workspace-local files via `scripts/infra/state.py`, `scripts/infra/checkpoint.py`, and `scripts/infra/verification.py`, then emit standardized handoffs via `scripts/agents/schemas/handoff.py`.

**State Management:**
- Use filesystem state, not in-memory orchestration, as the source of truth.
- Keep pipeline configuration in INI files loaded by `scripts/infra/config_loader.sh` and `scripts/infra/config.py`.
- Persist agent context in workspace files such as `.agent_state.json`, `.checkpoints/*_checkpoint_*.json`, `.gates/*_gate.json`, and handoff JSON emitted by `scripts/agents/schemas/handoff.py`.
- Treat the stage workspace itself (`rec/`, `dock/`, `com/`) as the main artifact bus between stages.

## Key Abstractions

**Stage registry:**
- Purpose: Define the canonical pipeline order, required config sections, and ligand-targeting mode per stage.
- Examples: `scripts/run_pipeline.sh`
- Pattern: Bash associative arrays (`STAGE_DESC`, `STAGE_CMD`, `STAGE_SECTIONS`, `STAGE_LIGAND_MODE`) plus ordered stage lists.

**Config access abstraction:**
- Purpose: Normalize INI access across bash and Python code.
- Examples: `scripts/infra/config_loader.sh`, `scripts/infra/config.py`
- Pattern: Bash `get_config`/`require_config` for stage scripts and Python `ConfigManager` for agent/utility code.

**Agent role abstraction:**
- Purpose: Standardize orchestration behavior across orchestrator, runner, analyzer, checker, and debugger roles.
- Examples: `scripts/agents/base.py`, `scripts/agents/orchestrator.py`, `scripts/agents/runner.py`, `scripts/agents/analyzer.py`, `scripts/agents/checker.py`, `scripts/agents/debugger.py`
- Pattern: Shared `BaseAgent` with per-role `execute()` implementations and standardized handoff creation.

**Handoff record abstraction:**
- Purpose: Serialize inter-agent communication in a durable, machine-readable format.
- Examples: `scripts/agents/schemas/handoff.py`, `scripts/commands/common.sh`
- Pattern: Dataclass-backed JSON payload with `from_agent`, `to_agent`, `status`, `stage`, `data`, `warnings`, `errors`, and `recommendations`.

**Verification gate abstraction:**
- Purpose: Pause workflow progression for human review between stages.
- Examples: `scripts/infra/verification.py`, `scripts/agents/orchestrator.py`
- Pattern: File-backed gate state machine with explicit `pending`, `approved`, `rejected`, and `paused` transitions.

**Workspace-per-run abstraction:**
- Purpose: Keep each run self-contained and reproducible under a chosen workdir.
- Examples: `scripts/config.ini.template`, `WORKFLOW.md`, `work/test/config.ini`
- Pattern: Root workdir configured in `[general] workdir`, with stage-local subtrees such as `rec/`, `dock/`, `com/`, `mdp/`, and optional `ref/`.

## Entry Points

**Full pipeline CLI:**
- Location: `scripts/run_pipeline.sh`
- Triggers: Manual CLI invocation such as `bash scripts/run_pipeline.sh --config work/test/config.ini`.
- Responsibilities: Validate required config sections, resolve stage commands, run one stage or the default ordered pipeline, and log start/end timestamps.

**Stage scripts:**
- Location: `scripts/rec/*.sh`, `scripts/rec/*.py`, `scripts/dock/*.sh`, `scripts/dock/*.py`, `scripts/com/*.sh`, `scripts/com/*.py`
- Triggers: Direct CLI use or dispatch from `scripts/run_pipeline.sh`.
- Responsibilities: Perform scientific stage work and write deterministic artifacts into the workspace.

**Agent CLI:**
- Location: `scripts/agents/__main__.py`
- Triggers: `python -m scripts.agents --agent <role> --workspace <dir> ...`
- Responsibilities: Load config/input payloads, instantiate the requested agent, execute role logic, and emit JSON output.

**Slash-command bridges:**
- Location: `scripts/commands/*.sh`
- Triggers: Slash-command wrappers referenced in `AGENTS.md`, such as `scripts/commands/rec-ensemble.sh`, `scripts/commands/dock-run.sh`, and `scripts/commands/status.sh`.
- Responsibilities: Ensure environment, resolve workspace root, parse generic flags, dispatch agent calls, and inspect handoff status.

**Environment bootstrap:**
- Location: `scripts/setenv.sh`
- Triggers: Manual `source ./scripts/setenv.sh` and automatic sourcing through `scripts/infra/common.sh:init_script()` and `scripts/commands/common.sh:ensure_env()`.
- Responsibilities: Activate the `autoEnsmblDockMD` Conda environment expected by the pipeline.

## Error Handling

**Strategy:** Fail fast in core scripts, then layer structured review/debug metadata on top in the agent stack.

**Patterns:**
- Use `set -euo pipefail` in shell entrypoints such as `scripts/run_pipeline.sh`, `scripts/rec/0_prep.sh`, `scripts/dock/2_gnina.sh`, and `scripts/com/0_prep.sh`.
- Validate prerequisites early with `require_file`, `require_dir`, and `require_cmd` from `scripts/infra/common.sh`.
- Surface orchestration failures through standardized statuses in `scripts/agents/schemas/handoff.py` and role implementations like `scripts/agents/checker.py` and `scripts/agents/debugger.py`.

## Cross-Cutting Concerns

**Logging:** Use timestamped shell logging from `scripts/infra/common.sh` (`log_info`, `log_warn`, `log_error`) and Python-side structured payloads/checkpoints from `scripts/agents/` and `scripts/infra/`.

**Validation:** Validate config sections in `scripts/run_pipeline.sh`, config keys and files in each stage script, output quality in `scripts/agents/checker.py`, and runtime logs in `scripts/infra/monitor.py`.

**Authentication:** Not applicable for application auth. Execution trust is environment-based: Conda activation in `scripts/setenv.sh`, filesystem-based workspace access, and cluster access through Slurm commands invoked from `scripts/infra/common.sh` and `scripts/infra/executor.py`.

---

*Architecture analysis: 2026-04-19*
