---
name: debugger-diagnose
description: Use when a pipeline stage fails or outputs are unexpected and you need diagnosis with concrete remediation steps.
license: MIT
compatibility: Requires gnina, gromacs 2022+, python 3.10+
metadata:
  author: autoEnsmblDockMD
  version: "1.0"
  agent: debugger
  stage: failure_diagnosis
---

# Failure Diagnosis

This skill inspects stage logs and handoff errors to identify root causes, version-sensitive incompatibilities, and practical recovery actions for GROMACS, gnina, and gmx_MMPBSA workflows.

## When to use this skill
- Runner reports `failure` or `blocked` status in handoff records.
- Stage logs show fatal GROMACS/gnina/gmx_MMPBSA errors.
- You need prioritized troubleshooting steps after repeated retries.

## Prerequisites
- Error logs are available in `.run_logs/`.
- Related handoff record exists in `.handoffs/`.

## Usage
Command: `scripts/commands/debugger-diagnose.sh --config config.ini`
Agent dispatch: `python -m scripts.agents --agent debugger --input handoff.json`

## Expected Output
- Diagnosis report with likely causes and confidence levels.
- Suggested fixes and next command recommendations.

## Troubleshooting
- Missing logs: re-run failed stage with logging enabled.
- Ambiguous diagnosis: include the latest failing handoff as debugger input.
