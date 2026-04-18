---
name: orchestrator-resume
description: Use when resuming an interrupted workflow session from saved checkpoints and handoff state.
license: MIT
compatibility: Requires gnina, gromacs 2022+, python 3.10+
metadata:
  author: autoEnsmblDockMD
  version: "1.0"
  agent: orchestrator
  stage: workflow_resume
---

# Workflow Resume

This skill restores session continuity by reading checkpoint/handoff state, identifying the last completed stage, and selecting the next safe stage to execute.

## When to use this skill
- A previous agent session ended before workflow completion.
- You need to continue from the latest validated checkpoint.
- You want to avoid rerunning completed, expensive stages.

## Prerequisites
- Checkpoint state and handoff files exist in workspace metadata directories.
- Workflow config is unchanged or intentionally versioned.

## Usage
Command: `scripts/commands/orchestrator-resume.sh --config config.ini`
Agent dispatch: `python -m scripts.agents --agent orchestrator --input handoff.json`

## Expected Output
- Resume decision (last completed stage, next stage, rationale).
- Updated checkpoint record for continued execution.

## Troubleshooting
- No checkpoint state: run `status` to inspect workspace and start from earliest incomplete stage.
- Conflicting state files: use newest successful handoff timestamp as source of truth.
