# Human and Agent Documentation Consistency Report

**Analysis Date:** 2026-04-19
**Scope:** Human-facing docs and agent-facing docs cross-checked against implemented scripts and config without executing commands.

## Sources Reviewed

### Human-facing documentation
- `README.md`
- `WORKFLOW.md`
- `docs/GUIDE.md`
- `docs/EXPERIMENTAL.md`

### Agent-facing documentation
- `AGENTS.md`
- `.opencode/skills/rec-ensemble/SKILL.md`
- `.opencode/skills/dock-run/SKILL.md`
- `.opencode/skills/com-setup/SKILL.md`
- `.opencode/skills/com-md/SKILL.md`
- `.opencode/skills/com-mmpbsa/SKILL.md`
- `.opencode/skills/com-analyze/SKILL.md`
- `.opencode/skills/status/SKILL.md`
- `.opencode/skills/orchestrator-resume/SKILL.md`
- `.opencode/skills/checker-validate/SKILL.md`
- `.opencode/skills/debugger-diagnose/SKILL.md`

### Code and config checked as source of truth
- `scripts/run_pipeline.sh`
- `scripts/config.ini.template`
- `scripts/setenv.sh`
- `scripts/env.yml`
- `scripts/commands/common.sh`
- `scripts/commands/status.sh`
- `scripts/commands/rec-ensemble.sh`
- `scripts/commands/dock-run.sh`
- `scripts/commands/com-setup.sh`
- `scripts/commands/com-md.sh`
- `scripts/commands/com-mmpbsa.sh`
- `scripts/commands/com-analyze.sh`
- `scripts/commands/orchestrator-resume.sh`
- `scripts/commands/checker-validate.sh`
- `scripts/commands/debugger-diagnose.sh`
- `scripts/agents/__main__.py`
- `scripts/agents/__init__.py`
- `scripts/agents/utils/routing.py`
- `scripts/agents/runner.py`
- `scripts/agents/analyzer.py`
- `scripts/agents/orchestrator.py`
- `scripts/agents/checker.py`
- `scripts/agents/debugger.py`
- `scripts/agents/schemas/handoff.py`
- `scripts/agents/schemas/state.py`
- `scripts/infra/checkpoint.py`
- `scripts/infra/state.py`

## High-level Consistency Summary

## Consistent areas

- Human docs consistently present the project as script-first and agents as experimental around the same script baseline in `README.md`, `WORKFLOW.md`, `docs/EXPERIMENTAL.md`, and `AGENTS.md`.
- Human docs consistently point to `scripts/run_pipeline.sh` as the main manual entrypoint, which matches `scripts/run_pipeline.sh`.
- Human docs consistently point to `scripts/config.ini.template` as the canonical config template, which matches `README.md`, `docs/GUIDE.md`, `WORKFLOW.md`, and `scripts/config.ini.template`.
- Agent docs consistently describe YAML-frontmatter skill files, which matches `.opencode/skills/*/SKILL.md`.
- Slash-command names in `AGENTS.md` match files under `scripts/commands/`.

## Material drift / inconsistency

### 1) Handoff persistence is documented, but command bridge code does not write `.handoffs/*.json`
- Docs state that agents exchange state through handoff files in `AGENTS.md` and multiple skill docs expect outputs such as `.handoffs/receptor_cluster.json`, `.handoffs/docking_run.json`, and similar.
- `scripts/commands/common.sh` calls `python -m scripts.agents ... --input <(printf ...)` and then immediately checks `.handoffs/${stage}.json` in `check_handoff_result()`.
- `scripts/agents/__main__.py` writes agent output to stdout by default and only writes to a file when `--output` is explicitly provided.
- `scripts/commands/common.sh` never passes `--output`, so documented handoff files are not produced by the current bridge path.
- `scripts/agents/schemas/handoff.py` supports saving handoffs, but the standard command bridge path does not call `HandoffRecord.save()`.

**Assessment:** Documentation reflects intended behavior; code path is incomplete or drifted.

