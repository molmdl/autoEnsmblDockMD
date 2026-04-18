---
phase: 02-core-pipeline
plan: 02
subsystem: api
tags: [bash, python, mdanalysis, gromacs, slurm, receptor, ensemble]

# Dependency graph
requires:
  - phase: 02-core-pipeline
    provides: bash config/common infrastructure from 02-01
provides:
  - generalized receptor preparation and ensemble extraction shell scripts
  - configurable MDAnalysis receptor ensemble alignment utility
  - AMBER/CHARMM force-field selection through shared INI config
affects: [02-03, 02-05, 02-06, 02-07, 02-08, 02-09, 02-11]

# Tech tracking
tech-stack:
  added: []
  patterns: [config-driven-rec-scripts, common-sh-runtime, mdanalysis-alignment-cli]

key-files:
  created:
    - scripts/rec/0_prep.sh
    - scripts/rec/1_pr_rec.sh
    - scripts/rec/3_ana.sh
    - scripts/rec/4_cluster.sh
    - scripts/rec/5_align.py
  modified: []

key-decisions:
  - "Keep receptor stage scripts config-driven with shared common.sh lifecycle and wrappers."
  - "Use Slurm array submission for receptor production trials to satisfy parallel execution requirements."

patterns-established:
  - "Pattern: each stage script supports --help and --config consistently."
  - "Pattern: separate shell stage orchestration from Python structure-alignment utility."

# Metrics
duration: 1 min
completed: 2026-04-18
---

# Phase 2 Plan 2: Receptor ensemble generation scripts Summary

**Config-driven receptor pipeline scripts now automate prep→MD→analysis→clustering and align extracted ensemble structures to a reference complex with MDAnalysis.**

## Performance

- **Duration:** 1 min
- **Started:** 2026-04-18T12:54:24Z
- **Completed:** 2026-04-18T12:56:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Added generalized receptor prep, production, analysis, and clustering bash scripts in `scripts/rec/` that source `scripts/infra/common.sh`, accept `--config`, and expose `--help`.
- Implemented config-driven support for AMBER/CHARMM force-field selection and Slurm execution parameters across receptor stage scripts.
- Added `scripts/rec/5_align.py` for reusable MDAnalysis-based ensemble alignment with CLI and INI config support plus RMSD summary reporting.

## Task Commits

Each task was committed atomically:

1. **Task 1: Generalize receptor bash scripts** - `9bb20be` (feat)
2. **Task 2: Create ensemble alignment script** - `ed9a246` (feat)

**Plan metadata:** _(captured in docs commit for SUMMARY/STATE updates)_

## Files Created/Modified
- `scripts/rec/0_prep.sh` - Receptor system preparation and equilibration Slurm submission pipeline.
- `scripts/rec/1_pr_rec.sh` - Parallel receptor production MD submission via Slurm array.
- `scripts/rec/3_ana.sh` - Trajectory centering/fitting and RMSD/RMSF analysis aggregation.
- `scripts/rec/4_cluster.sh` - GROMOS clustering and ensemble structure extraction (`rec0..recN`).
- `scripts/rec/5_align.py` - MDAnalysis alignment utility with CLI/library entrypoint and config integration.

## Decisions Made
- Standardized receptor stage scripts to use `init_script` and shared helpers (`run_gmx`, `submit_job`) for consistent execution and logging behavior.
- Used Slurm job arrays in production receptor MD submission so parallel trials are configurable and scalable from INI.
- Kept alignment as a Python utility to preserve reusable library mode while remaining callable as a numbered pipeline step.

## Deviations from Plan

None - plan executed exactly as written.

## Authentication Gates

None.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Receptor ensemble stage is ready for downstream docking and dock-to-complex steps.
- No blockers identified from this plan.

---
*Phase: 02-core-pipeline*
*Completed: 2026-04-18*
