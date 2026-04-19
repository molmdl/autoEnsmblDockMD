# Skill: orchestrator-resume
**Stage:** workflow_resume
**Agent:** orchestrator

## Capability
Resume interrupted workflow sessions by reconstructing stage state from persisted checkpoints and handoffs. Select the safest continuation point to avoid redundant reruns and preserve workflow integrity.

## Parameters
| Parameter | Config Key | Required | Description |
|-----------|------------|----------|-------------|
| Workspace root | `general.workdir` | Yes | Root workspace where checkpoints and stage outputs are evaluated for resume planning. |
| Receptor stage dir | `receptor.workdir` | Conditional | Used to verify receptor-stage completion when reconstructing pipeline progress. |
| Docking stage dir | `docking.dock_dir` | Conditional | Used to verify docking-stage completion and available downstream inputs. |
| Complex stage dir | `complex.workdir` | Conditional | Used to verify complex prep/MD/MMPBSA progression before resume. |

## Scripts
| Script | Purpose |
|--------|---------|
| `scripts/commands/orchestrator-resume.sh` | Command entrypoint for resume-state reconstruction and next-stage selection. |

## Success Criteria
- Resume decision identifies last reliable completed stage and next executable stage with rationale.
- Updated checkpoint/handoff continuity data is written for resumed orchestration.

## Usage Example
Slash command: `/orchestrator-resume --config config.ini`

Agent invocation: `python -m scripts.agents --agent orchestrator --input handoff.json`

## Workflow
1. Load checkpoint and handoff metadata from workspace persistence directories.
2. Determine most recent successful stage based on status and timestamps.
3. Validate downstream prerequisites to select a safe continuation stage.
4. Emit resume recommendation (next stage + reason + confidence).
5. Update continuity records so subsequent orchestrator actions proceed from consistent state.
