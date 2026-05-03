# Phase 7: First Controlled Execution - Research

**Researched:** 2026-05-03
**Domain:** Agent skill orchestration and execution patterns
**Confidence:** HIGH

## Summary

This research addresses the critical failure from previous execution: the executor ran pipeline scripts directly (`run_pipeline.sh --stage X`) instead of using the agent skill interface. The phase goal is to TEST the skill orchestration workflow, not just run the pipeline.

Agent skills in `.opencode/skills/` provide the orchestration interface. The skill tool loads skill instructions, which guide execution through wrapper scripts, the runner agent, and finally the actual pipeline scripts. For Slurm-backed stages, jobs submit asynchronously and return immediately with status=success meaning "submission successful" (not "job complete").

**Primary recommendation:** Plans must explicitly instruct executors to use `skill(name="aedmd-<name>")` to load skill instructions, then follow the skill's execution pattern. Never instruct executors to run pipeline scripts directly.

## Standard Stack

The established pattern for skill orchestration:

### Core Components
| Component | Purpose | Location |
|-----------|---------|----------|
| Skill tool | Loads skill instructions into conversation | Built-in tool: `skill(name=...)` |
| SKILL.md files | Define execution patterns and parameters | `.opencode/skills/*/SKILL.md` |
| Wrapper scripts | Bridge between skills and agents | `scripts/commands/aedmd-*.sh` |
| common.sh | Shared utilities for wrappers | `scripts/commands/common.sh` |
| Runner agent | Executes scripts and creates handoffs | `scripts/agents/runner.py` |
| Handoff schema | Status and data exchange format | `scripts/agents/schemas/handoff.py` |
| Checkpoint manager | State persistence for long jobs | `scripts/infra/checkpoint.py` |

### Execution Flow
```
┌─────────────┐
│ Skill Tool  │  Load skill(name="aedmd-<stage>")
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ SKILL.md    │  Provides instructions, parameters, expected outputs
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Wrapper     │  scripts/commands/aedmd-<stage>.sh
│  (bash)     │  - Sources common.sh
└──────┬──────┘  - Calls dispatch_agent("runner", "<stage_token>")
       │         - Calls check_handoff_result("<stage_token>")
       ▼
┌─────────────┐
│ Runner      │  scripts/agents/runner.py
│  (python)   │  - Executes script via subprocess
└──────┬──────┘  - Creates HandoffRecord
       │         - Saves to .handoffs/<stage>.json
       ▼
┌─────────────┐
│ Pipeline    │  scripts/rec/ | dock/ | com/*.sh
│  Script     │  - May submit Slurm job (async)
└──────┬──────┘  - Returns exit code
       │
       ▼
┌─────────────┐
│ Handoff     │  .handoffs/<stage>.json
│  JSON       │  - status: success/failure/needs_review/blocked
└─────────────┘  - data: job IDs, metrics, paths
```

### Installation
No installation needed. Skills are loaded dynamically via the built-in `skill` tool.

## Architecture Patterns

### Pattern 1: Skill Invocation (CORRECT)

**What:** Load skill instructions via skill tool, then follow the skill's guidance

**When to use:** ALWAYS for Phase 7 - this is the phase goal

**Example:**
```
## Task 1: Execute Receptor Ensemble Generation

**Action:** Load the receptor ensemble skill and execute

1. Load skill instructions:
   ```
   Use the skill tool to load: skill(name="aedmd-rec-ensemble")
   ```

2. After skill loads, follow the instructions in the SKILL.md:
   - Execute the wrapper: `bash scripts/commands/aedmd-rec-ensemble.sh --config config.ini`
   - Verify handoff created: `.handoffs/receptor_prep.json`

3. Verify handoff status:
   ```bash
   jq -r '.status' .handoffs/receptor_prep.json
   # Expected: "success"
   ```

4. For async Slurm jobs, extract job ID:
   ```bash
   jq -r '.data.job_id // .metadata.job_id // empty' .handoffs/receptor_prep.json
   ```

5. Write checkpoint to `.continue-here.md`:
   ```markdown
   ---
   phase: 07-first-controlled-execution
   task: 1
   status: waiting
   job_id: <extracted_job_id>
   ---
   
   Waiting for Slurm job <job_id> to complete.
   Check: sacct -j <job_id>
   ```

6. EXIT session with clear instructions to wait for job completion
```

