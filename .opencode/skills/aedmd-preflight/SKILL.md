---
name: aedmd-preflight
description: Use when validating config, tools, and inputs before workflow execution
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

This skill performs deterministic readiness checks before running workflow stages, returning structured validation results that can be consumed by wrappers, orchestrators, and checker/debugger flows.

## When to use this skill
- Before launching any workflow stage to catch configuration/tool/input issues early.
- After modifying `config.ini` or switching workspace/mode.
- When validating a newly initialized workspace prior to expensive compute stages.

## Prerequisites
- Workspace is initialized (for example via workspace-init).
- `config.ini` exists and is accessible.
- Conda/project environment is active (`source ./scripts/setenv.sh`).

## Usage
- Bash wrapper command:
  - `scripts/commands/aedmd-preflight.sh --config config.ini`
- OpenCode plugin:
  - `.opencode/plugins/preflight.js`
  - Plugin name: `aedmd-preflight`

## Parameters
| Parameter | Required | Default | Description |
|---|---|---|---|
| `config` | Yes | `config.ini` (wrapper default) | Configuration file path to validate. |
| `workspace` | No | Auto-detected workspace root | Workspace root used for input/tool/stage-readiness checks. |

## Expected Output
- HandoffRecord JSON persisted to `.handoffs/preflight_validation.json` by wrapper.
- Severity-aware findings grouped into `errors`, `warnings`, and informative metadata.
- Status mapped to existing workflow semantics:
  - `failure` for blocking validation errors
  - `needs_review` for non-blocking warnings
  - `success` when checks pass cleanly

## Mode-Aware Validation Notes
- **Targeted docking mode** checks include required targeted inputs (for example `reference_ligand` expectations).
- **Blind docking mode** checks include autobox configuration requirements and related mode-specific settings.
- Validation behavior is mode-dependent to avoid false blocking for valid alternative modes.

## Troubleshooting
- **Missing config sections/keys**
  - Compare with `scripts/config.ini.template` and restore required sections.
- **Tool availability warnings**
  - Ensure `gmx`, `gnina`, and `gmx_MMPBSA` are available in active environment.
- **Unexpected mode errors**
  - Verify docking mode and corresponding required parameters are consistent.
- **Workspace path mismatch**
  - Re-run with explicit workspace path and confirm input files are in expected locations.

## Related Automation Links
- Wrapper: `scripts/commands/aedmd-preflight.sh`
- Common follow-up inspector: `scripts/commands/aedmd-handoff-inspect.sh`
- OpenCode plugin: `.opencode/plugins/preflight.js`
