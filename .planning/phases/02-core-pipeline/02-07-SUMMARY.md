---
phase: 02-core-pipeline
plan: 07
subsystem: md
tags: [gromacs, amber, charmm, topology, slurm, bash, python]

# Dependency graph
requires:
  - phase: 02-01
    provides: Shared bash config/loading/logging helpers via scripts/infra/common.sh
provides:
  - Unified complex preparation script for AMBER and CHARMM modes
  - Generalized AMBER angle-type bypass utility with CLI, config mode, and library function
  - Config-driven multi-ligand complex preparation with Slurm submission
affects: [02-08, 02-09, 02-10, 02-11]

# Tech tracking
tech-stack:
  added: []
  patterns: [config-driven-complex-prep, amber-angle-bypass-compatibility, multi-ligand-slurm-submission]

key-files:
  created:
    - scripts/com/0_prep.sh
    - scripts/com/bypass_angle_type3.py
  modified: []

key-decisions:
  - "Use one 0_prep.sh entrypoint with [complex] mode=amber|charmm to avoid script drift between force fields."
  - "Preserve angle type 3->1 conversion logic exactly, then generalize only interface/validation around it."

patterns-established:
  - "Pattern: Resolve ligand targets from explicit list, CLI override, or directory discovery."
  - "Pattern: Prepare per-ligand Slurm job scripts from a shared config-driven command template."

# Metrics
duration: 2 min
completed: 2026-04-18
---

# Phase 2 Plan 7: Complex MD preparation scripts Summary

**Unified AMBER/CHARMM complex preparation now assembles receptor-ligand systems and submits solvation, ionization, minimization, and restrained equilibration jobs while automatically handling AMBER angle type compatibility for gmx_MMPBSA.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-18T12:59:45Z
- **Completed:** 2026-04-18T13:02:38Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Added `scripts/com/0_prep.sh` as a single config-driven complex preparation entrypoint for both AMBER and CHARMM workflows.
- Added complex assembly and topology generation logic, including AMBER-specific `bypass_angle_type3.py` invocation before MD preparation.
- Generalized `scripts/com/bypass_angle_type3.py` with argparse/config support, validation, dry-run mode, optional topology include rewriting, and reusable library function.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create unified complex prep script** - `d6e00ba` (feat)
2. **Task 2: Generalize bypass_angle_type3.py** - `db52d20` (feat)

**Plan metadata:** _(pending in next commit)_

## Files Created/Modified
- `scripts/com/0_prep.sh` - Unified complex preparation driver with multi-ligand support and Slurm submission.
- `scripts/com/bypass_angle_type3.py` - AMBER angle-type compatibility utility with generalized CLI/config/library interfaces.

## Decisions Made
- Use `scripts/infra/common.sh` as the shared runtime dependency so new complex scripts inherit consistent config, logging, and command behavior.
- Keep the core angle conversion implementation unchanged and only add safe wrappers (argparse, config, validation, dry-run, optional topology update).
- Build per-ligand preparation artifacts in `com/<ligand>/` to preserve reproducibility and simplify downstream production/MMPBSA stages.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Created missing `scripts/com/` target location**
- **Found during:** Task 1 (Create unified complex prep script)
- **Issue:** Planned output paths under `scripts/com/` did not exist in the repository, which blocked creating required plan artifacts.
- **Fix:** Created `scripts/com/` with the planned script files and wired imports to existing shared infrastructure.
- **Files modified:** `scripts/com/0_prep.sh`, `scripts/com/bypass_angle_type3.py`
- **Verification:** `bash -n scripts/com/0_prep.sh` and `python -m py_compile scripts/com/bypass_angle_type3.py` both pass.
- **Committed in:** `d6e00ba`, `db52d20`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Deviation was required to create the planned deliverables; no scope creep.

## Authentication Gates

None.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Core complex preparation and AMBER topology compatibility path are now in place.
- Ready to continue remaining Phase 2 plans (02-05/02-06/02-08 onward).
- No blockers identified from this plan.

---
*Phase: 02-core-pipeline*
*Completed: 2026-04-18*
