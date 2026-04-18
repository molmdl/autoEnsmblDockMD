# Phase 2: Core Pipeline - Context

**Gathered:** 2026-04-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver generalized core pipeline scripts for receptor preparation, docking, MD, MMPBSA, and analysis, plus wrapper scripts and gap-filling scripts. Ligand preparation remains deferred to v2 and is not part of this phase.

</domain>

<decisions>
## Implementation Decisions

### Script interface
- Use a config-led workflow that stays easy for both humans and agents to run.
- Keep script behavior predictable across fresh sessions by making run inputs easy to inspect later.
- Keep validation strict enough to fail clearly on missing or inconsistent inputs.

### Config and CLI
- Keep defaults and help behavior consistent across all stage scripts.
- Standardize script interfaces so the same execution pattern works across receptor prep, docking, MD, MMPBSA, and analysis.
- Favor human-friendly invocation while still exposing enough controls for agent-driven runs.

### Wrapper behavior
- Optimize the wrapper for both human and agent workflows, not one at the expense of the other.
- Preserve run state between stages so execution can be resumed and reviewed in a fresh session.
- Place checkpoints at natural workflow boundaries where human review is useful.

### Error and resume behavior
- Preserve intermediate state so a failed run can be resumed cleanly.
- Fail clearly on broken inputs or stage failures rather than silently continuing.
- Keep partial outputs available unless they are invalid or corrupt.

### Script organization
- Follow the existing script layout pattern from `scripts/CONTEXT.md`: numeric prefixes for order, with `rec/`, `dock/`, `com/`, and `infra/` separation.
- Reuse the implemented blind-docking scripts as the baseline for generalized workflow behavior.
- Treat Mode A and Mode B as related script families that should share conventions where possible.

### OpenCode's Discretion
- Exact config syntax and file naming details.
- Exact wrapper control flow and checkpoint placement within a stage.
- Exact retry policy for transient external-command failures.

</decisions>

<specifics>
## Specific Ideas

- Numeric prefix naming for execution order.
- `rec/`, `dock/`, `com/`, and `infra/` directory split.
- Existing blind-docking scripts are the baseline pattern to generalize from.
- Keep the workflow friendly for a fresh session that needs to inspect prior run choices.

</specifics>

<deferred>
## Deferred Ideas

- Ligand preparation scripts and related chemistry-specific handling are deferred to v2.
- Any new capabilities beyond the core pipeline script family belong to later phases.

</deferred>

---

*Phase: 02-core-pipeline*
*Context gathered: 2026-04-18*
