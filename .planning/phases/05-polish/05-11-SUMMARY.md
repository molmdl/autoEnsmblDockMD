---
phase: 05-polish
plan: 11
subsystem: docs
tags: [agent-workflow, orchestration, handoff, state-machine, pipeline]

requires:
  - phase: 04-integration
    provides: skill files, command scripts, AGENTS.md baseline
  - phase: 05-polish
    provides: restored SKILL.md YAML frontmatter, structural validation report

provides:
  - Agent-loadable pipeline orchestration document at .opencode/docs/AGENT-WORKFLOW.md
  - Complete HandoffRecord JSON schema with types and examples
  - State machine for all 9 pipeline stages with transitions
  - Decision trees for normal flow, failure, checker-validate, and debugger-diagnose
  - Stage preconditions/postconditions with I/O glob patterns

affects: [orchestrator agents, runner agents, checker agents, debugger agents]

tech-stack:
  added: []
  patterns:
    - "Agent-loadable markdown with YAML-structured code blocks for schemas"
    - "HandoffRecord file-based state passing for pipeline resumability"

key-files:
  created:
    - .opencode/docs/AGENT-WORKFLOW.md
  modified: []

key-decisions:
  - "Single document covers full pipeline from input_prep through analysis"
  - "HandoffRecord schema includes status enum, inputs/outputs, next_action, and timestamp"
  - "Decision tree uses table format for quick agent parsing"
  - "Stage preconditions reference exact glob patterns and GROMACS version requirements"

patterns-established:
  - "Stage preconditions/postconditions use table format with Required inputs, Required env, Expected outputs, Validation checks"
  - "All cross-references use relative paths matching AGENTS.md conventions"

duration: 8min
completed: 2026-04-19
---

# Phase 5 Plan 11: Agent Workflow Document Summary

**Agent-loadable pipeline orchestration document with 9-stage state machine, HandoffRecord JSON schema, decision trees, and stage preconditions/postconditions enabling full docking→MD→MM/PBSA orchestration from a single file.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-19T08:21:02Z
- **Completed:** 2026-04-19T08:29:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Created `.opencode/docs/AGENT-WORKFLOW.md` (477 lines) satisfying DOC-02 requirement
- Defined complete HandoffRecord JSON schema with field types, constraints, and a worked docking→complex_setup example
- State machine covers all 9 stages with valid transitions and Mode A/B differences
- Decision trees cover normal progression, checker-validate gate, debugger-diagnose recovery, and workflow completion
- Stage preconditions/postconditions for all 9 stages with I/O globs and validation criteria
- 8-step orchestration protocol for orchestrator agents
- All 10 skill paths and 10 command script paths cross-referenced and verified to exist

## Task Commits

1. **Task 1: Create agent-facing workflow document** — `2c1e83f` (feat)

**Plan metadata:** (see below)

## Files Created/Modified

- `.opencode/docs/AGENT-WORKFLOW.md` — Agent-parseable pipeline orchestration reference; includes state machine, HandoffRecord schema, decision trees, stage pre/postconditions, orchestration protocol

## Decisions Made

- Single-document approach: full pipeline context loadable without cross-document traversal
- HandoffRecord `next_action` field encodes both stage advancement and special values (`human_review`, `debug`) to drive orchestrator branching
- `docs/` subdirectory used (not skill directory) since this is orchestration meta-doc, not a stage-specific skill
- Stage table includes "agent type" column to help orchestrators dispatch to correct agent role

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- DOC-02 requirement satisfied: `.opencode/docs/AGENT-WORKFLOW.md` exists and is structured for agent parsing
- 05-12-PLAN.md (E2E functional testing of slash commands + skills) is the remaining plan in Phase 5
- All cross-referenced files exist and were validated during execution

---
*Phase: 05-polish*
*Completed: 2026-04-19*
