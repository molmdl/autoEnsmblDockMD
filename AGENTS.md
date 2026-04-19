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
- Spawns runner/analyzer/checker/debugger pathways based on handoff data.
- Handles resume logic and state recovery from prior sessions.
- Skills:
  - `.opencode/skills/aedmd-orchestrator-resume/SKILL.md`
  - `.opencode/skills/aedmd-status/SKILL.md`

### 2) Runner

Executes stage scripts through slash command wrappers and returns structured outputs/artifacts.

- Wrappers dispatch canonical `WorkflowStage` tokens (for example `receptor_prep`, `docking_run`, `complex_prep`, `complex_md`, `complex_mmpbsa`, `complex_analysis`) aligned with `scripts/agents/schemas/state.py`.
- Wrapper handoff payloads for runner/analyzer include explicit `script` resolved from `scripts/commands/common.sh` stage→script mapping.
- Passes validated parameters/config to script layer.
- Produces deterministic stage outputs and run metadata.
- Skills:
  - `.opencode/skills/aedmd-rec-ensemble/SKILL.md`
  - `.opencode/skills/aedmd-dock-run/SKILL.md`
  - `.opencode/skills/aedmd-com-setup/SKILL.md`
  - `.opencode/skills/aedmd-com-md/SKILL.md`
  - `.opencode/skills/aedmd-com-mmpbsa/SKILL.md`

### 3) Analyzer

Interprets completed simulation outputs into comparative scientific signals for downstream decisions.

- Runs trajectory-analysis workflows after production MD/MM-PBSA.
- Produces ligand-level comparative summaries (RMSD/RMSF/contacts/H-bonds/fingerprints).
- Skills:
  - `.opencode/skills/aedmd-com-analyze/SKILL.md`

### 4) Checker

Validates results against protocol expectations and quality thresholds before downstream progression.

- Reviews generated outputs and key metrics.
- Flags warnings/failures and recommends acceptance criteria decisions.
- Supports human verification checkpoints with concise evidence.
- Skill:
  - `.opencode/skills/aedmd-checker-validate/SKILL.md`

### 5) Debugger

Diagnoses failed stages, traces root causes, and proposes fixes with tool/version awareness.

- Investigates script, config, and environment-level failures.
- Uses version-aware reasoning for GROMACS/gnina/gmx_MMPBSA issues.
- Produces remediation actions that preserve workflow compatibility.
- Skill:
  - `.opencode/skills/aedmd-debugger-diagnose/SKILL.md`

---

## File-Based Handoff Pattern

Agents exchange state through files, not long in-memory threads.

- **HandoffRecord JSON:** structured payload describing stage, status, inputs/outputs, and next action.
- **Checkpoint files:** persisted pause/resume markers for human verification and continuation.
- **Workspace artifacts:** generated outputs in stage directories (`rec/`, `dock/`, `com/`) serve as execution evidence.
- **Planning state artifacts:** `.planning/STATE.md`, phase summaries, and related metadata preserve cross-session continuity.

This pattern supports resumable execution and minimizes context overflow risk.

### Handoff status and wrapper exit behavior

`scripts/commands/common.sh` interprets handoff status values and exits consistently:

| Handoff status | Wrapper behavior | Exit code |
|---|---|---|
| `success` | Continue/complete normally | `0` |
| `needs_review` | Print warnings and request review | `2` |
| `failure` | Print errors/recommendations and fail | `1` |
| `blocked` | Print blocker details and fail | `1` |
| Unknown/missing handoff | Treat as failure | `1` |

---

## Skill File Contract

Skill files referenced in this document are stored at `.opencode/skills/{skill-name}/SKILL.md` and follow the restored YAML-frontmatter format.

- Frontmatter starts/ends with `---` and includes: `name`, `description`, `license`, `compatibility`, and `metadata`.
- The `name` field is the canonical skill identifier and must match slash-command/agent references.
- Body sections use the current structure (for example: **When to use this skill**, **Prerequisites**, **Usage**, **Parameters**, **Expected Output**, **Troubleshooting** where applicable).

---

## Slash Commands → Script Wrappers

| Slash Command | Script Wrapper | Primary Skill Reference |
|---|---|---|
| `/aedmd-rec-ensemble` | `scripts/commands/aedmd-rec-ensemble.sh` | `.opencode/skills/aedmd-rec-ensemble/SKILL.md` |
| `/aedmd-dock-run` | `scripts/commands/aedmd-dock-run.sh` | `.opencode/skills/aedmd-dock-run/SKILL.md` |
| `/aedmd-com-setup` | `scripts/commands/aedmd-com-setup.sh` | `.opencode/skills/aedmd-com-setup/SKILL.md` |
| `/aedmd-com-md` | `scripts/commands/aedmd-com-md.sh` | `.opencode/skills/aedmd-com-md/SKILL.md` |
| `/aedmd-com-mmpbsa` | `scripts/commands/aedmd-com-mmpbsa.sh` | `.opencode/skills/aedmd-com-mmpbsa/SKILL.md` |
| `/aedmd-com-analyze` | `scripts/commands/aedmd-com-analyze.sh` | `.opencode/skills/aedmd-com-analyze/SKILL.md` |
| `/aedmd-checker-validate` | `scripts/commands/aedmd-checker-validate.sh` | `.opencode/skills/aedmd-checker-validate/SKILL.md` |
| `/aedmd-debugger-diagnose` | `scripts/commands/aedmd-debugger-diagnose.sh` | `.opencode/skills/aedmd-debugger-diagnose/SKILL.md` |
| `/aedmd-orchestrator-resume` | `scripts/commands/aedmd-orchestrator-resume.sh` | `.opencode/skills/aedmd-orchestrator-resume/SKILL.md` |
| `/aedmd-status` | `scripts/commands/aedmd-status.sh` | `.opencode/skills/aedmd-status/SKILL.md` |

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

- Install and activate Conda environment from `scripts/env.yml`.
- Ensure required tools are available: **GROMACS > 2022**, **gnina**, **gmx_MMPBSA**.
- Source environment before script execution: `source ./scripts/setenv.sh`.
- Provide stage inputs in `./work/input` (copy to a new workspace run directory as needed).
- Reference manual-trial outputs in `./expected/` and supporting examples in `.reference/`.

---

## Scope Notes

- Workflow step-by-step execution order is documented in `WORKFLOW.md`.
- Project-level requirements and deliverable tracking are maintained in `.planning/PROJECT.md`.
- Future work (outside current scope): ligand preparation automation and `ffnonbond.itp` edit automation.
