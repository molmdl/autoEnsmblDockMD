# Phase 7: First Controlled Execution - Research

**Researched:** 2026-05-03
**Domain:** Workflow validation, end-to-end testing, dry-run execution
**Confidence:** HIGH

## Summary

Phase 7 requires executing the full Mode A (targeted docking) workflow in an isolated workspace and validating outputs against expected results. The pipeline has comprehensive dry-run support through `scripts/run_pipeline.sh --dry-run`, and several validation plugins exist (preflight, workspace-init, handoff-inspect). However, key gaps exist: (1) expected outputs in `expected/amb/` are symbolic links to external directories that may need copying, (2) no comprehensive validation script exists for comparing generated outputs to expected outputs with MD-appropriate tolerances, and (3) token/runtime/disk metrics tracking is not built into the pipeline (external to scripts).

**Primary recommendation:** Build a Phase 7 execution orchestrator that wraps existing tools (preflight, workspace-init, pipeline dry-run) and adds two new components: (1) a dryrun report generator that produces the comprehensive markdown report with file/config readiness, tool availability, command preview, and text-based flowchart; (2) a validation comparator that checks generated outputs against expected with loose numerical tolerances for MD-derived values.

## Standard Stack

The established tools for this validation phase:

### Core
| Library/Tool | Version | Purpose | Why Standard |
|--------------|---------|---------|--------------|
| `scripts/run_pipeline.sh` | v1 | Pipeline orchestrator | Dispatches all stages with `--dry-run` support |
| `scripts/infra/plugins/preflight.py` | v1 | Config/tool/input validation | Mode-aware preflight checks |
| `scripts/infra/plugins/workspace_init.py` | v1 | Workspace initialization | Isolated workspace setup with security boundary |
| `scripts/infra/plugins/handoff_inspect.py` | v1 | Handoff status triage | Normalizes stage status for decision-making |

### Supporting
| Library/Tool | Version | Purpose | When to Use |
|--------------|---------|---------|-------------|
| `scripts/agents/checker.py` | v1 | Output validation | Post-stage quality checks |
| `scripts/agents/debugger.py` | v1 | Failure diagnosis | Error analysis and remediation suggestions |
| `scripts/infra/plugins/group_id_check.py` | v1 | MM/PBSA group validation | Before MM/PBSA calculations |
| `scripts/infra/plugins/conversion_cache.py` | v1 | Format conversion caching | During docking/complex prep |

### Test Inputs Available
| Input | Location | Purpose |
|-------|----------|---------|
| `rec.pdb` | `work/input/` | Reference receptor for alignment target |
| `2bxo.pdb` | `work/input/` | Starting receptor for ensemble generation |
| `ref.pdb` | `work/input/` | Reference ligand for pocket definition |
| `dzp/` | `work/input/dzp/` | Reference ligand with AMBER topology |
| `ibp/` | `work/input/ibp/` | New ligand with AMBER topology |
| `amber19SB_OL21_OL3_lipid17.ff/` | `work/input/` (symlink) | AMBER force field files |

### Expected Outputs Structure (Mode A)
| Directory | Contents | Status |
|-----------|----------|--------|
| `expected/amb/rec/ensemble/` | `hsa0.gro` - `hsa9.gro` (10 conformers) | Accessible |
| `expected/amb/dock/` | Symlinks to external directory | **May need copying** |
| `expected/amb/com_md/ref/dzp/` | Symlink to external directory | **May need copying** |
| `expected/amb/com_md/new/dzp/`, `ibp/` | Symlinks to external directory | **May need copying** |

**Critical note:** Most `expected/amb/` files are symbolic links to `/share/home/nglokwan/dparker/dp_xinyi/`. User may need to copy actual files from another computer if symlinks are inaccessible.

## Architecture Patterns

