---
name: aedmd-status
description: Use when inspecting current workspace progress, detected workflow mode, completed stages, pending stages, and last handoff status.
license: MIT
compatibility: Requires gnina, gromacs 2022+, python 3.10+
metadata:
  author: autoEnsmblDockMD
  version: "1.0"
  agent: none
  stage: workspace_status
---

# Workspace Status Inspection

This skill summarizes workspace execution state without dispatching an agent, including mode/config detection and stage completion signals from handoff artifacts.

## When to use this skill
- You need a quick snapshot before launching the next command.
- You want to confirm which stages are complete vs pending.
- You need to inspect the last handoff outcome after interruptions.

## Prerequisites
- Workspace contains pipeline config and/or prior stage artifacts.
- `scripts/commands/aedmd-status.sh` is available.

## Usage
Command: `scripts/commands/aedmd-status.sh --config config.ini`
Agent dispatch: `N/A (no agent dispatch for this command)`

## Parameters
| Parameter | Config Key | CLI Flag | Default | Description |
|-----------|------------|----------|---------|-------------|
| Config file | `general.config` | `--config` | `config.ini` | Configuration file used to detect workflow mode and expected paths. |
| Workspace root | `general.workdir` | `--workdir` | `./work/test` | Root workspace scanned for stage artifacts and completion markers. |
| Verbose status | `status.verbose` | `--verbose` | `false` | Include detailed per-stage path checks in status output. |

## Expected Output
- Human-readable summary of mode, completed stages, pending stages.
- Last handoff status and path hints to relevant logs/artifacts.

## Troubleshooting
- Empty status: verify command is executed from a valid workspace root.
- Missing mode info: ensure `config.ini` has workflow/docking mode settings.