### 2) `status` documentation describes workflow mode detection, but implementation reads the wrong config section
- `README.md`, `AGENTS.md`, and `.opencode/skills/status/SKILL.md` describe status inspection as detecting workflow mode.
- `scripts/commands/status.sh` reads `[workflow] mode` from config.
- `scripts/config.ini.template` does not define a `[workflow]` section; the active mode is under `[docking] mode`.

**Assessment:** The current status implementation does not match the documented configuration model.

### 3) `docs/GUIDE.md` and `.opencode/skills/status/SKILL.md` document `--workdir` for `status`, but `status.sh` does not use it
- `docs/GUIDE.md` recommends `bash scripts/commands/status.sh --workdir work/my_project`.
- `.opencode/skills/status/SKILL.md` lists `--workdir` as a supported parameter.
- `scripts/commands/status.sh` determines workspace from `find_workspace_root()` and only uses `$CONFIG`; it does not consume the forwarded `--workdir` value.

**Assessment:** User-facing and skill-facing docs overstate the current CLI behavior.

### 4) Agent role ownership for `com-analyze` is inconsistent across docs and code
- `AGENTS.md` lists `.opencode/skills/com-analyze/SKILL.md` under the Runner role.
- `.opencode/skills/com-analyze/SKILL.md` metadata sets `agent: analyzer`.
- `scripts/commands/com-analyze.sh` dispatches `analyzer`.
- `scripts/agents/utils/routing.py` routes `WorkflowStage.COM_ANA` to `analyzer`.

**Assessment:** `AGENTS.md` is drifted; code and skill metadata agree that analysis belongs to the analyzer role.

### 5) Agent wrapper stage names do not line up cleanly with implemented agent stage handling
- `scripts/commands/rec-ensemble.sh` dispatches stage `rec_ensemble`, but `scripts/agents/runner.py` expects a `script` field in input data and does not derive a script from stage.
- `scripts/commands/dock-run.sh`, `scripts/commands/com-setup.sh`, `scripts/commands/com-md.sh`, and `scripts/commands/com-mmpbsa.sh` have the same bridge pattern.
- `scripts/commands/com-analyze.sh` dispatches stage `com_analyze`, but `scripts/agents/analyzer.py` only maps `complex_analysis` and `receptor_cluster` in `STAGE_ANALYSIS_MAP`.
- `scripts/commands/orchestrator-resume.sh` dispatches `orchestrator_resume`, but `scripts/agents/orchestrator.py` parses stage values using `WorkflowStage` values from `scripts/agents/schemas/state.py`, and `orchestrator_resume` is not one of them.

**Assessment:** Agent-facing docs imply end-to-end slash-command operability, but the current stage naming and payload contracts are not aligned.

### 6) `AGENTS.md` workspace artifact paths drift from the actual workspace layout
- `AGENTS.md` cites workspace artifacts in `rec/`, `dock/`, `com_md/`, and `mmpbsa/`.
- `README.md`, `WORKFLOW.md`, `docs/GUIDE.md`, and `scripts/config.ini.template` consistently use `rec/`, `dock/`, and `com/` as the primary workspace layout.
- `scripts/config.ini.template` sets `[mmpbsa] workdir = ${complex:workdir}`, which keeps MM/PBSA under `com/` by default rather than a top-level `mmpbsa/` directory.

**Assessment:** `AGENTS.md` should be updated to match the implemented workspace layout.

### 7) Environment-sourcing docs are accurate for manual scripts but incomplete for slash-command behavior
- Human docs consistently say to run `source ./scripts/setenv.sh` before using scripts.
- `scripts/commands/common.sh` already calls `ensure_env()` and sources `scripts/setenv.sh` automatically when using slash-command bridge scripts.

**Assessment:** No contradiction, but human and agent docs omit a useful implementation detail for command wrappers.

### 8) `orchestrator-resume`, `checker-validate`, and `debugger-diagnose` docs describe file artifacts that are only partially implemented
- `.opencode/skills/orchestrator-resume/SKILL.md`, `.opencode/skills/checker-validate/SKILL.md`, and `.opencode/skills/debugger-diagnose/SKILL.md` describe checkpoint, handoff, and log-driven workflows.
- `scripts/infra/checkpoint.py` and `scripts/infra/state.py` implement `.checkpoints/` and `.agent_state.json` persistence.
- `scripts/agents/debugger.py` writes debug reports into `.debug_reports/`.
- The standard command bridge still lacks automatic `.handoffs/*.json` persistence, which the checker/debugger/status docs assume.

