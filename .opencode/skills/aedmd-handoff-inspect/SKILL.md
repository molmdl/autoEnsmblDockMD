---
name: aedmd-handoff-inspect
description: Parse latest handoff and provide next-action guidance
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

This skill inspects the latest handoff artifact for a workspace, normalizes status for quick interpretation, and provides an actionable next-step recommendation.

## When to use this skill
- Immediately after stage execution to confirm outcome.
- During workflow debugging to inspect latest errors/warnings.
- During resume flows to determine the next valid action from persisted handoff state.

## Prerequisites
- Workspace exists and is accessible.
- `.handoffs/` directory is present or expected for stage outputs.
- Conda/project environment is active (`source ./scripts/setenv.sh`).

## Usage
- Bash wrapper command:
  - `scripts/commands/aedmd-handoff-inspect.sh --workspace work/test`
- OpenCode plugin:
  - `.opencode/plugins/handoff-inspect.js`
  - Plugin name: `aedmd-handoff-inspect`

## Parameters
| Parameter | Required | Default | Description |
|---|---|---|---|
| `workspace` | No | Auto-detected workspace root (wrapper) | Workspace containing `.handoffs` artifacts to inspect. |

## Expected Output
- HandoffRecord JSON persisted by wrapper to `.handoffs/handoff_inspection.json`.
- Core extracted fields include:
  - latest stage name
  - normalized status (`SUCCESS`, `FAILED`, `NEEDS_REVIEW`, `BLOCKED`)
  - next-action recommendation tailored to status
- Warnings/errors from latest handoff are surfaced for downstream checker/debugger use.

## Troubleshooting
- **No handoff files found**
  - Confirm stage commands were run and handoff persistence is enabled.
- **Unexpected status mapping**
  - Verify latest handoff uses canonical status vocabulary expected by wrappers.
- **Workspace detection mismatch**
  - Pass explicit `--workspace` path to avoid resolving the wrong workspace root.

## Related Automation Links
- Wrapper: `scripts/commands/aedmd-handoff-inspect.sh`
- OpenCode plugin: `.opencode/plugins/handoff-inspect.js`
- Typical adjacent command: `scripts/commands/aedmd-status.sh`
