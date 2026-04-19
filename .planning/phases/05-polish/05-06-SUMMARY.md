---
phase: 05-polish
plan: 06
subsystem: docs
tags: [guide, troubleshooting, force-field, stage-instructions, workflow-crossref]

# Dependency graph
requires:
  - phase: 05-polish
    provides: "GUIDE Part 1 baseline config/input/workspace reference from 05-05"
  - phase: 05-polish
    provides: "Canonical stage/script mapping in WORKFLOW.md from 05-01"
provides:
  - "docs/GUIDE.md Part 2 with stage-by-stage operating instructions for Stage 0-6"
  - "Output interpretation quick guide for docking/MD/MM-PBSA/analysis triage"
  - "Troubleshooting matrix and force-field compatibility quick reference"
affects: [phase-05-polish, operator-docs, onboarding, run-validation]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Guide-first stage verification format: what to run, what to check, expected outputs, common issues"]

key-files:
  created: [.planning/phases/05-polish/05-06-SUMMARY.md]
  modified: [docs/GUIDE.md]

key-decisions:
  - "Keep script-level details in WORKFLOW.md and use GUIDE.md for operator verification/interpretation guidance"
  - "Promote Troubleshooting and Force Field Compatibility to top-level sections for fast lookup"

patterns-established:
  - "Each computational stage section uses a consistent checklist block (purpose, commands, checks, outputs, common issues)"
  - "Part 2 guidance explicitly cross-references WORKFLOW.md instead of duplicating script inventory"

# Metrics
duration: 3 min
completed: 2026-04-19
---

# Phase 5 Plan 06: GUIDE Part 2 stage operations and troubleshooting summary

**Completed GUIDE Part 2 with actionable Stage 0-6 operating checklists, output interpretation guidance, and failure-recovery references for force-field and runtime issues.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-19T02:43:28Z
- **Completed:** 2026-04-19T02:46:36Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Replaced the Part 2 placeholder with stage-by-stage instructions covering Stage 0 through Stage 6 and computational stages 1-6 in detail.
- Added an output interpretation quick guide to help users evaluate cluster quality, docking plausibility, MD stability, MM/PBSA consistency, and interaction persistence.
- Added top-level troubleshooting and force-field compatibility sections with concrete diagnostics and corrective actions.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add per-stage instructions** - `a97a286` (docs)
2. **Task 2: Add troubleshooting and force field guide** - `bb68c8c` (docs)

## Files Created/Modified
- `docs/GUIDE.md` - Added Part 2 operational guidance, stage verification checklists, output interpretation matrix, troubleshooting table, and force-field compatibility reference.
- `.planning/phases/05-polish/05-06-SUMMARY.md` - Execution summary for plan 05-06.

## Decisions Made
- Kept script-path and execution-order authority in `WORKFLOW.md`, while using `docs/GUIDE.md` for user-facing operating checks and interpretation guidance.
- Elevated Troubleshooting and Force Field Compatibility to top-level sections (with TOC links) so operators can quickly locate failure recovery rules.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- GUIDE.md now provides full stage guidance plus failure handling support for operational use.
- Ready for `05-07-PLAN.md` (phase-close validation and end-to-end artifact readiness).
- Existing Phase 5 blocker remains: collect end-to-end validation artifacts.

---
*Phase: 05-polish*
*Completed: 2026-04-19*