### Recommended Validation Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    PHASE 7: VALIDATION FLOW                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. DRYRUN PHASE                                                             │
│     ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                   │
│     │ preflight   │───▶│ workspace   │───▶│ dryrun      │                   │
│     │ validation  │    │ init        │    │ report      │                   │
│     └─────────────┘    └─────────────┘    └─────────────┘                   │
│            │                  │                  │                           │
│            ▼                  ▼                  ▼                           │
│     .handoffs/          work/test/         .planning/                       │
│     preflight_*.json    (isolated)         07-dryrun-report.md              │
│                                                                              │
│     MANUAL APPROVAL GATE ←───────────────────────────────────────────────   │
│                                                                              │
│  2. EXECUTION PHASE                                                          │
│     ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                   │
│     │ run_pipeline│───▶│ stage       │───▶│ validation  │                   │
│     │ (Mode A)    │    │ monitoring  │    │ comparator  │                   │
│     └─────────────┘    └─────────────┘    └─────────────┘                   │
│            │                  │                  │                           │
│            ▼                  ▼                  ▼                           │
│     work/test/          .handoffs/         .planning/                       │
│     (artifacts)         stage/*.json       07-execution-report.md           │
│                                                                              │
│  3. FAILURE HANDLING                                                         │
│     ┌─────────────┐    ┌─────────────┐                                       │
│     │ checker     │◀───│ stage       │  On NEEDS_REVIEW/FAILURE             │
│     │ validate    │    │ failure     │                                       │
│     └─────────────┘    └─────────────┘                                       │
│            │                                                                 │
│            ▼                                                                 │
│     ┌─────────────┐                                                          │
│     │ debugger    │  Generate diagnosis, wait for user approval             │
│     │ diagnose    │                                                          │
│     └─────────────┘                                                          │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Pattern 1: Dryrun Report Generation
**What:** Generate comprehensive markdown report before real execution
**When to use:** Before any expensive workflow execution
**Example:**
```bash
# Source: scripts/run_pipeline.sh --dry-run
bash scripts/run_pipeline.sh --config config.ini --dry-run

# Output: List of commands that would run
[DRY-RUN] /path/to/scripts/rec/0_prep.sh --config config.ini
[DRY-RUN] /path/to/scripts/rec/1_pr_rec.sh --config config.ini
...
```

**Gap:** Current dry-run only prints commands. Need wrapper to produce:
1. File/config readiness status (from preflight)
2. Tool availability check results (from preflight)
3. Command preview (existing dry-run)
4. Text-based flowchart showing stages/sub-steps/scripts

### Pattern 2: Workspace Initialization
**What:** Create isolated workspace from template with security boundary enforcement
**When to use:** Before any test/production run
**Source:** `scripts/infra/plugins/workspace_init.py`

```python
# Initialize workspace with boundary checks
from scripts.infra.plugins.workspace_init import initialize_workspace

record = initialize_workspace(
    template_dir=Path("work/input"),
    target_dir=Path("work/test"),
    force=True,  # Overwrite existing
)

# record.status: SUCCESS | FAILURE | BLOCKED
# record.data["workspace_path"]: created workspace location
# record.warnings: missing critical inputs
```

**Security boundary:** `--force` deletion restricted to `work/` directory only via `is_relative_to(work_root)` check.

### Pattern 3: Handoff-Based Progress Tracking
**What:** Use `.handoffs/*.json` files as canonical run-state ledger
**When to use:** After each stage execution
**Source:** `scripts/infra/plugins/handoff_inspect.py`

```python
# Inspect latest handoff
from scripts.infra.plugins.handoff_inspect import inspect_latest_handoff

record = inspect_latest_handoff(Path("work/test"))

# Normalized status: SUCCESS | FAILED | NEEDS_REVIEW | BLOCKED
# record.data["latest_stage"]: last completed stage
# record.data["next_action"]: recommended next command
```

### Anti-Patterns to Avoid
- **Assuming symlinks resolve:** Check if `expected/amb/*` symlinks point to accessible files before validation
- **Exact numerical comparison:** MD/MM/PBSA outputs have high variance; use tolerance ranges
- **Blocking on warnings:** `NEEDS_REVIEW` status should allow continuation after user acknowledgment
- **Skipping preflight:** Tool availability and config validation prevents late-stage failures

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Config validation | Custom INI parser | `scripts/infra/plugins/preflight.py` | Mode-aware validation, tool checks |
| Workspace setup | Manual `cp -r` | `scripts/infra/plugins/workspace_init.py` | Security boundaries, template validation |
| Status triage | Parse handoff JSON manually | `scripts/infra/plugins/handoff_inspect.py` | Normalized status, next-action guidance |
| Stage dispatch | Custom orchestration | `scripts/run_pipeline.sh` | Stage ordering, config section validation |
| Failure diagnosis | Manual log inspection | `scripts/agents/debugger.py` | Known error patterns, environment capture |

**Key insight:** The pipeline already has robust infrastructure for validation and execution. Phase 7 should wrap these tools rather than reimplement them.

## Common Pitfalls

### Pitfall 1: Symlink Resolution Failure
**What goes wrong:** Expected outputs in `expected/amb/` are symlinks to `/share/home/nglokwan/dparker/dp_xinyi/` which may not be accessible
**Why it happens:** Expected outputs stored on different filesystem/machine
**How to avoid:** 
1. Check symlink accessibility with `readlink -f` before validation
2. If inaccessible, request user to copy actual files from source
3. Document expected file structure for user reference
**Warning signs:** `ls: cannot access expected/amb/dock/dzp: No such file or directory`

### Pitfall 2: MD Numerical Variance
**What goes wrong:** Exact numerical comparison fails for MD-derived outputs
**Why it happens:** MD simulations have inherent stochasticity; different random seeds, GPU nondeterminism
**How to avoid:**
1. Use tolerance ranges for numerical values (e.g., RMSD mean ± 2σ)
2. Compare structure counts exactly (atom count, residue count, frame count)
3. Do NOT validate binding energies (MM/PBSA variance too high)
**Recommended tolerances:**
- Docking scores: ±10% relative tolerance for top poses
- RMSD/RMSF mean: ±20% relative tolerance
- RMSD/RMSF std: ±30% relative tolerance
- Structure counts: Exact match required

### Pitfall 3: Asynchronous Stage Completion
**What goes wrong:** Assuming stage completion when wrapper returns
**Why it happens:** `rec_prod`, `com_prod`, `com_mmpbsa` submit Slurm jobs asynchronously
**How to avoid:**
1. Check job status with `squeue -u $USER` before advancing
2. Use `sacct -j <jobid> --format=JobID,State,Elapsed,ExitCode` for completion verification
3. Stage outputs not ready until Slurm job completes
**Warning signs:** Downstream stage fails with "file not found" for trajectory files

### Pitfall 4: Force-Field Incompatibility
**What goes wrong:** AMBER protein + CGenFF ligand topology mismatch
**Why it happens:** Mixed force-field assumptions in topology assembly
**How to avoid:**
1. Verify `[dock2com] ff = amber` for AMBER workflows
2. Check ligand `.itp` file uses GAFF2 atom types for AMBER
3. Use `scripts/com/bypass_angle_type3.py` for AMBER angle type issues
**Warning signs:** GROMACS fatal error during `gmx grompp` with "Unknown angle type"

### Pitfall 5: Missing Hydrogens
**What goes wrong:** Docking/MD/MM/PBSA fail with structure errors
**Why it happens:** Input structures missing hydrogen atoms
**How to avoid:**
1. Check `ref.pdb`, `rec.pdb`, ligand structures have H atoms
2. Use `pdb2pqr` with `--keep-chain` for protonation
3. Verify `[docking] addH = off` means input already has H (or set `addH = on`)
**Warning signs:** gnina docking produces unrealistic poses, GROMACS crashes in minimization

## Code Examples

Verified patterns from official sources:

### Preflight Validation
```python
# Source: scripts/infra/plugins/preflight.py
from scripts.infra.plugins.preflight import PreflightValidator

validator = PreflightValidator(config_path=Path("config.ini"))
validator.workspace_root = Path("work/test")
record = validator.validate()

# record.status: SUCCESS | FAILURE | NEEDS_REVIEW
# record.errors: blocking issues
# record.warnings: non-blocking issues
# record.data["mode"]: targeted | blind | test
# record.data["tools_checked"]: ["gmx", "gnina", "gmx_MMPBSA"]
```

### Pipeline Dry-Run
```bash
# Source: scripts/run_pipeline.sh
# Dry-run single stage
bash scripts/run_pipeline.sh --config config.ini --stage rec_prep --dry-run

# Dry-run full pipeline
bash scripts/run_pipeline.sh --config config.ini --dry-run

# Output: [DRY-RUN] <command> for each stage
```

### Workspace Initialization
```bash
# Source: scripts/infra/plugins/workspace_init.py
python -m scripts.infra.plugins.workspace_init \
    --template work/input \
    --target work/test \
    --force

# Output: HandoffRecord JSON with workspace_path, template_source, created_dirs
```

### Handoff Inspection
```bash
# Source: scripts/infra/plugins/handoff_inspect.py
python -m scripts.infra.plugins.handoff_inspect --workspace work/test

# Output: HandoffRecord JSON with:
# - latest_stage: last completed stage name
# - latest_status: SUCCESS | FAILED | NEEDS_REVIEW | BLOCKED
# - next_action: recommended next command
```

### Runner Agent Execution (for reference)
```python
# Source: scripts/agents/runner.py
from scripts.agents.runner import RunnerAgent

runner = RunnerAgent(workspace=Path("work/test"))
result = runner.execute({
    "stage": "rec_prep",
    "script": "scripts/rec/0_prep.sh",
    "params": {"config": "config.ini"},
})

# result["status"]: success | failure
# result["data"]["script_result"]["duration_seconds"]: execution time
# result["data"]["metrics"]: extracted numerical values (RMSD, energy, score)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual workspace setup | `workspace_init.py` plugin | Phase 6 | Secure, reproducible isolation |
| Ad-hoc preflight checks | `preflight.py` plugin | Phase 6 | Mode-aware validation |
| Hand-written status parsing | `handoff_inspect.py` plugin | Phase 6 | Normalized status vocabulary |
| No workspace boundary checks | `is_relative_to(work_root)` | Phase 6.1 | Prevents accidental deletion outside work/ |
| No frame striding in analysis | Auto-calculated stride | Phase 6.1 | Memory-safe trajectory analysis |

**Deprecated/outdated:**
- Manual `cp -r work/input work/test`: Use `workspace_init.py` for security
- Direct handoff JSON parsing: Use `handoff_inspect.py` for normalized status
- Assume all stage scripts synchronous: Check Slurm job status for async stages

## Open Questions

### 1. Expected Output File Availability
**Question:** Are the symlink targets in `expected/amb/` accessible during Phase 7 execution?
**What we know:** 
- Symlinks point to `/share/home/nglokwan/dparker/dp_xinyi/`
- User mentioned "user will provide/copy from another computer if needed"
- `expected/amb/rec/ensemble/*.gro` files exist directly (not symlinks)
**What's unclear:** Which specific expected outputs are needed for validation
**Recommendation:** Create checklist of required expected files; verify accessibility before execution

### 2. Token Tracking Mechanism
**Question:** How should token input/output counts be tracked during agent-assisted execution?
**What we know:**
- Runner agent tracks `duration_seconds` but not tokens
- CONTEXT.md specifies tracking "token input count, token output count, cache usage, and LLM model used"
- Agent execution is explicitly experimental
**What's unclear:** Whether tokens should be tracked at wrapper level or externally via OpenCode
**Recommendation:** Track tokens via OpenCode session metadata if agent-assisted; document manual execution separately

### 3. Failure Documentation Format
**Question:** Should failures be documented in separate report or integrated into main report?
**What we know:**
- CONTEXT.md says "OpenCode's discretion — prefer separate failure report for ease of debug sessions, but check current agent behavior for consistency"
- Debugger agent generates `.debug_reports/{stage}_{timestamp}.json` 
- Checker agent outputs validation reports
**What's unclear:** Preferred consolidation format
**Recommendation:** Separate failure reports in `.debug_reports/` with summary in main execution report; consistent with current agent behavior

### 4. Numerical Tolerance Standards
**Question:** What are field-standard tolerances for MD/MM/PBSA numerical comparisons?
**What we know:**
- CONTEXT.md says "loose tolerances due to high degrees of freedom"
- User specified NOT validating binding energies (MM/PBSA variance too high)
- Structure counts should be exact
**What's unclear:** Industry-standard tolerance ranges for RMSD/RMSF/docking scores
**Recommendation:** 
- Docking scores: ±10% relative (based on typical scoring function variance)
- RMSD mean: ±20% relative (based on MD ensemble variability)
- RMSF std: ±30% relative (higher variance in fluctuation measurements)
- Atom/residue/frame counts: Exact match required

## Gaps Between Current Tools and Phase 7 Requirements

| Requirement | Current Status | Gap | Recommended Solution |
|-------------|---------------|-----|---------------------|
| Comprehensive dryrun report | `--dry-run` prints commands only | No structured markdown report with file/tool checks | Create `07-dryrun-report.sh` wrapper combining preflight + dry-run + flowchart |
| Output validation comparator | Checker validates format/existence | No comparison to expected outputs with tolerances | Create `07-validate-outputs.py` script with tolerance-based comparison |
| Token tracking | Not implemented in scripts | No token count tracking | Track via OpenCode session metadata (external to pipeline) |
| Runtime tracking | `duration_seconds` in runner | No cumulative runtime across stages | Sum from handoff records in execution report |
| Disk usage tracking | Not implemented | No disk usage growth tracking | Add `du -sh` checkpoints between stages in wrapper |
| Text-based flowchart | Not implemented | No visual workflow documentation | Generate ASCII flowchart from `run_pipeline.sh --list-stages` output |
| Expected output verification | Manual inspection | No automated comparison | Create tolerance-based comparator for Mode A outputs |

## Sources

### Primary (HIGH confidence)
- `scripts/run_pipeline.sh` - Pipeline orchestrator with dry-run support
- `scripts/infra/plugins/preflight.py` - Config/tool/input validation
- `scripts/infra/plugins/workspace_init.py` - Workspace initialization with boundary checks
- `scripts/infra/plugins/handoff_inspect.py` - Handoff status triage
- `scripts/agents/runner.py` - Stage execution with metrics extraction
- `scripts/agents/checker.py` - Output validation checks
- `scripts/agents/debugger.py` - Failure diagnosis with environment capture
- `WORKFLOW.md` - Workflow execution reference
- `AGENTS.md` - Agent roles and security model

### Secondary (MEDIUM confidence)
- `expected/amb/README.md` - Mode A expected output structure
- `work/input/README.md` - Test input descriptions
- `.planning/phases/06.1-*/06.1-VERIFICATION.md` - Phase 6.1 validation patterns
- `scripts/agents/schemas/state.py` - Workflow stage definitions
- `scripts/agents/schemas/handoff.py` - Handoff record schema

### Tertiary (LOW confidence)
- `expected/slurm-91652.out` - Sample error log (may not represent current expected outputs)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Existing tools are well-documented and verified in Phase 6.1
- Architecture: HIGH - Patterns derived from actual implementation code
- Pitfalls: HIGH - Based on known issues from STATE.md and workflow documentation
- Gaps: HIGH - Clear requirements from CONTEXT.md, clear current tool capabilities
- Expected outputs: MEDIUM - Symlink accessibility unclear, may need user action

**Research date:** 2026-05-03
**Valid until:** 2026-06-03 (stable infrastructure, 30-day validity appropriate)
