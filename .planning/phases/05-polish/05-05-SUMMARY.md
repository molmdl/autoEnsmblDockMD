---
phase: 05-polish
plan: 05
subsystem: docs
tags: [guide, config, workspace, input-prep, pipeline]

# Dependency graph
requires:
  - phase: 05-polish
    provides: "Canonical stage/script mapping from WORKFLOW.md (05-01) used for stage usage notes"
provides:
  - "docs/GUIDE.md Part 1 with full config.ini key reference"
  - "Input preparation guidance for receptor/ligands/FF/MDP assets"
  - "Workspace setup procedure with directory layout and preflight verification"
affects: [phase-05-polish, onboarding, operator-docs, guide-part2]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Table-driven config documentation with key type/default/stage mapping"]

key-files:
  created: [docs/GUIDE.md, .planning/phases/05-polish/05-05-SUMMARY.md]
  modified: [docs/GUIDE.md]

key-decisions:
  - "Documented every config.ini.template key directly from source template to avoid drift"
  - "Used [production] as the explicit MD section label while preserving plan intent for [md] coverage"

patterns-established:
  - "Part 1 guide sections: config reference -> input prep -> workspace setup"
  - "Each config key entry includes stage usage and mode notes when relevant"

# Metrics
duration: 2 min
completed: 2026-04-19
---

# Phase 5 Plan 05: GUIDE Part 1 summary

**Shipped a complete pre-run operator guide covering all runtime config keys, required input assets, and reproducible workspace setup steps.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-19T02:39:09Z
- **Completed:** 2026-04-19T02:41:30Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Created `docs/GUIDE.md` with a structured Part 1 table of contents and navigation for config/input/workspace topics.
- Documented all sections and keys from `scripts/config.ini.template`, including type, default, stage usage, and mode-specific notes.
- Added practical input preparation requirements and workspace bootstrapping commands, including the force-field compatibility pitfall warning.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create docs/ directory and GUIDE.md header + config reference** - `9a4adc6` (docs)
2. **Task 2: Add input preparation and workspace setup sections** - `87dd99f` (docs)

## Files Created/Modified
- `docs/GUIDE.md` - Human-facing Part 1 guide with complete config reference plus setup/preparation instructions.
- `.planning/phases/05-polish/05-05-SUMMARY.md` - Execution summary for plan 05-05.

## Decisions Made
- Kept configuration reference exhaustive by deriving entries directly from `scripts/config.ini.template` so GUIDE remains aligned with runtime keys.
- Represented MD controls under the actual `[production]` section name while calling it out as the MD section in GUIDE headings.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- GUIDE Part 1 prerequisites are complete and usable for human operators before stage execution.
- Ready for `05-06-PLAN.md` (GUIDE Part 2: per-stage instructions + troubleshooting).
- Remaining Phase 5 blocker remains end-to-end validation artifacts (`05-07`).

---
*Phase: 05-polish*
*Completed: 2026-04-19*
