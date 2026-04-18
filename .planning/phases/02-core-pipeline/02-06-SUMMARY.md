---
phase: 02-core-pipeline
plan: 06
subsystem: docking
tags: [bash, dock2com, gromacs-topology, wrapper, config-driven]

# Dependency graph
requires:
  - phase: 02-core-pipeline
    provides: shared bash config/common utilities and dock2com Python pipeline utilities
provides:
  - dock-to-complex wrapper for batch new-ligand processing
  - dock-to-complex wrapper for reference-ligand processing
  - standardized com/<ligand>/ output assembly with sys.top, complex.gro, and posre_lig.itp
affects: [02-07, 02-08, 02-09, 02-11]

# Tech tracking
tech-stack:
  added: []
  patterns: [python-utility-orchestration-wrapper, config-first-dock2com-shell-interface]

key-files:
  created:
    - scripts/dock/4_dock2com.sh
    - scripts/dock/4_dock2com_ref.sh
  modified: []

key-decisions:
  - "Implemented separate wrappers for new-ligand and reference-ligand workflows while sharing the same Python utility chain."
  - "Validated required Python utilities before execution to fail fast with actionable errors."

patterns-established:
  - "Pattern: shell wrappers source infra/common.sh, expose --config/--help, and orchestrate Python CLI utilities in sequence."
  - "Pattern: workflow outputs are normalized under com/<ligand>/ for downstream MD stages."

# Metrics
duration: 2 min
completed: 2026-04-18
---

# Phase 2 Plan 6: Dock-to-complex shell wrappers Summary

**Config-driven dock2com wrappers now provide single-command orchestration for both new-ligand and reference-ligand complex topology preparation.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-18T13:00:37Z
- **Completed:** 2026-04-18T13:03:10Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments
- Added `scripts/dock/4_dock2com.sh` to run `4_dock2com_1.py` → `4_dock2com_2.py` → `4_dock2com_2.2.1.py` for selected docked ligands.
- Added `scripts/dock/4_dock2com_ref.sh` for reference-ligand topology preparation using reference ligand parameter directories.
- Standardized output assembly to `com/<ligand>/` (or `com/ref/<ligand>/` for reference workflow) with required MD inputs.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create dock2com shell wrappers** - `8e96d5b` (feat)

**Plan metadata:** _(pending in next commit)_

## Files Created/Modified
- `scripts/dock/4_dock2com.sh` - New-ligand dock2com wrapper with config parsing, utility validation, ligand discovery, and output collation.
- `scripts/dock/4_dock2com_ref.sh` - Reference-ligand dock2com wrapper with ref parameter resolution and matching output collation.

## Decisions Made
- Used two explicit wrapper entrypoints (new/reference) to preserve human-friendly CLI while avoiding divergence in underlying Python utility calls.
- Added mandatory preflight checks for `4_dock2com_1.py`, `4_dock2com_2.py`, and `4_dock2com_2.2.1.py` so misconfigured environments fail immediately.

## Deviations from Plan

None - plan executed exactly as written.

## Authentication Gates

None.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Dock-to-complex wrappers are in place and verified (`bash -n` and `--help`) for both new/reference ligand workflows.
- No blockers identified from this plan.

---
*Phase: 02-core-pipeline*
*Completed: 2026-04-18*