**Source:** Based on `.opencode/skills/aedmd-*/SKILL.md` files and `scripts/commands/common.sh`

### Pattern 2: Direct Pipeline Invocation (WRONG - DO NOT USE)

**Anti-pattern:**
```
## Task 1: Run Receptor Ensemble

**Action:** Execute pipeline script directly

1. Run: `bash scripts/run_pipeline.sh --stage rec_*`
```

**Why it's wrong:**
- Bypasses skill interface entirely
- No handoff JSON created
- Skill orchestration never tested
- Defeats Phase 7 goal

**Source:** This is what caused the failure in the previous execution

### Pattern 3: Checkpoint Flow for Async Jobs

**What:** Handle long-running Slurm jobs with checkpoint/resume pattern

**When to use:** For stages that submit Slurm jobs (rec_prod, dock_run, com_md, com_mmpbsa)

**Example:**
```markdown
## Task 2: Execute Docking (Async)

**Step 1: Submit Job**
1. Load skill: `skill(name="aedmd-dock-run")`
2. Execute wrapper: `bash scripts/commands/aedmd-dock-run.sh --config config.ini`
3. Verify handoff: `jq '.status' .handoffs/docking_run.json`
4. Extract job ID: `jq -r '.data.slurm_job_ids[0]' .handoffs/docking_run.json`

**Step 2: Write Checkpoint**
Create `.continue-here.md`:
```markdown
---
phase: 07-first-controlled-execution
task: 2
status: waiting
job_ids: [12345, 12346, 12347]
last_updated: 2026-05-03T22:00:00+08:00
---

<current_state>
Waiting for docking jobs to complete.

Jobs: 12345, 12346, 12347
Check: sacct -j 12345,12346,12347

Expected outputs:
- dock/dzp/docked.sdf
- dock/ibp/docked.sdf
</current_state>

<next_action>
Resume when jobs complete:
1. Check job status: sacct -j 12345,12346,12347
2. Verify outputs exist
3. Load next skill: skill(name="aedmd-com-setup")
</next_action>
```

**Step 3: EXIT**
Exit session with message: "Slurm jobs submitted. Resume after jobs complete (check with sacct)."

**Step 4: Resume (in new session)**
1. Read `.continue-here.md`
2. Check job status: `sacct -j <job_ids>`
3. If complete, verify outputs
4. Proceed to next stage
```

**Source:** Derived from `.opencode/skills/aedmd-orchestrator-resume/SKILL.md` and checkpoint manager patterns

### Anti-Patterns to Avoid

1. **Running pipeline scripts directly**
   - Wrong: `run_pipeline.sh --stage X`
   - Right: Load skill → Execute wrapper → Verify handoff

2. **Ignoring handoff status**
   - Wrong: Execute skill, assume success
   - Right: Check `.handoffs/<stage>.json` status field

3. **Treating async job completion as synchronous**
   - Wrong: Skill returns success → assume job complete
   - Right: Success means "submission successful" → checkpoint → wait → resume

4. **Not verifying handoff JSON creation**
   - Wrong: Execute wrapper, proceed to next task
   - Right: Verify `.handoffs/<stage>.json` exists and has valid status

## Don't Hand-Roll

Problems that have existing solutions in the skill system:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stage execution | Custom script invocation | Skill tool + wrapper | Tests orchestration, creates handoffs |
| Job tracking | Manual Slurm queries | Checkpoint + handoff data | Preserves context across sessions |
| Status checking | Ad-hoc status logic | `check_handoff_result()` in common.sh | Standardized exit codes and messages |
| Error handling | Try-catch around scripts | Handoff status + recommendations | Structured failure reporting |
| Session continuation | Memory-based state | `.continue-here.md` + `.checkpoints/` | Resumable across context windows |

**Key insight:** The skill system provides the orchestration layer. Phase 7's goal is to TEST this layer. Don't bypass it.

## Common Pitfalls

### Pitfall 1: Skill Tool Misunderstanding

**What goes wrong:** Executor thinks skill tool "runs" the skill

**Why it happens:** The skill tool is called "skill", which sounds like an action

