# Phase 1: Foundation - Context

**Gathered:** 2026-03-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish configuration system, execution environment, and checkpoint infrastructure that enables all downstream work. This phase delivers: local/HPC execution support, job monitoring, error detection, checkpoint system, human verification gates, and file-based state passing.

</domain>

<decisions>
## Implementation Decisions

### Configuration format
- INI/conf style format (simple, human and LLM-friendly)
- Per-stage configs with fallback to global settings
- Explicit path required - config passed as argument, no default location
- CLI flags override config values

### Checkpoint persistence
- Format: JSON/YAML/Markdown (research phase to choose best balance for human readability and LLM friendliness)
- Content: Between full state and complete dump - clear and concise for human reading, sufficient context for agent to resume in fresh session
- Location: Workspace-relative by default, override via user argument
- Naming: Timestamped files (e.g., checkpoint-20260324-143022.{format})
- Trigger: Stage start + stage end + before critical operations + when user requests pause
- Retention: Keep all checkpoints (user manages cleanup)
- Resume: Explicit checkpoint path passed to resume command
- Validation: No validation on load - trust checkpoint integrity

### Execution backend selection
- Auto-detect Slurm environment (check for sbatch/squeue), allow --slurm/--local override
- If Slurm requested but unavailable: interactive prompt to run locally
- Job selection for Slurm: Fixed by default based on workflow - learn from manual trial notes and workflow files during research phase
- Parallel jobs: Independent Slurm submission (not job arrays)

### Human verification gates
- Pause at configured checkpoints, allow bypass with --auto flag
- Pause on critical errors (suggest fix before pause)
- Approval flow: Dump checkpoint, suggest user start fresh session, user passes approve/reject via CLI on resume command
- Gate context displayed: Summary + output paths + key metrics + recommendations
- Gate locations: After each major stage (prep→dock→MD→MMPBSA), potentially after batches if processing many ligands

### Config as central interface
- All configurable options in one place: Slurm options (bypass if user provides template), paths, number of trials, ligands to test
- Wrapper script reads config and calls other scripts
- Human and agent edit the same config file - consistent interface, saves context for agent

### Infrastructure vs workflow scripts
- Phase 1 delivers workflow-agnostic infrastructure utilities (config parsing, checkpoint save/load, verification gates, execution backend detection, job monitoring)
- Phase 2 delivers workflow scripts, wrapper script(s), and gap-filling scripts after WORKFLOW.md is finalized
- This split allows Phase 1 to proceed without workflow dependency

### OpenCode's Discretion
- Exact checkpoint file format (JSON vs YAML vs Markdown) - research to determine
- Specific checkpoint content structure
- Implementation details of checkpoint save/load logic
- Exact format of gate summary/recommendations output

</decisions>

<specifics>
## Specific Ideas

- "Simple, easy for both human and LLM agent to read and write" - guiding principle for config and checkpoint formats
- Checkpoint approach similar to gsd workflow - dump context, user starts fresh session to continue
- Manual trial notes in ./expected will guide which steps use Slurm - generalize during planning

</specifics>

<deferred>
## Deferred Ideas

- Batch checkpoint handling for many ligands - decide after workflow finalized
- Slurm job template customization - user can provide template to bypass defaults (noted in config interface)

</deferred>

---

*Phase: 01-foundation*
*Context gathered: 2026-03-24*
