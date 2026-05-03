# Phase 7: First Controlled Execution - Context

**Gathered:** 2026-05-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Execute full targeted docking workflow (Mode A) in isolated workspace and validate outputs against expected results. Start with read-only dryrun before real test. This is a validation phase to confirm the pipeline works end-to-end before recommending production use.

## Execution Approach (DECISION: Option B)

**User Decision (2026-05-03):** Use Option B - Agent Skills with Checkpoint Flow

**Rationale:**
- Phase goal is to TEST agent skills in `.opencode/skills/`, not just run pipeline scripts
- Agent skills submit Slurm jobs asynchronously and return immediately
- Checkpoint flow enables proper async job handling without context overflow

**Implementation Pattern:**
1. Load skill via `skill` tool (e.g., `skill(name="aedmd-rec-ensemble")`)
2. Execute skill wrapper (submits Slurm job, returns immediately)
3. Parse job ID from `work/test/.handoffs/*.json`
4. Write checkpoint to `.continue-here.md` with job ID and "waiting" status
5. EXIT session with instructions to wait for job completion
6. On resume: check `sacct` for job status, verify outputs, proceed to next stage

**Stages with async Slurm jobs (require checkpoints):**
| Stage | Skill | Duration | Checkpoint Needed |
|-------|-------|----------|-------------------|
| rec_prod | aedmd-rec-ensemble | 24-48 hrs | Yes |
| dock_run | aedmd-dock-run | 1-4 hrs | Yes |
| com_setup (equil) | aedmd-com-setup | 1-4 hrs | Yes |
| com_md | aedmd-com-md | 24-48 hrs | Yes |
| com_mmpbsa | aedmd-com-mmpbsa | 2-8 hrs | Yes |

**Alternative approaches NOT chosen:**
- Option A: Replan phase with agent skills as primary interface (discards current plans)
- Option C: Hybrid - test skills for simple stages, fall back to scripts for long jobs (inconsistent testing)

</domain>

<decisions>
## Implementation Decisions

### Dryrun Scope

- **Coverage:** Run dryrun for both blind and targeted docking modes, but emphasize targeted mode in report (the mode we'll actually execute)
- **Validation level:** File/config readiness checks + tool availability checks + syntax validation
- **Output:** Markdown report with:
  - File/config readiness status
  - Tool availability check results
  - Command preview (all commands that would run)
  - Text-based flowchart showing stages, sub-steps, and scripts called
- **Transition to real execution:** Manual approval required after reviewing dryrun report
- **Tools to test:** Test both human-facing tools AND agent skills for both docking modes

### Validation Criteria

- **Files to validate:** Research phase will identify specific files; user will provide/copy from another computer if needed
- **Validation level:** Check existence, format, approximate filesize, key values (NOT exact numerical match due to MD randomness)
- **Key values to validate:**
  - Docking scores (top poses and rankings)
  - RMSD/RMSF statistics (mean and standard deviation ranges, not exact values)
  - Structure counts (atom counts, residue counts, frame counts — exact)
- **NOT validated:** Binding energies (MM/PBSA has too much variance)
- **Tolerance levels:** Loose tolerances due to high degrees of freedom in MD systems

### Failure Handling

- **Research needed first:** Check current checker and debugger agent behavior to ensure consistency
- **Test execution behavior:** Continue to test coverage (test downstream stages even if upstream fails), then report all failures
- **Failure response:** Suggest checker/debugger agents to handle specific failures, wait for user approval before proceeding
- **Failure documentation:** OpenCode's discretion — prefer separate failure report for ease of debug sessions, but check current agent behavior for consistency

### Report Depth

- **Detail level:** Comprehensive with analytics (OpenCode's discretion with rationale)
  - Per-stage: inputs, outputs, pass/fail, duration, key metrics, errors if any
  - Cross-stage: total tokens, cumulative runtime, disk usage growth, stage dependencies
- **Token tracking:** Track token input count, token output count, cache usage, and LLM model used (NOT cost)
- **Storage location:** Planning directory (.planning/phases/07-*) for project record

### OpenCode's Discretion

- Failure documentation format (check current agent behavior for consistency first)
- Exact tolerance levels for numerical comparisons (propose based on field standards during planning)
- Detailed report structure within comprehensive+analytics scope

</decisions>

<specifics>
## Specific Ideas

- "MD has randomness" — account for stochastic variation in validation approach
- "Expected has more than enough" — use existing expected/ reference outputs generously
- "Degree of freedom is high here, looser" — apply loose tolerances for numerical comparisons
- "Test the related agent (check)" — use failures as opportunities to validate checker agent behavior
- Workspace and test files will be identified during research phase; user may need to copy files from another computer

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 07-first-controlled-execution*
*Context gathered: 2026-05-03*
