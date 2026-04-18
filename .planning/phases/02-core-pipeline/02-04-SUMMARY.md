---
phase: 02-core-pipeline
plan: 04
subsystem: docking
tags: [bash, gnina, slurm, ensemble-docking, config-driven]

# Dependency graph
requires:
  - phase: 02-core-pipeline
    provides: bash config/common utilities and shared script conventions from 02-01
provides:
  - receptor-to-docking preparation script with GRO to PDB conversion support
  - unified gnina docking launcher for test, blind, and targeted modes
  - per-ligand parallel Slurm submission with ensemble inner-loop docking
affects: [02-05, 02-06, 02-07, 02-08, 02-11]

# Tech tracking
tech-stack:
  added: []
  patterns: [single-script-multi-mode-docking, config-first-gnina-parameters, per-ligand-slurm-jobs]

key-files:
  created:
    - scripts/dock/1_rec4dock.sh
    - scripts/dock/2_gnina.sh
  modified: []

key-decisions:
  - "Consolidated five mode-specific gnina workflows into one config-driven launcher with mode overrides."
  - "Preserved parallel model as one Slurm job per ligand with receptor-ensemble loop inside each job."

patterns-established:
  - "Pattern: scripts source infra/common.sh and expose --config/--help with explicit config key documentation."
  - "Pattern: mode defaults derive from docking intent (blind vs targeted/test) but remain fully overrideable in config."

# Metrics
duration: 3 min
completed: 2026-04-18
---

# Phase 2 Plan 4: Docking execution scripts Summary

**Unified docking execution now supports receptor preparation plus gnina test/blind/targeted submission from a single config-driven interface.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-18T12:49:09Z
- **Completed:** 2026-04-18T12:52:51Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments
- Implemented `scripts/dock/1_rec4dock.sh` to stage receptor ensembles into docking workspace with copy/symlink behavior and optional GRO→PDB conversion.
- Implemented `scripts/dock/2_gnina.sh` to unify test, blind, and targeted gnina workflows behind one `--mode`/`[docking] mode` interface.
- Added per-ligand Slurm submission so each ligand runs in its own job while docking against all ensemble members within that job.

## Task Commits

Each task was committed atomically:

1. **Task 1: Generalize rec4dock and unified gnina script** - `8bd8b15` (feat)

**Plan metadata:** _(pending in next commit)_

## Files Created/Modified
- `scripts/dock/1_rec4dock.sh` - Configurable receptor staging utility with optional symlink mode and GRO-to-PDB conversion for gnina compatibility.
- `scripts/dock/2_gnina.sh` - Unified gnina launcher with mode-specific defaults, ligand discovery/list support, and Slurm-based parallel ligand submission.

## Decisions Made
- Keep a single gnina entrypoint (`2_gnina.sh`) for all docking modes to reduce script divergence and keep mode behavior config-driven.
- Maintain the established workload shape (outer ligand parallelism, inner receptor ensemble loop) to satisfy Slurm parallelization requirements without changing downstream expectations.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Created missing `scripts/dock/` implementation directory and new plan-target scripts**
- **Found during:** Task 1 (Generalize rec4dock and unified gnina script)
- **Issue:** Target script paths did not exist in repository, preventing implementation in-place.
- **Fix:** Created `scripts/dock/` and added `1_rec4dock.sh` and `2_gnina.sh` at planned canonical paths.
- **Files modified:** scripts/dock/1_rec4dock.sh, scripts/dock/2_gnina.sh
- **Verification:** `bash -n` succeeded for both scripts and `scripts/dock/2_gnina.sh --help` rendered mode/config docs.
- **Committed in:** 8bd8b15 (task commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Blocking fix was required to place deliverables at specified paths; no scope expansion.

## Authentication Gates

None.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `02-04` deliverables are complete and verified; docking execution foundation is ready for post-docking scoring and dock-to-complex work.
- No blockers identified from this plan.

---
*Phase: 02-core-pipeline*
*Completed: 2026-04-18*
