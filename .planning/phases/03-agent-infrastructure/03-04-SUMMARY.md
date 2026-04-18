---
phase: 03-agent-infrastructure
plan: 04
subsystem: infra
tags: [agents, registry, cli, argparse, handoff, integration]

# Dependency graph
requires:
  - phase: 03-02
    provides: Orchestrator/Runner concrete roles for registry and invocation
  - phase: 03-03
    provides: Analyzer/Checker/Debugger concrete roles for registry and invocation
provides:
  - Public scripts.agents API exports for all five agent roles plus shared schemas
  - AGENT_REGISTRY role map and get_agent factory for runtime role resolution
  - `python -m scripts.agents` CLI entrypoint with JSON handoff input/output
affects: [phase-4-integration]

# Tech tracking
tech-stack:
  added: []
  patterns: [package-level-agent-registry, role-factory-instantiation, json-handoff-cli-entrypoint]

key-files:
  created:
    - scripts/agents/__main__.py
  modified:
    - scripts/agents/__init__.py

key-decisions:
  - "Expose AGENT_REGISTRY and get_agent from scripts.agents so orchestrators and CLI use one authoritative role-to-class map."
  - "CLI loads optional INI config through ConfigManager and accepts JSON handoff input/output for tool-friendly chaining."

patterns-established:
  - "Pattern: role strings are normalized and resolved through AGENT_REGISTRY rather than ad-hoc imports."
  - "Pattern: agent CLI returns structured JSON to stdout/file with non-zero exit codes on invalid input/runtime failure."

# Metrics
duration: 1 min
completed: 2026-04-19
---

# Phase 3 Plan 4: Agent registry and CLI integration summary

**Delivered a unified `scripts.agents` public API with role registry/factory and a module CLI that invokes any agent with JSON handoff I/O.**

## Performance

- **Duration:** 1 min
- **Started:** 2026-04-18T17:39:09Z
- **Completed:** 2026-04-18T17:40:45Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Added full package exports in `scripts/agents/__init__.py` for BaseAgent, all five concrete agents, and shared handoff/workflow schemas.
- Added `AGENT_REGISTRY` plus `get_agent()` factory to map role strings to concrete classes with normalized lookup.
- Implemented `scripts/agents/__main__.py` argparse CLI supporting `--agent`, `--workspace`, `--config`, `--input`, and `--output`.
- Verified integration flow across orchestrator → runner → checker plus analyzer/debugger instantiation and CLI invocation.

## Task Commits

Each task was committed atomically:

1. **Task 1: Agent registry and CLI entrypoint** - `9dc4eef` (feat)
2. **Task 2: Integration smoke test and fixups** - `11e44e9` (fix)

**Plan metadata:** _(pending metadata commit)_

## Files Created/Modified
- `scripts/agents/__init__.py` - Public exports, AGENT_REGISTRY mapping, get_agent factory, and package `__all__`.
- `scripts/agents/__main__.py` - argparse-based CLI that loads config/input, executes selected agent, and writes JSON output.

## Decisions Made
- Centralized role routing in `AGENT_REGISTRY` and reused it in both imports and CLI choices to eliminate mapping drift.
- Kept CLI handoff format JSON-only for deterministic automation and shell-friendly interoperability.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added explicit get_agent input validation for role type/emptiness**
- **Found during:** Task 2 (Integration smoke test)
- **Issue:** Factory accepted any role value shape until registry lookup; invalid/non-string input paths could fail opaquely.
- **Fix:** Added explicit type check (`str`) and non-empty role validation before AGENT_REGISTRY lookup.
- **Files modified:** `scripts/agents/__init__.py`
- **Verification:** Smoke tests and CLI checks pass; invalid role inputs now fail with clear errors.
- **Committed in:** `11e44e9` (part of Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** Validation hardening improved reliability without changing planned architecture or scope.

## Authentication Gates

None.

## Issues Encountered

- Initial smoke command used a non-existent enum member (`WorkflowStage.DOCKING`); corrected to `WorkflowStage.DOCK_RUN` and reran successfully.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 3 agent infrastructure is now complete, including package API and CLI entrypoint required for integration wiring.
- Agent invocation surface is stable for slash-command and skill integration in Phase 4.
- No blockers identified for progressing to Phase 4 integration plans.

---
*Phase: 03-agent-infrastructure*
*Completed: 2026-04-19*
