---
name: aedmd-workspace-init
description: Use when creating isolated workspace from template for workflow execution
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

This skill creates an isolated run workspace by copying a validated template (typically `work/input`) into a target run directory (for example `work/test` or `work/run_YYYY-MM-DD`) and emits a machine-readable handoff record.

## When to use this skill
- Initialize a fresh workspace before any stage execution.
- Recreate a workspace from a known-good template after cleanup.
- Verify that expected workspace directories/files exist before starting expensive jobs.

## Prerequisites
- Template directory exists and contains `config.ini`.
- Template includes required subdirectories such as `mdp/` (with stage-specific inputs under it).
- Command environment is prepared (`source ./scripts/setenv.sh`) so Python and project modules resolve correctly.

## Usage
- Bash wrapper command:
  - `scripts/commands/aedmd-workspace-init.sh --template work/input --target work/test`
  - Optional overwrite: `scripts/commands/aedmd-workspace-init.sh --template work/input --target work/test --force`
- OpenCode plugin:
  - `.opencode/plugins/workspace-init.js`
  - Plugin name: `aedmd-workspace-init`

## Parameters
| Parameter | Required | Default | Description |
|---|---|---|---|
| `template` | Yes | None | Source template workspace directory (for example `work/input`). |
| `target` | Yes | None | Destination workspace directory to create (for example `work/test`). |
| `force` | No | `false` | Overwrite target directory if it already exists. |

## Expected Output
- HandoffRecord JSON persisted by wrapper to `.handoffs/workspace_init.json`.
- Includes deterministic fields such as:
  - `data.workspace_path`
  - `data.template_source`
  - `metadata.created_dirs`
- Status semantics remain aligned with wrapper/common handoff handling (`success`, `blocked`, `failure`, `needs_review`).

## Troubleshooting
- **Template missing required files**
  - Ensure `config.ini` and `mdp/` exist in the template path.
- **Target already exists**
  - Re-run with `--force` only when overwrite is intended.
- **Permission denied**
  - Confirm write access to parent directory of the target path.
- **Plugin/module import errors**
  - Re-source environment with `source ./scripts/setenv.sh` and retry.

## Related Automation Links
- Wrapper: `scripts/commands/aedmd-workspace-init.sh`
- Complementary wrappers often run next: `scripts/commands/aedmd-preflight.sh`, `scripts/commands/aedmd-handoff-inspect.sh`
- OpenCode plugin: `.opencode/plugins/workspace-init.js`
