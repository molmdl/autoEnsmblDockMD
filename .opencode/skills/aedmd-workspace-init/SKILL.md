---
name: aedmd-workspace-init
description: Use when starting a new run and `work/input` must be copied into an isolated workspace (`work/test` or `work/run_DATE`), especially when initialization fails due to missing template files or existing target directories.
license: MIT
compatibility: Requires python 3.10+, conda environment
metadata:
  author: autoEnsmblDockMD
  version: "1.0"
  agent: none
  stage: workspace_initialization
  token_savings: "1500-3000"
---

# Workspace Initialization

## Overview

Core principle: create reproducible runs from a known template, never from ad-hoc manual directory edits. Use wrapper/plugin outputs (HandoffRecord JSON) as the source of truth for downstream automation.

## When to Use
- New run setup needs `work/input` copied into `work/test` or `work/run_YYYY-MM-DD`.
- You hit setup blockers like `Workspace exists` or missing `config.ini` in template.
- You need deterministic workspace creation before preflight or stage wrappers.

## Prerequisites
- Template directory exists and contains `config.ini`.
- Template includes required subdirectories such as `mdp/` (with stage-specific inputs under it).
- Command environment is prepared (`source ./scripts/setenv.sh`) so Python and project modules resolve correctly.

## Quick Reference
- Wrapper: `scripts/commands/aedmd-workspace-init.sh`
- Plugin: `.opencode/plugins/workspace-init.js` (`aedmd-workspace-init`)
- Typical success artifact: `.handoffs/workspace_init.json`
- Common follow-up: `scripts/commands/aedmd-preflight.sh`

## Parameters
| Parameter | Required | Default | Description |
|---|---|---|---|
| `template` | Yes | None | Source template workspace directory (for example `work/input`). |
| `target` | Yes | None | Destination workspace directory to create (for example `work/test`). |
| `force` | No | `false` | Overwrite target directory if it already exists. |

## Implementation
- Run wrapper for deterministic initialization:
  - `scripts/commands/aedmd-workspace-init.sh --template work/input --target work/test`
  - Optional overwrite: `... --force`
- Or use OpenCode plugin directly:
  - `.opencode/plugins/workspace-init.js`
- Expected output is HandoffRecord JSON with status (`success`, `blocked`, `failure`, `needs_review`) and fields like:
  - `data.workspace_path`
  - `data.template_source`
  - `metadata.created_dirs`

## Common Mistakes
- **Copying from wrong source directory**
  - Confirm template points to `work/input` (or intentional equivalent), not a stale run directory.
- **Overwriting prior results unintentionally**
  - Use `--force` only when replacement is deliberate and previous outputs are archived.
- **Skipping environment sourcing**
  - Always run `source ./scripts/setenv.sh` before wrapper/plugin calls.
- **Ignoring blocked status**
  - If handoff status is `blocked`, resolve workspace conflict before downstream stages.

## Related Automation Links
- Wrapper: `scripts/commands/aedmd-workspace-init.sh`
- Complementary wrappers often run next: `scripts/commands/aedmd-preflight.sh`, `scripts/commands/aedmd-handoff-inspect.sh`
- OpenCode plugin: `.opencode/plugins/workspace-init.js`
