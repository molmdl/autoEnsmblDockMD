# Phase 3: Agent Infrastructure - Context

**Gathered:** 2026-04-19
**Status:** Ready for planning

## Phase Boundary

Implement five agent types for the workflow: orchestrator, runner, analyzer, checker, and debugger. This phase defines file-based state passing and agent responsibilities for coordinating the existing pipeline scripts; it does not add new workflow capabilities.

## Implementation Decisions

### Role boundaries
- Orchestrator manages workflow state, agent routing, checkpoints, and human verification gates.
- Orchestrator should support both normal user-check mode and more automatic modes, but human checkpoints remain part of the workflow.
- Runner executes stage scripts and shapes outputs into structured handoff records for downstream agents.
- Analyzer runs the standard workflow-defined analysis set and may also support custom analysis hooks described in the workflow and AGENTS guidance.
- Checker is the general validation layer for plans, results, and stage outputs; it should balance human understanding with agent-friendly structure.
- Debugger is focused on issues, errors, and bugs in current or custom code paths, not general validation.

### State handoff
- Agents should persist enough state to avoid missing work across session boundaries.
- Checkpoints are written at every stage transition.
- State should stay usable by both humans and agents, with a balance of structured fields and readable notes.
- The exact persistence shape is left flexible so research/planning can choose the best mix of JSON, markdown, or YAML for each handoff.

### Result reporting
- Agent summaries should follow the GSD workflow style: concise but structured enough to support downstream orchestration.
- Reports should include the current status, key findings, warnings if any, and the next recommended action.
- Warnings should be actionable and include enough reason/context to explain why they matter.
- Success and failure should be explicit, with supporting evidence and short interpretation when it changes the workflow decision.
- Structured outputs may use whichever format best fits the consumer, with no single forced format at this phase.

### Debug escalation
- Debugger is triggered by user request by default.
- Outside explicit user triggers, checker can escalate issues when validation shows a real problem or repeated risk.
- Checker stays the broader quality gate; debugger is the specialized investigation path for bugs, failures, and code defects.
- Human involvement is required when a checkpoint fails, when a workflow block cannot be resolved automatically, or when a result is ambiguous enough to affect the next decision.
- Debugger should keep a reproducibility-oriented record of tool versions, environment details, command context, and output locations.

### OpenCode's Discretion
- Exact file schemas for agent state and handoff records.
- Whether to prefer JSON, markdown, YAML, or a hybrid per file type.
- The exact threshold logic used by checker warnings and failures.
- The exact auto-mode variants beyond the required human-check mode.

## Specific Ideas

- Follow the GSD workflow patterns already established in the project.
- Keep agent support aligned with `AGENTS.md` requirements.
- Preserve human-run validation as the primary workflow shape.

## Deferred Ideas

- Any broader automation beyond the current Phase 3 agent infrastructure belongs in later integration phases.

---

*Phase: 03-agent-infrastructure*
*Context gathered: 2026-04-19*
