---
phase: 02-core-pipeline
plan: 08
subsystem: md
tags: [gromacs, gmx_mmpbsa, slurm, bash, md]

# Dependency graph
requires:
  - phase: 02-01
    provides: Shared config/common shell runtime for script orchestration
  - phase: 02-07
    provides: Prepared complex systems and force-field-aware topology setup
provides:
  - Unified production MD submission script with equilibration→production dependencies
  - Unified MM/PBSA trajectory preparation and chunked workdir generation
  - Slurm array-based MM/PBSA submission and single-chunk execution wrappers
affects: [02-10, 02-11, validation, downstream-analysis]

# Tech tracking
tech-stack:
  added: []
  patterns: [config-driven-md-production, mmpbsa-chunk-array-submission, robust-index-group-selection]

key-files:
  created:
    - scripts/com/1_pr_prod.sh
    - scripts/com/2_trj4mmpbsa.sh
    - scripts/com/2_run_mmpbsa.sh
    - scripts/com/2_mmpbsa.sh
    - scripts/com/2_sub_mmpbsa.sh
  modified:
    - scripts/com/2_trj4mmpbsa.sh

key-decisions:
  - "Use a unified 1_pr_prod.sh that submits equilibration and production as separate jobs connected with Slurm afterok dependencies."
  - "Run MM/PBSA as per-ligand Slurm job arrays (one array task per chunk) to preserve parallel throughput and reproducibility."
  - "Resolve complex group IDs dynamically from generated index files instead of hardcoding make_ndx group numbers."

patterns-established:
  - "Pattern: production-stage scripts accept --ligand override while defaulting to config-driven multi-ligand discovery."
  - "Pattern: run_mmpbsa orchestrator always calls trajectory preprocessing before submission wrapper."

# Metrics
duration: 5 min
completed: 2026-04-18
---

# Phase 2 Plan 8: Production MD and MM/PBSA pipeline scripts Summary

**Production MD and MM/PBSA are now unified into config-driven scripts that submit equilibration/production chains and parallel chunked gmx_MMPBSA arrays for AMBER and CHARMM workflows.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-18T13:08:19Z
- **Completed:** 2026-04-18T13:14:04Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Added `scripts/com/1_pr_prod.sh` to unify production MD submission with multi-ligand support, configurable equilibration staging, and Slurm dependency chaining.
- Added MM/PBSA pipeline scripts (`2_trj4mmpbsa.sh`, `2_mmpbsa.sh`, `2_sub_mmpbsa.sh`, `2_run_mmpbsa.sh`) for trajectory preprocessing, single-chunk execution, array submission, and end-to-end orchestration.
- Implemented topology-path flexibility and mode compatibility so MM/PBSA workers can run with AMBER (`bypass_sys.top`) or CHARMM (`sys.top`) inputs.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create production MD script** - `a9c015f` (feat)
2. **Task 2: Create MM/PBSA pipeline scripts** - `42d8228` (feat)
3. **Deviation fix (Task 2 follow-up):** `adc0ddf` (fix)

**Plan metadata:** _(pending in next commit)_

## Files Created/Modified
- `scripts/com/1_pr_prod.sh` - Unified production MD submitter with equilibration chain and production dependency jobs.
- `scripts/com/2_trj4mmpbsa.sh` - MM/PBSA trajectory/index preparation with chunked complex-only trajectory generation.
- `scripts/com/2_mmpbsa.sh` - Single-chunk MM/PBSA execution wrapper around `gmx_MMPBSA`.
- `scripts/com/2_sub_mmpbsa.sh` - Slurm job-array submitter for MM/PBSA chunks.
- `scripts/com/2_run_mmpbsa.sh` - Unified orchestrator running trajectory preprocessing before array submission.

## Decisions Made
- Keep one production entrypoint (`1_pr_prod.sh`) for both modes and drive behavior through config sections to avoid script drift.
- Use Slurm array submission for MM/PBSA chunk parallelism rather than serial per-chunk submission loops.
- Prefer dynamic index group resolution from generated `.ndx` files to avoid fragile assumptions about GROMACS group numbering.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed hardcoded complex group index in trajectory extraction**
- **Found during:** Task 2 (MM/PBSA trajectory processing implementation)
- **Issue:** Initial implementation assumed the new complex group was always group `24`, which is not guaranteed across systems and could break `trjconv` selection.
- **Fix:** Updated `2_trj4mmpbsa.sh` to parse generated index files, detect total group count, and use the actual last-group ID dynamically.
- **Files modified:** `scripts/com/2_trj4mmpbsa.sh`
- **Verification:** `bash -n scripts/com/2_trj4mmpbsa.sh` and `--help` checks pass; script now uses numeric dynamic group IDs.
- **Committed in:** `adc0ddf`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Fix was required for correct MM/PBSA trajectory extraction robustness; no scope creep.

## Authentication Gates

None.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Production MD and MM/PBSA execution path is now scripted end-to-end for submission/orchestration.
- Ready for downstream validation and integration in remaining Phase 2 plans.
- No blockers identified.

---
*Phase: 02-core-pipeline*
*Completed: 2026-04-18*