**How to avoid:**
- Skill tool LOADS instructions, it doesn't execute anything
- After loading, follow the instructions in SKILL.md
- Instructions typically say to run a wrapper script

**Warning signs:**
- Plan says "run skill X" without specifying the wrapper
- Executor tries to call skill tool multiple times in one session
- No wrapper script invocation mentioned

**Correct pattern:**
```
1. Load skill: skill(name="aedmd-<stage>")
2. Read the instructions that were loaded
3. Execute the wrapper script mentioned in SKILL.md
4. Verify handoff JSON
```

### Pitfall 2: Handoff Status Misinterpretation

**What goes wrong:** Treating `status: success` as "job complete" for Slurm stages

**Why it happens:** Success sounds like full completion

**How to avoid:**
- For Slurm stages: `success` = "job submitted successfully"
- Must check job status separately with `sacct`
- Must verify output files exist
- Must implement checkpoint flow

**Warning signs:**
- Plan proceeds to next stage immediately after skill execution
- No checkpoint file created
- No job ID extracted from handoff

**Correct interpretation:**
```json
{
  "status": "success",
  "stage": "receptor_md",
  "data": {
    "slurm_job_ids": [12345, 12346, 12347, 12348],
    "script_result": {
      "returncode": 0,
      "stdout": "Submitted batch job 12345\n..."
    }
  }
}
```
This means: "Jobs submitted, not complete"

### Pitfall 3: Missing Handoff Verification

**What goes wrong:** Skill wrapper executes but no handoff JSON created

**Why it happens:**
- Wrapper script errors before reaching dispatch_agent
- dispatch_agent fails silently
- Wrong stage token used
- Permission issues in .handoffs/ directory

**How to avoid:**
- Always verify `.handoffs/<stage>.json` exists after execution
- Check handoff status with `jq '.status' .handoffs/<stage>.json`
- Use canonical stage tokens from `scripts/agents/schemas/state.py`

**Stage token mapping (canonical):**
| Skill Name | Stage Token | Handoff File |
|------------|-------------|--------------|
| aedmd-rec-ensemble | receptor_prep | .handoffs/receptor_prep.json |
| aedmd-dock-run | docking_run | .handoffs/docking_run.json |
| aedmd-com-setup | complex_prep | .handoffs/complex_prep.json |
| aedmd-com-md | complex_md | .handoffs/complex_md.json |
| aedmd-com-mmpbsa | complex_mmpbsa | .handoffs/complex_mmpbsa.json |
| aedmd-com-analyze | complex_analysis | .handoffs/complex_analysis.json |

**Verification command:**
```bash
# After executing skill wrapper
if [[ -f .handoffs/<stage>.json ]]; then
  status=$(jq -r '.status' .handoffs/<stage>.json)
  echo "Handoff status: $status"
  
  case "$status" in
    success)
      echo "✓ Stage completed successfully"
      ;;
    needs_review)
      echo "⚠ Warnings detected:"
      jq -r '.warnings[]' .handoffs/<stage>.json
      ;;
    failure|blocked)
      echo "✗ Stage failed:"
      jq -r '.errors[]' .handoffs/<stage>.json
      exit 1
      ;;
  esac
else
  echo "✗ No handoff file created"
  exit 1
fi
```

### Pitfall 4: Plan-Goal Mismatch

**What goes wrong:** Plan instructions contradict phase goal

**Why it happens:**
- Plan written for efficiency, not testing
- Planner didn't understand phase goal
- Skill interface wasn't considered during planning

**How to avoid:**
- Plans must start with phase goal reference
- Each task must test a skill
- Verification must check handoff files
- Success criteria must include "skill orchestration tested"

**Warning signs:**
- Plan says "run run_pipeline.sh"
- No mention of skill tool
- No handoff verification steps
- Success criteria only mention output files

## Code Examples

### Example 1: Complete Skill Invocation Pattern

