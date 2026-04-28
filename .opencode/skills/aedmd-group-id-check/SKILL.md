---
name: aedmd-group-id-check
description: Validate MM/PBSA group IDs against index.ndx before MM/PBSA execution
license: MIT
compatibility: Requires python 3.10+, gmx_MMPBSA workflow artifacts
metadata:
  author: autoEnsmblDockMD
  version: "1.0"
  agent: none
  stage: group_id_check
  token_savings: "900-1800"
---

# MM/PBSA Group ID Consistency Check

This skill validates receptor/ligand MM/PBSA group IDs against the canonical `index.ndx` header ordering to prevent silent mis-grouped energy calculations.

## When to use this skill
- Before running MM/PBSA stage.
- After trajectory/index preparation changes.
- When troubleshooting suspicious MM/PBSA results that might come from group-ID mismatch.

## Prerequisites
- Workspace contains prepared MM/PBSA inputs.
- `index.ndx` is available in expected location for the workspace/stage.
- Conda/project environment is active (`source ./scripts/setenv.sh`).

## Usage
- Bash wrapper command:
  - `scripts/commands/aedmd-group-id-check.sh --workspace work/test`
- OpenCode plugin:
  - `.opencode/plugins/group-id-check.js`
  - Plugin name: `aedmd-group-id-check`

## Parameters
| Parameter | Required | Default | Description |
|---|---|---|---|
| `workspace` | No | Auto-detected workspace root (wrapper) | Workspace to validate for group-ID consistency. |

## Expected Output
- HandoffRecord JSON persisted to `.handoffs/group_id_check.json`.
- Includes detected receptor/ligand group IDs and validation status.
- Outputs warnings/errors when configured IDs diverge from index-derived expectations.

## Troubleshooting
- **index.ndx missing**
  - Complete trajectory/index prep stage before running this check.
- **Group mismatch detected**
  - Use index-header-derived IDs or explicit validated overrides in config.
- **Unexpected IDs from stale files**
  - Regenerate index file from current workspace artifacts and rerun check.

## Related Automation Links
- Wrapper: `scripts/commands/aedmd-group-id-check.sh`
- OpenCode plugin: `.opencode/plugins/group-id-check.js`
- Typical consumer stage: MM/PBSA execution wrappers in `scripts/com/`
