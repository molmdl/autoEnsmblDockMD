# AGENTS.md — Agent Overview for autoEnsmblDockMD

Agent roles and execution boundaries for the docking→MD→MM/PBSA workflow toolkit.

> [!WARNING]
> **EXPERIMENTAL AGENT SUPPORT**
> Agent-based operation is experimental. The stable baseline remains a script-driven, human-validated workflow.

---

## Overview

autoEnsmblDockMD uses agents to orchestrate and validate workflow stages, while scripts remain the source of truth for execution.

- Agents **call scripts** and stage wrappers; they do not replace protocol scripts.
- Slash commands are thin entry points under `scripts/commands/`.
- Stage logic, options, and reproducibility live in `./scripts/` and config files.
- Human checkpoints are first-class for verification and session continuation.
- File-based handoffs reduce context-window pressure and preserve resumability.

---

## Agent Types

### 1) Orchestrator

Owns global workflow state, routes stage work to specialist agents, and pauses/resumes at checkpoints.

- Tracks current phase/stage and execution status.
- Spawns runner/checker/debugger pathways based on handoff data.
- Handles resume logic and state recovery from prior sessions.
- Skills:
  - `.opencode/skills/orchestrator-resume/SKILL.md`
  - `.opencode/skills/status/SKILL.md`

### 2) Runner

Executes stage scripts through slash command wrappers and returns structured outputs/artifacts.

- Resolves stage intent to script entry points in `scripts/commands/*.sh`.
- Passes validated parameters/config to script layer.
- Produces deterministic stage outputs and run metadata.
- Skills:
  - `.opencode/skills/rec-ensemble/SKILL.md`
  - `.opencode/skills/dock-run/SKILL.md`
  - `.opencode/skills/com-setup/SKILL.md`
  - `.opencode/skills/com-md/SKILL.md`
  - `.opencode/skills/com-mmpbsa/SKILL.md`
  - `.opencode/skills/com-analyze/SKILL.md`

### 3) Checker

Validates results against protocol expectations and quality thresholds before downstream progression.

- Reviews generated outputs and key metrics.
- Flags warnings/failures and recommends acceptance criteria decisions.
- Supports human verification checkpoints with concise evidence.
- Skill:
  - `.opencode/skills/checker-validate/SKILL.md`

### 4) Debugger

Diagnoses failed stages, traces root causes, and proposes fixes with tool/version awareness.

- Investigates script, config, and environment-level failures.
- Uses version-aware reasoning for GROMACS/gnina/gmx_MMPBSA issues.
- Produces remediation actions that preserve workflow compatibility.
- Skill:
  - `.opencode/skills/debugger-diagnose/SKILL.md`

---

## File-Based Handoff Pattern

Agents exchange state through files, not long in-memory threads.

- **HandoffRecord JSON:** structured payload describing stage, status, inputs/outputs, and next action.
- **Checkpoint files:** persisted pause/resume markers for human verification and continuation.
- **Workspace artifacts:** generated outputs in stage directories (`rec/`, `dock/`, `com_md/`, `mmpbsa/`) serve as execution evidence.
- **Planning state artifacts:** `.planning/STATE.md`, phase summaries, and related metadata preserve cross-session continuity.

This pattern supports resumable execution and minimizes context overflow risk.

---

## Slash Commands → Script Wrappers

| Slash Command | Script Wrapper | Primary Skill Reference |
|---|---|---|
| `/rec-ensemble` | `scripts/commands/rec-ensemble.sh` | `.opencode/skills/rec-ensemble/SKILL.md` |
| `/dock-run` | `scripts/commands/dock-run.sh` | `.opencode/skills/dock-run/SKILL.md` |
| `/com-setup` | `scripts/commands/com-setup.sh` | `.opencode/skills/com-setup/SKILL.md` |
| `/com-md` | `scripts/commands/com-md.sh` | `.opencode/skills/com-md/SKILL.md` |
| `/com-mmpbsa` | `scripts/commands/com-mmpbsa.sh` | `.opencode/skills/com-mmpbsa/SKILL.md` |
| `/com-analyze` | `scripts/commands/com-analyze.sh` | `.opencode/skills/com-analyze/SKILL.md` |
| `/checker-validate` | `scripts/commands/checker-validate.sh` | `.opencode/skills/checker-validate/SKILL.md` |
| `/debugger-diagnose` | `scripts/commands/debugger-diagnose.sh` | `.opencode/skills/debugger-diagnose/SKILL.md` |
| `/orchestrator-resume` | `scripts/commands/orchestrator-resume.sh` | `.opencode/skills/orchestrator-resume/SKILL.md` |
| `/status` | `scripts/commands/status.sh` | `.opencode/skills/status/SKILL.md` |

---

## Constraints (Safety + Operating Rules)

- **No `rm` except in workspace test directories** for temporary test artifacts. Any `rm` use must be reported and explicitly approved.
- **Never require `sudo`.**
- **Environment sourcing required:** `source ./scripts/setenv.sh` before project scripts/commands.
- **Conda environment only:** do not modify system-wide Python installations.
- **Validation workspace:** prefer `work/test`; user-provided inputs are under `./work/input`.
- **Maintain backward compatibility** when editing core workflow behavior.
- **Configuration-driven implementation** over hardcoded values.
- **Preserve multi-job manager support** in shell scripts.
- **Keep I/O and coding style consistent** across scripts and stages.
- **Professional tone:** clear, concise outputs with error checks.
- **Interaction policy:** use question-style interactions for approvals/uncertainties.
- **Session reporting:** summarize completed work and remaining to-do items in planning artifacts.

---

## Prerequisites

- Install and activate Conda environment from `env.yml`.
- Ensure required tools are available: **GROMACS > 2022**, **gnina**, **gmx_MMPBSA**.
- Source environment before script execution: `source ./scripts/setenv.sh`.
- Provide stage inputs in `./work/input` (copy to a new workspace run directory as needed).
- Reference manual-trial outputs in `./expected/` and supporting examples in `.reference/`.

---

## Scope Notes

- Workflow step-by-step execution order is documented in `WORKFLOW.md`.
- Project-level requirements and deliverable tracking are maintained in `.planning/PROJECT.md`.
- Future work (outside current scope): ligand preparation automation and `ffnonbond.itp` edit automation.
