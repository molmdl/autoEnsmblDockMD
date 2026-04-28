---
name: aedmd-handoff-inspect
description: Use when stage outcomes are unclear, `.handoffs/*.json` needs quick triage, or resume/debug flow requires normalized status (`SUCCESS`, `FAILED`, `NEEDS_REVIEW`, `BLOCKED`) with next-action guidance.
license: MIT
compatibility: Requires python 3.10+, conda environment
metadata:
  author: autoEnsmblDockMD
  version: "1.0"
  agent: none
  stage: handoff_inspection
  token_savings: "1200-2500"
---

# Handoff Inspection

## Overview

Core principle: treat handoff files as the canonical run-state ledger. Normalize latest status fast so operators and orchestrators can decide the next command without manually parsing JSON.

## When to Use
- You need immediate pass/fail/review triage after a stage run.
- Resume flow is ambiguous and latest handoff status must be interpreted.
- Debugging requires extracting errors, warnings, and recommendations from `.handoffs`.

## Prerequisites
- Workspace exists and is accessible.
- `.handoffs/` directory is present or expected for stage outputs.
- Conda/project environment is active (`source ./scripts/setenv.sh`).

## Quick Reference
- Wrapper: `scripts/commands/aedmd-handoff-inspect.sh --workspace work/test`
- Plugin: `.opencode/plugins/handoff-inspect.js` (`aedmd-handoff-inspect`)
- Output artifact: `.handoffs/handoff_inspection.json`
- Normalized labels: `SUCCESS`, `FAILED`, `NEEDS_REVIEW`, `BLOCKED`

## Parameters
| Parameter | Required | Default | Description |
|---|---|---|---|
| `workspace` | No | Auto-detected workspace root (wrapper) | Workspace containing `.handoffs` artifacts to inspect. |

## Implementation
- Run wrapper/plugin to inspect the latest handoff by file mtime.
- Extract and normalize stage status for compact operator-facing summaries.
- Preserve downstream-consumable fields for checker/debugger handoff:
  - latest stage name
  - normalized status
  - next-action recommendation
  - surfaced warnings/errors

## Common Mistakes
- **Inspecting stale workspace**
  - Explicitly pass `--workspace` when multiple runs coexist.
- **Assuming unknown status is success**
  - Treat unmapped/unknown values as failure-path and inspect raw JSON.
- **Skipping follow-up after `NEEDS_REVIEW`**
  - Review warnings before triggering next heavy stage.
- **Running before any handoffs exist**
  - Confirm at least one stage wrapper has persisted `.handoffs/*.json`.

## Related Automation Links
- Wrapper: `scripts/commands/aedmd-handoff-inspect.sh`
- OpenCode plugin: `.opencode/plugins/handoff-inspect.js`
- Typical adjacent command: `scripts/commands/aedmd-status.sh`
