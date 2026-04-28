---
name: aedmd-group-id-check
description: Use when MM/PBSA setup may be wrong because receptor/ligand group IDs can drift from `index.ndx` ordering, especially after index regeneration, trajectory prep changes, or suspicious binding-energy results.
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

## Overview

Core principle: treat `index.ndx` header order as canonical and detect group-ID mismatch before MM/PBSA execution. Prevent silent receptor/ligand swap or wrong-group energy decomposition.

## When to Use
- Before MM/PBSA runs when group assignments were regenerated or edited.
- After trajectory/index preparation changes that may reorder groups.
- When results look suspicious (unexpected ΔG trends, inconsistent decomposition) and group mismatch is a candidate cause.

## Prerequisites
- Workspace contains prepared MM/PBSA inputs.
- `index.ndx` is available in expected location for the workspace/stage.
- Conda/project environment is active (`source ./scripts/setenv.sh`).

## Quick Reference
- Wrapper: `scripts/commands/aedmd-group-id-check.sh --workspace work/test`
- Plugin: `.opencode/plugins/group-id-check.js` (`aedmd-group-id-check`)
- Artifact: `.handoffs/group_id_check.json`
- Failure symptom: configured receptor/ligand IDs diverge from `index.ndx` order

## Parameters
| Parameter | Required | Default | Description |
|---|---|---|---|
| `workspace` | No | Auto-detected workspace root (wrapper) | Workspace to validate for group-ID consistency. |

## Implementation
- Run wrapper/plugin before MM/PBSA stage dispatch.
- Parse `index.ndx` headers and compare against configured or propagated IDs.
- Emit HandoffRecord JSON including:
  - resolved receptor/ligand IDs
  - validation status
  - mismatch warnings/errors and recommendations

## Common Mistakes
- **Using stale `index.ndx`**
  - Regenerate index from current trajectory/topology artifacts before check.
- **Ignoring explicit mismatch warnings**
  - Resolve mismatch first; do not proceed to MM/PBSA with uncertain group mapping.
- **Assuming IDs are stable across runs**
  - Group order can change with regenerated files; re-check each workspace.
- **Skipping environment activation**
  - Source `./scripts/setenv.sh` to ensure consistent plugin behavior.

## Related Automation Links
- Wrapper: `scripts/commands/aedmd-group-id-check.sh`
- OpenCode plugin: `.opencode/plugins/group-id-check.js`
- Typical consumer stage: MM/PBSA execution wrappers in `scripts/com/`
