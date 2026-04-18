# Phase 4: Integration - Context

**Gathered:** 2026-04-19
**Status:** Ready for planning

## Phase Boundary

Connect agents to scripts via slash commands and loadable agent skills. Commands expose high-level workflow stages to both human users and orchestrator agents. Skills provide metadata + documentation for agent runtime loading. Mark agent support as experimental throughout documentation.

This phase integrates Phase 2 scripts and Phase 3 agents through a command layer, not adding new workflow capabilities.

## Implementation Decisions

### Slash Command Granularity & Naming

**Decision: Commands target abstract agent-level stages**

- 10 primary commands corresponding to agent WorkflowStage enum:
  - `/rec-ensemble` — receptor preparation, MD, clustering, alignment (stages: REC_PREP → REC_MD → REC_CLUSTER)
  - `/dock-run` — docking execution (stages: DOCK_PREP → DOCK_RUN)
  - `/com-setup` — complex system preparation (stage: COM_PREP)
  - `/com-md` — complex production MD (stage: COM_MD)
  - `/com-mmpbsa` — MM/PBSA calculations (stage: COM_MMPBSA)
  - `/com-analyze` — trajectory analysis (stage: COM_ANA)
  - Plus: `/checker-validate`, `/debugger-diagnose`, `/orchestrator-resume` for on-demand agents

**Rationale:**
- Balances low-cost agent context (fewer commands to load)
- Meaningful workflow units for human orchestration
- Internal orchestration allows fine-grained stage transitions + checkpoints
- Each command maps to one entry in agent routing table for clean dispatch

**Naming Convention:**
- Format: `/{subsystem}-{action}` (e.g., `/rec-ensemble`, `/dock-run`)
- Lowercase, hyphenated
- Matches agent-level stage names converted to command form

### Mode & Workflow Variant Handling

**Decision: Mode and variants are workspace configuration**

- Mode (A: Reference Pocket, B: Blind) specified once in `config.ini` under `[workflow]` section
- Commands auto-detect mode from config; no separate command trees
- Example: `/dock-run` internally calls `gnina_targeted.sh` if mode=A, `gnina_blind.sh` if mode=B
- Docking-only variant (skip MD/MMPBSA) controlled via config: `skip_md=true` in `[workflow]` section
- Commands always execute their full orchestrated set; config determines which stages are skipped

**Rationale:**
- Workspace is immutable once set up (clear boundary)
- Config is "truth" for workflow shape (Phase 2 already established this)
- Prevents user confusion from multiple command trees
- Agents can inspect config once and make consistent decisions

### Command Parameter Handling

**Decision: Three-tier parameter provision**

1. **Config file (primary):** `--config config.ini`
   - Phase 2 scripts already use INI format; reuse directly
   - All stage-specific parameters stored in config sections
   - Example: `[dock]` section contains gnina options, autobox settings, etc.

2. **CLI flags (override):** `/dock-run --autobox-add 10 --config config.ini`
   - Flags override corresponding config values
   - Enables interactive human guidance + agent parameter tuning
   - Runner agent builds command by: config defaults + CLI flag overrides

3. **Interactive prompts (fallback):** Available for agents only
   - When a required parameter is missing, agent can use question tool to gather it
   - Humans bypass via CLI flags
   - Prevents workflow blockage while maintaining flexibility

**Workspace detection:** CWD-based
- `/dock-run` executed from workspace root; paths are relative to CWD
- Supports both local dev (single workspace) and multi-workspace scenarios
- If workspace needs to be explicit in future, add optional `--workspace` flag

**Config validation:**
- Commands validate required sections at startup (e.g., `/dock-run` requires `[dock]` section)
- If missing section: informative error message + suggestion to copy from template
- This keeps setup responsibility on user/agent preparation, not command runtime

### Command Execution & Dispatch

**Decision: Commands dispatch through existing runner agent**

- Orchestrator routes to runner agent with:
  ```json
  {
    "stage": "dock_run",
    "script": "scripts/dock/2_gnina.sh",
    "params": { "autobox_add": 10, "config": "config.ini" },
    "next_agent": "checker"
  }
  ```
- Runner agent:
  1. Validates environment (config, input files)
  2. Builds shell command from script + params
  3. Executes with timeout + output capture
  4. Creates handoff record with status/metrics/warnings
  5. Saves checkpoint for session continuity

**Logging & Output:**
- Full stdout/stderr captured to `.run_logs/{stage}.log`
- Structured JSON handoff written to `.handoffs/{stage}.json`
- Prevents context bloat in handoff payloads while preserving full diagnostics

### Skill Format & Structure

**Decision: DEFERRED TO PLANNING PHASE**

Research needed from planning stage on:
- Whether agent ecosystem expects YAML vs Markdown vs Hybrid
- How gsd-agents (from other GSD projects) structure skills
- Pattern for skill metadata that works across multiple agent systems

**Provisional approach for planning to research:**
- Hybrid format: YAML metadata block + Markdown documentation
- Per-stage skills (not per-agent): `doc/skills/dock_run.skill`, `doc/skills/com_mmpbsa.skill`
- Metadata fields: name, agent, stages, prerequisites, parameters, outputs, error_codes

### Error & Feedback Flow

**Decision: DEFERRED TO PLANNING PHASE**

Research needed from planning stage on:
- OpenCode's convention for agent error reporting (JSON vs structured text)
- How checker/debugger agents typically present issues
- Best practice for balancing console output vs detailed logs for humans

**Provisional approach for planning to research:**
- Console output: Status line + key metrics + warning/error summary (human-readable, <10 lines)
- Detailed output: Logged to files; errors tracked in handoff records
- Debugger escalation: Checker recommends debugging on failures; orchestrator/user decides
- Verbosity control: Global config (`verbose=true/false`) + per-command override (`--verbose`, `--quiet`)

### OpenCode's Discretion

- Exact schema for slash command registration in OpenCode system
- CLI help text format and auto-generation from skills
- Rate limiting / context window management for slash command usage patterns
- Whether to batch multi-stage commands (e.g., `/run-full-workflow`) or keep them granular
- Exact JSON structure for handoff records (Phase 3 schemas are starting point)

## Specific Ideas

- Commands should feel like a natural extension of shell script invocation
- Each command should be runnable standalone (idempotent) or as part of orchestrated sequence
- Skills should be discoverable: `/help dock-run` shows full metadata + examples
- Workspace state should always be inspectable: `/status` shows current stage + gate status
- Integration should preserve human checkpoints: gates still pause workflow, commands just automate script invocation

## Deferred Ideas

- Scheduled command execution (cron-like)
- Command composition/pipelines (running multiple stages in sequence without human intervention)
- Custom command extensions (user-defined commands beyond core stages)
- WebUI or graphical workflow visualization

---

*Phase: 04-integration*
*Context gathered: 2026-04-19*