```bash
# Task: Execute receptor ensemble generation via skill

# Step 1: Load skill instructions (this happens via skill tool in the conversation)
# The skill tool will inject the contents of .opencode/skills/aedmd-rec-ensemble/SKILL.md

# Step 2: Execute the wrapper as instructed by SKILL.md
cd work/test
bash ../../scripts/commands/aedmd-rec-ensemble.sh --config config.ini

# Step 3: Verify handoff creation
if [[ ! -f .handoffs/receptor_prep.json ]]; then
  echo "ERROR: No handoff file created"
  exit 1
fi

# Step 4: Check handoff status
status=$(jq -r '.status' .handoffs/receptor_prep.json)
echo "Handoff status: $status"

# Step 5: Extract job IDs for async stages
job_ids=$(jq -r '.data.slurm_job_ids[]? // .metadata.job_ids[]? // empty' .handoffs/receptor_prep.json)

if [[ -n "$job_ids" ]]; then
  echo "Slurm jobs submitted: $job_ids"
  echo "Jobs are running asynchronously"
  echo "Check completion: sacct -j $(echo $job_ids | tr '\n' ',')"
fi

# Step 6: Write checkpoint if async
if [[ -n "$job_ids" ]]; then
  cat > .continue-here.md <<EOF
---
phase: 07-first-controlled-execution
task: 1
status: waiting
job_ids: [$(echo $job_ids | jq -R -s -c 'split("\n") | map(select(length > 0))')]
last_updated: $(date -Iseconds)
---

<current_state>
Waiting for receptor production MD jobs to complete.

Job IDs: $(echo $job_ids)
Check: sacct -j $(echo $job_ids | tr '\n' ',')

Expected outputs:
- rec/pr_0.xtc through rec/pr_3.xtc
- rec/merged_fit.xtc
</current_state>

<next_action>
Resume when jobs complete:
1. sacct -j <job_ids> | grep COMPLETED
2. Verify output files
3. Load next skill: skill(name="aedmd-dock-run")
</next_action>
EOF
  
  echo "Checkpoint written to .continue-here.md"
  echo "EXIT session now. Resume after jobs complete."
fi
```

**Source:** Based on `scripts/commands/aedmd-rec-ensemble.sh`, `common.sh`, and skill files

### Example 2: Resume Pattern for Async Jobs

```bash
# Task: Resume after async job completion

# Step 1: Read checkpoint
checkpoint_file=".continue-here.md"
if [[ ! -f "$checkpoint_file" ]]; then
  echo "No checkpoint found. Start from beginning."
  exit 1
fi

# Step 2: Extract job IDs
job_ids=$(grep -A1 "^job_ids:" "$checkpoint_file" | tail -1 | jq -r '.[]' | tr '\n' ',')
job_ids=${job_ids%,}  # Remove trailing comma

echo "Checking jobs: $job_ids"

# Step 3: Check job status
job_status=$(sacct -j "$job_ids" --format=State --noheader | sort -u)

if echo "$job_status" | grep -q "RUNNING\|PENDING"; then
  echo "Jobs still running. Exit and wait."
  exit 0
elif echo "$job_status" | grep -q "FAILED\|TIMEOUT\|CANCELLED"; then
  echo "Jobs failed. Check logs."
  sacct -j "$job_ids" --format=JobID,State,ExitCode,Start,End
  exit 1
elif echo "$job_status" | grep -q "COMPLETED"; then
  echo "✓ All jobs completed successfully"
else
  echo "Unknown job status: $job_status"
  exit 1
fi

# Step 4: Verify outputs (example for receptor_md)
expected_outputs=(
  "rec/pr_0.xtc"
  "rec/pr_1.xtc"
  "rec/pr_2.xtc"
  "rec/pr_3.xtc"
)

for output in "${expected_outputs[@]}"; do
  if [[ ! -f "$output" ]]; then
    echo "ERROR: Missing expected output: $output"
    exit 1
  fi
done

echo "✓ All outputs verified"

# Step 5: Proceed to next stage
echo "Ready for next stage. Load skill: skill(name='aedmd-dock-run')"
```

**Source:** Derived from `aedmd-orchestrator-resume` skill and checkpoint manager

### Example 3: Handoff Status Handling

