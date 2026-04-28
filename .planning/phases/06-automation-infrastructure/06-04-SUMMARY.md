---
phase: 06-automation-infrastructure
plan: 04
subsystem: infra
tags: [mmpbsa, group-id, cache, plugin, wrapper]

# Dependency graph
requires:
  - phase: 06-automation-infrastructure
    provides: Plugin scaffolding and handoff-driven wrapper pattern from 06-01
provides:
  - Group ID consistency checker plugin for index.ndx and mmpbsa_groups.dat
  - Per-workspace conversion cache with staleness detection
  - Wrapper command to run group-id validation and persist handoff JSON
affects: [06-05-typescript-plugins, 06-07-dry-run-audit, complex-mmpbsa]

# Tech tracking
tech-stack:
  added: []
  patterns: [Index-aware MM/PBSA validation gate, per-workspace cache isolation]

key-files:
  created:
    - scripts/infra/plugins/group_id_check.py
    - scripts/infra/plugins/conversion_cache.py
    - scripts/commands/aedmd-group-id-check.sh
  modified:
    - scripts/commands/aedmd-group-id-check.sh

key-decisions:
  - "Use header-order group indexing from index.ndx as canonical group-ID source"
  - "Keep conversion cache local to workspace/.cache with mtime-based stale invalidation"

patterns-established:
  - "Pattern 1: Group-ID validation emits HandoffRecord status (success/needs_review/failure) for wrapper compatibility"
  - "Pattern 2: Conversion cache uses deterministic sha256(source_path:target_format) keys and sidecar metadata"

# Metrics
duration: 5 min
completed: 2026-04-28
---

# Phase 6 Plan 04: Group ID checker and conversion cache Summary

**MM/PBSA support automation now includes index-aware group-ID validation and deterministic per-workspace conversion caching to prevent silent wrong-group calculations and redundant file transforms.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-28T14:18:30Z
- **Completed:** 2026-04-28T14:24:24Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Implemented `group_id_check.py` with `validate_group_ids(workspace)` to validate `mmpbsa_groups.dat` against `index.ndx` and emit structured handoff JSON.
- Implemented `ConversionCache` in `conversion_cache.py` with deterministic keying, get/put cache operations, and stale detection from source mtime.
- Added `aedmd-group-id-check.sh` wrapper to run the plugin, persist `.handoffs/group_id_check.json`, and enforce status handling via `check_handoff_result`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement group ID consistency checker** - `8d0193e` (feat)
2. **Task 2: Implement conversion cache manager** - `18de94d` (feat)
3. **Task 3: Create group-id-check wrapper command** - `3ce21b3` (feat)

Additional auto-fix commit:
- **Wrapper executable permission fix** - `fe72d93` (fix)

**Plan metadata:** _(pending metadata commit)_

## Files Created/Modified
- `scripts/infra/plugins/group_id_check.py` - Parses `index.ndx`, validates/suggests receptor and ligand group IDs, and returns HandoffRecord statuses.
- `scripts/infra/plugins/conversion_cache.py` - Provides reusable per-workspace conversion cache with metadata-backed freshness checks.
- `scripts/commands/aedmd-group-id-check.sh` - Command wrapper with `--workspace` support and handoff persistence in `.handoffs/`.

## Decisions Made
- Treat `index.ndx` as the authoritative source of group IDs and map IDs by group-header order for deterministic MM/PBSA validation.
- Keep cache storage isolated at `workspace/.cache/<type>/` to avoid cross-workspace contamination and preserve reproducibility.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed wrapper execution mode to match command conventions**
- **Found during:** Task 3 (Create group-id-check wrapper command)
- **Issue:** Newly created wrapper had non-executable mode (`100644`), which can break direct command invocation.
- **Fix:** Set executable mode (`100755`) to align with existing `scripts/commands/aedmd-*.sh` wrappers.
- **Files modified:** `scripts/commands/aedmd-group-id-check.sh`
- **Verification:** `ls -l` confirms executable bit; `bash -n` passes.
- **Committed in:** `fe72d93`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Reliability hardening only; no scope expansion.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Authentication Gates
None.

## Next Phase Readiness
- Plan objective complete; group-ID checker and conversion cache are ready for downstream integration work.
- No blockers carried forward from this plan.

---
*Phase: 06-automation-infrastructure*
*Completed: 2026-04-28*
