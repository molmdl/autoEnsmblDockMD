---
name: checker-validate
description: Use when validating outputs from any completed workflow stage, especially when quality or consistency concerns are reported.
license: MIT
compatibility: Requires gnina, gromacs 2022+, python 3.10+
metadata:
  author: autoEnsmblDockMD
  version: "1.0"
  agent: checker
  stage: quality_validation
---

# Result Validation

This skill runs on-demand quality checks by inspecting handoff records and generated outputs to flag anomalies and produce actionable validation feedback.

## When to use this skill
- A stage completed but results seem suspicious or inconsistent.
- You need structured quality checks before proceeding to next stage.
- Warnings were emitted in `.handoffs/*.json` and require review.

## Prerequisites
- At least one stage handoff record exists in `.handoffs/`.
- Stage output files are present in workspace directories.

## Usage
Command: `scripts/commands/checker-validate.sh --config config.ini`
Agent dispatch: `python -m scripts.agents --agent checker --input handoff.json`

## Expected Output
- Validation report summarizing pass/warn/fail findings.
- Updated handoff/recommendations for next actions.

## Troubleshooting
- No handoff found: run a pipeline stage first to generate `.handoffs/{stage}.json`.
- Incomplete report: verify referenced output paths still exist.
