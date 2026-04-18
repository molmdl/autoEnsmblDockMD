---
phase: 02-core-pipeline
plan: 03
subsystem: docking
tags: [bash, python, mol2, gro, sdf, amber, format-conversion]

# Dependency graph
requires:
  - phase: 02-core-pipeline
    provides: bash config/common utilities and script conventions from 02-01
provides:
  - config-driven GRO to MOL2 shell wrapper for ligand batches
  - generalized AMBER GRO+ITP to MOL2 converter with CLI and importable API
  - config-driven SDF to GRO batch conversion for dock-to-MD handoff
affects: [02-05, 02-06, 02-07, 02-08, 02-11]

# Tech tracking
tech-stack:
  added: []
  patterns: [config-first-conversion-scripts, wrapper-plus-library-python-utility, shared-infra-common-sh]

key-files:
  created:
    - scripts/dock/0_gro2mol2.sh
    - scripts/dock/0_gro_itp_to_mol2.py
    - scripts/dock/0_sdf2gro.sh
    - scripts/dock/gro_itp_to_mol2.py
    - scripts/dock/__init__.py
    - scripts/__init__.py
  modified: []

key-decisions:
  - "Preserve the vetted 659-line AMBER conversion logic and layer CLI/config/logging enhancements without rewriting the core parser/mapping behavior."
  - "Expose a stable import path (scripts.dock.gro_itp_to_mol2:convert) via a thin wrapper while keeping executable script naming aligned with numeric workflow order."

patterns-established:
  - "Pattern: shell converters source infra/common.sh, validate inputs, and expose --config/--help interfaces."
  - "Pattern: conversion Python utilities support both direct CLI execution and reusable library mode."

# Metrics
duration: 4 min
completed: 2026-04-18
---

# Phase 2 Plan 3: Docking ligand conversion scripts Summary

**Docking ligand format bridges now support GRO↔MOL2/SDF→GRO workflows with config-driven wrappers and a preserved AMBER edge-case converter in reusable CLI+library form.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-18T12:50:06Z
- **Completed:** 2026-04-18T12:55:02Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Added `scripts/dock/0_gro2mol2.sh` to batch-convert ligand GRO+ITP pairs into MOL2 using shared infra utilities and config-driven paths.
- Added `scripts/dock/0_sdf2gro.sh` to batch-convert docking SDF outputs into GRO files for downstream complex MD setup.
- Generalized `scripts/dock/0_gro_itp_to_mol2.py` from the existing AMBER utility, preserving atom typing/charge/bond edge handling while adding argparse, config overrides, logging, and validation.
- Added importable library entrypoint `scripts.dock.gro_itp_to_mol2:convert` via `scripts/dock/gro_itp_to_mol2.py`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Generalize ligand conversion shell scripts** - `24191c6` (feat)
2. **Task 2: Generalize AMBER GRO+ITP to MOL2 converter** - `33dc55a` (feat)

**Plan metadata:** _(pending in next commit)_

## Files Created/Modified
- `scripts/dock/0_gro2mol2.sh` - Configurable GRO+ITP→MOL2 batch wrapper with input checks and progress logging.
- `scripts/dock/0_sdf2gro.sh` - Configurable SDF→GRO batch wrapper with optional recursive discovery.
- `scripts/dock/0_gro_itp_to_mol2.py` - Core AMBER-compatible converter generalized with CLI/config/logging/library support.
- `scripts/dock/gro_itp_to_mol2.py` - Import wrapper exposing stable `convert` API.
- `scripts/dock/__init__.py` - Dock package marker for import paths.
- `scripts/__init__.py` - Top-level package marker for `scripts.*` imports.

## Decisions Made
- Keep the proven GRO+ITP conversion logic intact and only generalize interfaces around it to avoid regressions in previously debugged AMBER edge cases.
- Accept `.itp` and historical `*_gmx.top` topology inputs for compatibility with existing ligand preparation outputs.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed wrapper import initialization for dataclass-based implementation module**
- **Found during:** Task 2 (library mode verification)
- **Issue:** Dynamic wrapper import failed because the implementation module was not registered in `sys.modules` before execution, causing dataclass initialization to error.
- **Fix:** Registered the dynamically loaded implementation module in `sys.modules` before `exec_module`.
- **Files modified:** scripts/dock/gro_itp_to_mol2.py
- **Verification:** `python -c "from scripts.dock.gro_itp_to_mol2 import convert; print(callable(convert))"` returned `True`.
- **Committed in:** 33dc55a (task commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Fix was required to satisfy planned library mode; no scope expansion.

## Authentication Gates

None.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Docking conversion artifacts for both CHARMM and AMBER paths are now in place and verified.
- Ready for downstream post-docking and dock-to-complex plans.

---
*Phase: 02-core-pipeline*
*Completed: 2026-04-18*