**Assessment:** The persistence model exists in parts, but docs currently describe a more complete handoff-file lifecycle than the command bridge implements.

## Possible citations to add

## Human-facing docs

### `README.md`
- Add direct citations to `scripts/run_pipeline.sh` when describing supported flags and stage selection.
- Add a citation to `scripts/config.ini.template` in the Quick Start and Configuration sections.
- Add a citation to `scripts/commands/common.sh` if documenting that slash-command wrappers auto-source `scripts/setenv.sh`.

### `WORKFLOW.md`
- Add a citation to `scripts/run_pipeline.sh` for the authoritative stage alias list.
- Add a citation to `scripts/config.ini.template` where required config sections are enumerated.
- Add a citation to `scripts/rec/5_align.py` in Stage 1 and to `scripts/dock/0_gro_itp_to_mol2.py` / `scripts/dock/4_dock2com_1.py` / `scripts/dock/4_dock2com_2.py` where Python helpers are referenced.

### `docs/GUIDE.md`
- Add a citation to `scripts/commands/status.sh` in the status example, together with a note that the current implementation resolves workspace from the current directory rather than a consumed `--workdir` flag.
- Add a citation to `scripts/config.ini.template` for every config table section to make it obvious that the tables are derived from the canonical template.

## Agent-facing docs

### `AGENTS.md`
- Add citations to `scripts/commands/*.sh` in the slash-command mapping table.
- Add citations to `scripts/agents/__main__.py`, `scripts/agents/__init__.py`, and `scripts/agents/utils/routing.py` in the role/mapping sections.
- Add citations to `scripts/infra/checkpoint.py`, `scripts/infra/state.py`, and `scripts/agents/schemas/handoff.py` in the file-based handoff section.

### Skill docs in `.opencode/skills/*/SKILL.md`
- Add citations to the corresponding wrapper script under `scripts/commands/`.
- Add citations to the underlying stage scripts under `scripts/run_pipeline.sh` and the relevant stage scripts under `scripts/rec/`, `scripts/dock/`, or `scripts/com/`.
- Add a citation to `scripts/agents/utils/routing.py` or `scripts/agents/*.py` when role ownership is asserted.

## Recommended doc updates

### Update immediately
1. Fix `AGENTS.md` to move `com-analyze` from Runner to Analyzer and to correct workspace artifact paths from `com_md/` / `mmpbsa/` to implemented defaults under `com/`.
2. Fix `.opencode/skills/status/SKILL.md` and `docs/GUIDE.md` so documented `status` behavior matches `scripts/commands/status.sh`, or update `scripts/commands/status.sh` to consume `--workdir` and read `[docking] mode`.
3. Add a clear note in `AGENTS.md`, `docs/EXPERIMENTAL.md`, and skill docs that `.handoffs/*.json` persistence is expected by the design, but the current bridge implementation in `scripts/commands/common.sh` and `scripts/agents/__main__.py` does not yet materialize those files automatically.

### Update soon
4. Align skill-stage naming with actual agent stage contracts across `scripts/commands/*.sh`, `.opencode/skills/*/SKILL.md`, `scripts/agents/utils/routing.py`, `scripts/agents/analyzer.py`, and `scripts/agents/orchestrator.py`.
5. Add code citations to key assertions so future documentation drift is easier to detect during review.

## Bottom line

Human-facing pipeline documentation is mostly consistent with the script-based implementation in `scripts/run_pipeline.sh` and `scripts/config.ini.template`.

The main consistency problems are concentrated in the agent/slash-command layer: `AGENTS.md`, `.opencode/skills/*/SKILL.md`, and `docs/EXPERIMENTAL.md` describe a handoff-driven wrapper system that is only partially reflected in the current bridge code under `scripts/commands/` and `scripts/agents/`.
