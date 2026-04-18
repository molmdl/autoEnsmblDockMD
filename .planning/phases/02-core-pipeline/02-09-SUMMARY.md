---
phase: 02-core-pipeline
plan: 09
subsystem: analysis
tags: [gromacs, mdanalysis, matplotlib, bash, python, trajectory-analysis]

# Dependency graph
requires:
  - phase: 02-01
    provides: Shared config-loading and logging utilities via scripts/infra/common.sh
  - phase: 02-07
    provides: Complex preparation outputs and scripts/com stage structure
provides:
  - Unified trajectory analysis entrypoint combining GROMACS and MDAnalysis analysis
  - Advanced MDAnalysis analysis utility for RMSD, RMSF, contact frequency, and COM distance metrics
  - Reusable default selection definitions with topology detection and config overrides
affects: [02-10, 02-11, phase-3-agent-infrastructure]

# Tech tracking
tech-stack:
  added: []
  patterns: [config-driven-analysis-orchestration, dual-gromacs-mdanalysis-analysis, reusable-selection-library]

key-files:
  created:
    - scripts/com/3_ana.sh
    - scripts/com/3_com_ana_trj.py
    - scripts/com/3_selection_defaults.py
  modified: []

key-decisions:
  - "Use scripts/com/3_ana.sh as the single orchestrator for both baseline GROMACS tools and advanced MDAnalysis analytics."
  - "Load 3_selection_defaults.py dynamically from 3_com_ana_trj.py to preserve numeric workflow naming while keeping reusable library behavior."

patterns-established:
  - "Pattern: expose analysis toggles and GROMACS group IDs through [analysis] config keys instead of hardcoded selections."
  - "Pattern: pair each numerical output CSV with a publication-ready plot generated in the same analysis pass."

# Metrics
duration: 3 min
completed: 2026-04-18
---

# Phase 2 Plan 9: Complex MD trajectory analysis scripts Summary

**Complex trajectory analysis now runs from one command to generate RMSD/RMSF/H-bond outputs via GROMACS plus MDAnalysis-derived RMSD, per-residue RMSF, contact frequency, and distance plots with reusable selection defaults.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-18T13:07:09Z
- **Completed:** 2026-04-18T13:10:12Z
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments
- Added `scripts/com/3_ana.sh` to orchestrate standard trajectory analysis with config-driven toggles and ligand targeting.
- Added `scripts/com/3_com_ana_trj.py` to compute RMSD, per-residue RMSF, contact frequency, and COM distance metrics with CSV + plot outputs.
- Added `scripts/com/3_selection_defaults.py` to provide standard selection groups, topology-aware ligand detection, and config-based custom overrides.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create analysis shell script and Python utilities** - `4f025a1` (feat)

**Plan metadata:** _(pending in next commit)_

## Files Created/Modified
- `scripts/com/3_ana.sh` - Config-driven orchestration for GROMACS and MDAnalysis trajectory analysis.
- `scripts/com/3_com_ana_trj.py` - Advanced MDAnalysis CLI/library analysis utility with plotting and CSV export.
- `scripts/com/3_selection_defaults.py` - Reusable default selection registry with topology detection and config overrides.

## Decisions Made
- Kept GROMACS and MDAnalysis responsibilities complementary: GROMACS for baseline RMSD/RMSF/H-bond outputs, MDAnalysis for richer residue/contact/distance metrics and publication plots.
- Implemented selection extension through `[analysis]` config keys (`selection.*` and `custom_selections`) so custom groups can be injected without code edits.

## Deviations from Plan

None - plan executed exactly as written.

## Authentication Gates

None.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Complex analysis stage now has complete shell + Python components aligned with planned `scripts/com/3_*` naming.
- Outputs are structured for downstream wrapper integration and agent-driven execution.
- Remaining Phase 2 plans can proceed; no blockers introduced by this plan.

---
*Phase: 02-core-pipeline*
*Completed: 2026-04-18*
