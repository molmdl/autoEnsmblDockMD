---
phase: 02-core-pipeline
plan: 10
subsystem: analysis
tags: [mdanalysis, bash, python, fingerprint, archive, rerun, slurm]

# Dependency graph
requires:
  - phase: 02-01
    provides: Shared config-loading and logging utilities via scripts/infra/common.sh
  - phase: 02-08
    provides: MM/PBSA chunk directories and submission patterns consumed by utility scripts
  - phase: 02-09
    provides: Complex trajectory analysis outputs that feed fingerprint post-analysis
provides:
  - Reusable fingerprint analysis utility with CSV matrix and similarity heatmap outputs
  - Config-driven fingerprint batch wrapper across ligand directories with summary reporting
  - Archive selection utility for packaging key ligand outputs
  - Rerun selection utility for detecting incomplete stages and resubmitting jobs
affects: [02-11, phase-3-agent-infrastructure, operational-qc]

# Tech tracking
tech-stack:
  added: []
  patterns: [config-driven-post-analysis-utilities, stage-aware-rerun-detection, audit-logged-result-management]

key-files:
  created:
    - scripts/com/4_fp.py
    - scripts/com/4_cal_fp.sh
    - scripts/com/5_arc_sel.sh
    - scripts/com/5_rerun_sel.sh
  modified: []

key-decisions:
  - "Implement fingerprinting with MDAnalysis contact logic to preserve existing trajectory tooling and avoid introducing new hard dependencies."
  - "Use stage-specific expected-output patterns in rerun detection so incomplete prep/prod/mmpbsa jobs can be selected consistently from configuration."

patterns-established:
  - "Pattern: utility wrappers expose --config/--help and source common.sh for consistent script ergonomics."
  - "Pattern: post-analysis scripts emit explicit audit logs for each ligand action (processed, skipped, submitted, archived)."

# Metrics
duration: 4 min
completed: 2026-04-18
---

# Phase 2 Plan 10: Supporting utilities: fingerprints, archive, rerun Summary

**Post-analysis utility coverage now includes configurable fingerprint generation, result archiving, and incomplete-stage rerun submission for complex MD workflows.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-18T13:16:57Z
- **Completed:** 2026-04-18T13:21:35Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added `scripts/com/4_fp.py` as a reusable fingerprint analysis CLI/library utility producing frame-residue contact matrices and frame-similarity heatmaps.
- Added `scripts/com/4_cal_fp.sh` to execute fingerprint analysis across ligands and aggregate per-ligand output paths into a summary CSV.
- Added `scripts/com/5_arc_sel.sh` to archive selected outputs using config-driven file patterns with clear audit logs.
- Added `scripts/com/5_rerun_sel.sh` to detect missing stage outputs and resubmit prep/prod/MM-PBSA jobs through Slurm.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create fingerprint analysis scripts** - `3f3d959` (feat)
2. **Task 2: Create archive and rerun scripts** - `8a7517d` (feat), `db28b85` (fix)

**Plan metadata:** _(pending in next commit)_

## Files Created/Modified
- `scripts/com/4_fp.py` - MDAnalysis-based fingerprint engine with CSV matrix and Dice similarity heatmap output.
- `scripts/com/4_cal_fp.sh` - Multi-ligand wrapper that calls `4_fp.py` and writes a run summary table.
- `scripts/com/5_arc_sel.sh` - Archive selection workflow for packaging result subsets into tarballs.
- `scripts/com/5_rerun_sel.sh` - Stage-aware rerun selector that checks expected outputs and submits recovery jobs.

## Decisions Made
- Kept fingerprint implementation in MDAnalysis rather than adding external fingerprint libraries so deployment remains aligned with existing project environment.
- Made rerun detection stage-configurable (`prep|prod|mmpbsa`) with per-stage expected patterns to support both targeted retries and auditable recovery behavior.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Marked archive/rerun wrappers executable**
- **Found during:** Post-Task 2 verification and staging
- **Issue:** `5_arc_sel.sh` and `5_rerun_sel.sh` were created without execute permission, blocking direct CLI usage.
- **Fix:** Applied executable mode bits to both wrapper scripts.
- **Files modified:** `scripts/com/5_arc_sel.sh`, `scripts/com/5_rerun_sel.sh`
- **Verification:** `--help` invocations succeed and scripts are executable.
- **Committed in:** `db28b85` (follow-up task fix)

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** Permission fix was required for expected runnable wrapper behavior; no scope expansion.

## Authentication Gates

None.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Plan 02-10 deliverables are complete and verified (`--help` support and syntax checks passed for all four scripts).
- Utility-layer gaps for fingerprints/archive/rerun are now filled, leaving pipeline wrapper and validation as the remaining Phase 2 work.
- Ready for `02-11-PLAN.md`.

---
*Phase: 02-core-pipeline*
*Completed: 2026-04-18*