```bash
# Standard handoff status handling from common.sh

check_handoff_result() {
  local stage="$1"
  local handoff_file=".handoffs/${stage}.json"
  
  if [[ ! -f "$handoff_file" ]]; then
    echo "ERROR: Handoff file missing: $handoff_file"
    return 1
  fi
  
  local status
  status=$(jq -r '.status // "unknown"' "$handoff_file")
  echo "Handoff status for $stage: $status"
  
  case "$status" in
    success)
      echo "✓ Stage completed successfully"
      return 0
      ;;
    needs_review)
      echo "⚠ Warnings detected:"
      jq -r '.warnings[]? // empty' "$handoff_file" | sed 's/^/  /'
      echo ""
      echo "Review recommended before proceeding."
      return 2
      ;;
    failure|blocked)
      echo "✗ Stage failed with status: $status"
      echo ""
      echo "Errors:"
      jq -r '.errors[]? // empty' "$handoff_file" | sed 's/^/  /'
      echo ""
      echo "Recommendations:"
      jq -r '.recommendations[]? // empty' "$handoff_file" | sed 's/^/  /'
      return 1
      ;;
    *)
      echo "ERROR: Unknown status: $status"
      return 1
      ;;
  esac
}

# Usage after skill execution:
# check_handoff_result "receptor_prep"
# exit_code=$?
# 
# if [[ $exit_code -eq 0 ]]; then
#   # Proceed to next stage
# elif [[ $exit_code -eq 2 ]]; then
#   # Review warnings, decide whether to proceed
# else
#   # Handle failure
# fi
```

**Source:** `scripts/commands/common.sh` lines 192-235

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Direct script execution | Skill orchestration | Phase 7 design | Tests agent workflow, creates handoffs |
| Synchronous execution assumption | Async checkpoint flow | Phase 7 design | Handles long Slurm jobs |
| No handoff tracking | JSON handoff files | Phase 7 design | Structured status, metrics, errors |
| Memory-based state | File-based checkpoints | Phase 7 design | Resumable across sessions |

**Deprecated/outdated:**
- Running `run_pipeline.sh` directly: Bypasses skill interface, defeats testing goal
- Assuming synchronous completion: Slurm jobs are async, need checkpoint flow
- Ad-hoc status checks: Use standardized handoff status values

## Open Questions

### Question 1: How to handle stage dependencies in plans?

**What we know:**
- Stages have clear dependencies (rec → dock → com_setup → com_md → mmpbsa → analysis)
- Handoff files indicate stage completion
- Checkpoint flow handles async timing

**What's unclear:**
- Should plans check for previous stage handoff before executing?
- Or assume sequential execution and let wrapper fail?

**Recommendation:**
Plans should include verification of previous stage handoff:
```bash
# Before executing dock_run
if [[ ! -f .handoffs/receptor_prep.json ]]; then
  echo "ERROR: receptor_prep not complete. Run aedmd-rec-ensemble first."
  exit 1
fi

# Then proceed to dock_run
skill(name="aedmd-dock-run")
```

### Question 2: What to do with needs_review status?

**What we know:**
- `needs_review` means warnings detected but execution didn't fail
- Handoff contains `.warnings[]` array with warning messages
- Common.sh exit code 2 for needs_review

**What's unclear:**
- Should execution halt for needs_review?
- Who reviews and how?
- When is it safe to proceed?

**Recommendation:**
Plans should handle needs_review explicitly:
```markdown
**If handoff status is needs_review:**
1. Display warnings to user
2. Ask user to decide: proceed or investigate
3. If proceed: continue to next stage
4. If investigate: load debugger skill
```

### Question 3: How to structure multi-plan phases?

**What we know:**
- Phase 7 has multiple stages, each requiring checkpoint flow
- Each async stage requires exit/resume cycle
- Can't fit all stages in one plan/session

**What's unclear:**
- One plan per stage? Or one plan covering multiple stages?
- How to handle plan boundaries with checkpoint flow?

**Recommendation:**
- One plan per logical checkpoint boundary
- Example: Plan 07-03 covers receptor stages (async), ends when rec_prod jobs submitted
- Plan 07-04 covers docking stage, ends when dock jobs submitted
- Each plan is a single session that fits in context window
- Checkpoint file (.continue-here.md) bridges between plans

## Sources

