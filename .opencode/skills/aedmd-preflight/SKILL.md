---
name: aedmd-preflight
description: Use when a run may fail due to missing config sections, unavailable tools (`gmx`, `gnina`, `gmx_MMPBSA`), or incomplete inputs, and you need mode-aware preflight validation before expensive stages.
license: MIT
compatibility: Requires python 3.10+, gmx/gnina/gmx_MMPBSA for full validation
metadata:
  author: autoEnsmblDockMD
  version: "1.0"
  agent: none
  stage: preflight_validation
  token_savings: "2000-4000"
---

# Preflight Validation

## Overview

Core principle: fail fast on configuration and environment issues before heavy compute. Preflight should emit structured, deterministic findings that wrappers and orchestrators can gate on.

## When to Use
- Before any stage run when you suspect missing keys, bad mode config, or absent inputs.
- After editing `config.ini`, switching docking mode, or changing workspace contents.
- When `needs_review`/`failure` handoffs suggest setup drift.

## Prerequisites
- Workspace is initialized (for example via workspace-init).
- `config.ini` exists and is accessible.
- Conda/project environment is active (`source ./scripts/setenv.sh`).

## Quick Reference
- Wrapper: `scripts/commands/aedmd-preflight.sh --config config.ini`
- Plugin: `.opencode/plugins/preflight.js` (`aedmd-preflight`)
- Primary artifact: `.handoffs/preflight_validation.json`
- Status behavior:
  - `failure` = blocking errors
  - `needs_review` = warnings only
  - `success` = clean readiness

## Parameters
| Parameter | Required | Default | Description |
|---|---|---|---|
| `config` | Yes | `config.ini` (wrapper default) | Configuration file path to validate. |
| `workspace` | No | Auto-detected workspace root | Workspace root used for input/tool/stage-readiness checks. |

## Implementation
- Run wrapper or plugin to produce HandoffRecord JSON.
- Interpret severity buckets deterministically:
  - `errors` should block stage execution.
  - `warnings` should trigger review but can allow continuation.
- Preserve mode-aware checks to avoid false blockers across targeted vs blind docking.

## Mode-Aware Validation Notes
- **Targeted docking mode** checks include required targeted inputs (for example `reference_ligand` expectations).
- **Blind docking mode** checks include autobox configuration requirements and related mode-specific settings.
- Validation behavior is mode-dependent to avoid false blocking for valid alternative modes.

## Common Mistakes
- **Treating warnings as ignorable forever**
  - `needs_review` should be triaged before long MD/MM-PBSA jobs.
- **Validating wrong workspace**
  - Pass explicit workspace when multiple run directories exist.
- **Mode mismatch in config**
  - Ensure `[docking] mode` aligns with required fields (targeted vs blind).
- **Running without environment activation**
  - Source `./scripts/setenv.sh` so tool checks reflect real runtime.

## Related Automation Links
- Wrapper: `scripts/commands/aedmd-preflight.sh`
- Common follow-up inspector: `scripts/commands/aedmd-handoff-inspect.sh`
- OpenCode plugin: `.opencode/plugins/preflight.js`
