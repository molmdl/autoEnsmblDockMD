---
phase: 02-core-pipeline
plan: 05
subsystem: docking
tags: [bash, python, sdf, gro, itp, topology, restraints]

# Dependency graph
requires:
  - phase: 02-core-pipeline
    provides: bash config/common utilities and script conventions from 02-01
  - phase: 02-core-pipeline
    provides: ligand conversion baseline utilities from 02-03
  - phase: 02-core-pipeline
    provides: unified docking execution outputs from 02-04
provides:
  - docking score report generation and ranking across receptor-ligand poses
  - selected-pose SDF to GRO conversion utility for dock-to-complex handoff
  - topology parsing, complex topology assembly, and ligand posre generation utilities
affects: [02-06, 02-07, 02-08, 02-11]

# Tech tracking
tech-stack:
  added: []
  patterns: [config-driven-post-docking-tools, cli-plus-library-python-utilities, modular-itp-parser-reuse]

key-files:
  created:
    - scripts/dock/3_dock_report.sh
    - scripts/dock/4_dock2com_1.py
    - scripts/dock/4_dock2com_2.py
    - scripts/dock/4_dock2com_2.1.py
    - scripts/dock/4_dock2com_2.2.1.py
    - scripts/dock/dock2com_2_1.py
  modified: []

key-decisions:
  - "Implemented post-docking score extraction as a config-driven shell wrapper with embedded Python ranking logic to keep shell interface consistency while handling SDF parsing robustly."
  - "Added a dedicated wrapper module (`dock2com_2_1.py`) to bridge Python import limitations for dotted numeric filenames while preserving expected workflow script naming."

patterns-established:
  - "Pattern: post-docking scripts expose --config and standalone CLI flags while remaining reusable from Python library calls."
  - "Pattern: topology assembly utilities validate required ITP sections before generating output topologies."

# Metrics
duration: 5 min
completed: 2026-04-18
---

# Phase 2 Plan 5: Post-docking scoring and dock2com Python core Summary

**Post-docking processing now covers ranked score reporting, selected-pose SDF→GRO conversion, and modular topology/posre generation for MD-ready complex preparation.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-18T12:59:21Z
- **Completed:** 2026-04-18T13:04:50Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Added `scripts/dock/3_dock_report.sh` to generate ranked docking reports from gnina SDF outputs with CSV/text output control and top-N filtering.
- Added `scripts/dock/4_dock2com_1.py` to convert a selected pose from multi-pose SDF into GRO with coordinate-preserving conversion pathways (RDKit preferred, obabel fallback).
- Added `scripts/dock/4_dock2com_2.py`, `4_dock2com_2.1.py`, and `4_dock2com_2.2.1.py` to provide ITP parsing, complex topology assembly (AMBER/CHARMM flag support), and heavy-atom ligand position restraint generation.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create dock report and SDF conversion** - `43e31f8` (feat)
2. **Task 2: Create topology extraction Python utilities** - `74c71ef` (feat)

**Plan metadata:** _(pending in next commit)_

## Files Created/Modified
- `scripts/dock/3_dock_report.sh` - Common.sh-based CLI wrapper for cross-file SDF score extraction and ranked report generation.
- `scripts/dock/4_dock2com_1.py` - Pose-indexed SDF→GRO converter with CLI/config input handling and library function export.
- `scripts/dock/4_dock2com_2.py` - Complex topology builder that imports shared ITP parsing utilities and emits MD-ready topologies.
- `scripts/dock/4_dock2com_2.1.py` - Reusable ITP parser utility with section extraction and JSON/text output modes.
- `scripts/dock/4_dock2com_2.2.1.py` - Ligand heavy-atom position restraint generator from GRO files.
- `scripts/dock/dock2com_2_1.py` - Import wrapper enabling stable module linkage from `4_dock2com_2.py`.

## Decisions Made
- Kept the post-docking report script in bash entrypoint form to stay consistent with existing dock-stage wrappers, while delegating scoring table generation to embedded Python for robust structured parsing.
- Used a wrapper module to satisfy the planned import link between `4_dock2com_2.py` and `4_dock2com_2.1.py` without renaming numeric workflow scripts.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed direct CLI import path failure for `4_dock2com_2.py`**
- **Found during:** Task 2 (CLI help verification)
- **Issue:** Running `python scripts/dock/4_dock2com_2.py --help` failed with `ModuleNotFoundError: No module named 'scripts'`.
- **Fix:** Added guarded import fallback using local dynamic module loading for `dock2com_2_1.py` when package-style import is unavailable.
- **Files modified:** scripts/dock/4_dock2com_2.py
- **Verification:** `python scripts/dock/4_dock2com_2.py --help` succeeds and py_compile checks pass for all three task-2 scripts.
- **Committed in:** 74c71ef (task commit)

**2. [Rule 3 - Blocking] Added wrapper import module for dotted numeric script interoperability**
- **Found during:** Task 2 (implementing planned shared-module link)
- **Issue:** Python cannot import `4_dock2com_2.1.py` directly as a standard module because of the dotted numeric filename.
- **Fix:** Added `scripts/dock/dock2com_2_1.py` wrapper to expose parser APIs and preserve planned script filenames.
- **Files modified:** scripts/dock/dock2com_2_1.py, scripts/dock/4_dock2com_2.py
- **Verification:** `4_dock2com_2.py` imports parser utilities successfully and all verification checks pass.
- **Committed in:** 74c71ef (task commit)

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking)
**Impact on plan:** Both fixes were required to satisfy planned module linkage and runnable CLI behavior without architectural scope changes.

## Authentication Gates

None.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Post-docking score summarization and dock-to-complex Python utilities are now available and verified.
- Ready for downstream shell wrapper integration and complex MD handoff stages.

---
*Phase: 02-core-pipeline*
*Completed: 2026-04-18*