### Primary (HIGH confidence)
- `.opencode/skills/aedmd-rec-ensemble/SKILL.md` - Skill structure and execution pattern
- `.opencode/skills/aedmd-dock-run/SKILL.md` - Skill structure and async job handling
- `.opencode/skills/aedmd-com-setup/SKILL.md` - Complex preparation skill
- `.opencode/skills/aedmd-com-md/SKILL.md` - Async MD execution pattern
- `.opencode/skills/aedmd-orchestrator-resume/SKILL.md` - Resume pattern
- `.opencode/skills/aedmd-status/SKILL.md` - Status checking pattern
- `scripts/commands/common.sh` - Wrapper dispatch and handoff checking
- `scripts/agents/runner.py` - Runner agent execution
- `scripts/agents/schemas/handoff.py` - Handoff status values and structure
- `scripts/agents/schemas/state.py` - WorkflowStage tokens
- `scripts/infra/checkpoint.py` - Checkpoint management

### Secondary (MEDIUM confidence)
- `.planning/phases/07-first-controlled-execution/.continue-here.md` - Previous execution failure analysis
- `.planning/phases/07-first-controlled-execution/07-CONTEXT.md` - Phase decisions and requirements
- `AGENTS.md` - Agent roles and execution boundaries

### Tertiary (LOW confidence)
None - all findings verified with primary sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Direct source from skill files, wrapper scripts, and agent code
- Architecture: HIGH - Verified through code reading and execution flow analysis
- Pitfalls: HIGH - Derived from actual failure case and code inspection

**Research date:** 2026-05-03
**Valid until:** 2026-06-03 (30 days - stable patterns unlikely to change)

---

## Quick Reference for Planners

### How to Write Plans That Test Skills

**Template:**
```markdown
## Task X: Execute <Stage Name>

**Goal:** Test the aedmd-<stage> skill orchestration

**Action:**

1. **Load skill instructions:**
   ```
   Use the skill tool: skill(name="aedmd-<stage>")
   ```

2. **Execute wrapper** (as instructed by SKILL.md):
   ```bash
   cd work/test
   bash ../../scripts/commands/aedmd-<stage>.sh --config config.ini
   ```

3. **Verify handoff creation:**
   ```bash
   # Check handoff file exists
   [[ -f .handoffs/<stage_token>.json ]] || exit 1
   
   # Check status
   status=$(jq -r '.status' .handoffs/<stage_token>.json)
   [[ "$status" == "success" ]] || exit 1
   ```

4. **For async stages:** Extract job ID, write checkpoint, exit

5. **For sync stages:** Verify outputs, proceed to next task

**Success criteria:**
- Skill loaded via skill tool ✓
- Wrapper executed ✓
- Handoff JSON created ✓
- Status verified ✓
- Outputs verified ✓

**Failure mode:**
If executor runs pipeline scripts directly, this defeats the phase goal.
```

### Canonical Stage Mappings

| Skill | Stage Token | Handoff File | Wrapper | Async? |
|-------|-------------|--------------|---------|--------|
| aedmd-rec-ensemble | receptor_prep | .handoffs/receptor_prep.json | scripts/commands/aedmd-rec-ensemble.sh | Yes |
| aedmd-dock-run | docking_run | .handoffs/docking_run.json | scripts/commands/aedmd-dock-run.sh | Yes |
| aedmd-com-setup | complex_prep | .handoffs/complex_prep.json | scripts/commands/aedmd-com-setup.sh | Yes |
| aedmd-com-md | complex_md | .handoffs/complex_md.json | scripts/commands/aedmd-com-md.sh | Yes |
| aedmd-com-mmpbsa | complex_mmpbsa | .handoffs/complex_mmpbsa.json | scripts/commands/aedmd-com-mmpbsa.sh | Yes |
| aedmd-com-analyze | complex_analysis | .handoffs/complex_analysis.json | scripts/commands/aedmd-com-analyze.sh | No |
| aedmd-preflight | preflight_validation | .handoffs/preflight_validation.json | scripts/commands/aedmd-preflight.sh | No |
| aedmd-status | workspace_status | N/A (no agent) | scripts/commands/aedmd-status.sh | No |

### Handoff Status Meanings

| Status | Meaning | Action |
|--------|---------|--------|
| success | Stage completed successfully | Proceed to next stage |
| needs_review | Warnings detected, review recommended | Display warnings, ask user |
| failure | Stage failed with errors | Display errors, stop, debug |
| blocked | External dependency missing | Display blocker, stop, fix |

### Common.sh Exit Codes

| Code | Meaning | Handoff Status |
|------|---------|----------------|
| 0 | Success | success |
| 1 | Failure | failure or blocked |
| 2 | Needs Review | needs_review |
