# Skill: status
**Stage:** workspace_status
**Agent:** orchestrator

## Capability
Inspect workspace execution progress and summarize detected workflow mode, completed stages, pending stages, and latest handoff outcomes. Provide lightweight read-only situational awareness before orchestration decisions.

## Parameters
| Parameter | Config Key | Required | Description |
|-----------|------------|----------|-------------|
| Workspace root | `general.workdir` | Yes | Root workspace inspected for stage outputs and status signals. |
| Docking mode | `docking.mode` | Conditional | Used to report relevant docking-path expectations in status summaries. |
| Complex mode | `complex.mode` | Conditional | Used to report AMBER/CHARMM complex-path expectations in status summaries. |

## Scripts
| Script | Purpose |
|--------|---------|
| `scripts/commands/status.sh` | Command entrypoint for workspace status introspection and reporting. |

## Success Criteria
- Status output clearly identifies completed vs pending workflow stages.
- Latest handoff/checkpoint state is reported with enough detail for next action selection.

## Usage Example
Slash command: `/status --config config.ini`

Agent invocation: `N/A (status is read-only introspection without runner dispatch)`

## Workflow
1. Read config and workspace artifacts to infer workflow mode and stage context.
2. Inspect handoff/checkpoint files to determine completion status per stage.
3. Summarize latest stage outcome, pending stages, and likely next action.
4. Return concise status report with pointers to relevant logs/artifacts when issues are detected.
