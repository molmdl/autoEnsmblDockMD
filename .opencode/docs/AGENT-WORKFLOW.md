# AGENT-WORKFLOW.md — Pipeline Orchestration Reference

> [!WARNING]
> **EXPERIMENTAL AGENT SUPPORT** — Agent-based operation is experimental. Script-driven human-validated execution is the stable baseline.

Agent-loadable document for orchestrating the full docking→MD→MM/PBSA pipeline.
Structured for machine parsing. Load this document to manage the complete workflow.

---

## 1. Pipeline State Machine

Stages execute in order. Each stage maps to one slash command, one skill, and one script entry point.

| # | Stage ID | Slash Command | Skill File | Script Entry | Agent Type |
|---|----------|---------------|------------|--------------|------------|
| 0 | `input_prep` | `/status` | `.opencode/skills/status/SKILL.md` | `scripts/infra/config_loader.sh` | orchestrator |
| 1 | `receptor_prep` | `/rec-ensemble` | `.opencode/skills/rec-ensemble/SKILL.md` | `scripts/rec/0_prep.sh` | runner |
| 2 | `receptor_md` | `/rec-ensemble` | `.opencode/skills/rec-ensemble/SKILL.md` | `scripts/rec/1_pr_rec.sh` | runner |
| 3 | `receptor_cluster` | `/rec-ensemble` | `.opencode/skills/rec-ensemble/SKILL.md` | `scripts/rec/4_cluster.sh` | runner |
| 4 | `receptor_align` | `/rec-ensemble` | `.opencode/skills/rec-ensemble/SKILL.md` | `scripts/rec/5_align.py` | runner |
| 5 | `docking` | `/dock-run` | `.opencode/skills/dock-run/SKILL.md` | `scripts/dock/2_gnina.sh` | runner |
| 6 | `complex_setup` | `/com-setup` | `.opencode/skills/com-setup/SKILL.md` | `scripts/com/0_prep.sh` | runner |
| 7 | `complex_md` | `/com-md` | `.opencode/skills/com-md/SKILL.md` | `scripts/com/1_pr_prod.sh` | runner |
| 8 | `mmpbsa` | `/com-mmpbsa` | `.opencode/skills/com-mmpbsa/SKILL.md` | `scripts/com/2_run_mmpbsa.sh` | runner |
| 9 | `analysis` | `/com-analyze` | `.opencode/skills/com-analyze/SKILL.md` | `scripts/com/3_ana.sh` | runner |

### Valid Transitions

```
input_prep → receptor_prep
receptor_prep → receptor_md
receptor_md → receptor_cluster
receptor_cluster → receptor_align (optional, skip to docking if Mode B)
receptor_align → docking
receptor_cluster → docking       (Mode B direct path)
docking → complex_setup
complex_setup → complex_md
complex_md → mmpbsa
mmpbsa → analysis
analysis → [COMPLETE]
```

### Mode Differences

| Mode | Description | Key Difference |
|------|-------------|----------------|
| A | Reference pocket / AMBER-oriented | Uses `receptor_align`; targeted/test docking; AMBER FF branch |
| B | Blind docking / CHARMM36m/CGenFF | Skips `receptor_align`; blind docking; CHARMM FF branch |

Mode is set via `[docking] mode` in `config.ini`. Values: `targeted`, `test`, `blind`.

---

## 2. HandoffRecord Schema

Every stage produces a HandoffRecord JSON written to `.handoffs/{stage_id}.json`.

```json
{
  "$schema": "handoff-record-v1",
  "stage": "<string: stage_id from table above>",
  "status": "<string: pending | running | complete | failed | needs_review | blocked>",
  "inputs": {
    "config": "<string: path to config.ini>",
    "workdir": "<string: workspace root directory>",
    "params": "<object: stage-specific CLI/config overrides>"
  },
  "outputs": {
    "artifacts": ["<string: glob pattern or explicit path>"],
    "summary": "<string: human-readable stage outcome>",
    "warnings": ["<string: non-fatal issues>"],
    "errors": ["<string: fatal issues, present if status=failed>"]
  },
  "next_action": "<string: recommended next stage_id or 'human_review' or 'debug'>",
  "error": "<string | null: error message, null if no error>",
  "recommendations": ["<string: remediation steps if failed>"],
  "timestamp": "<string: ISO 8601 UTC, e.g. 2026-04-19T08:00:00Z>"
}
```

### Field Types

| Field | Type | Required | Values |
|-------|------|----------|--------|
| `stage` | string | yes | stage_id from state machine table |
| `status` | string | yes | `pending`, `running`, `complete`, `failed`, `needs_review`, `blocked` |
| `inputs.config` | string | yes | path to config.ini |
| `inputs.workdir` | string | yes | absolute workspace path |
| `inputs.params` | object | no | arbitrary key-value overrides |
| `outputs.artifacts` | array[string] | yes | file paths or globs produced |
| `outputs.summary` | string | yes | one-line stage outcome |
| `outputs.warnings` | array[string] | no | non-fatal issues |
| `outputs.errors` | array[string] | no | fatal errors (if status=failed) |
| `next_action` | string | yes | next stage_id or `human_review` or `debug` |
| `error` | string\|null | yes | error message or null |
| `recommendations` | array[string] | no | remediation steps on failure |
| `timestamp` | string | yes | ISO 8601 UTC |

### Example: Completed Docking → complex_setup Handoff

```json
{
  "$schema": "handoff-record-v1",
  "stage": "docking",
  "status": "complete",
  "inputs": {
    "config": "config.ini",
    "workdir": "/work/test",
    "params": {"mode": "blind"}
  },
  "outputs": {
    "artifacts": [
      "dock/gnina_output/*.sdf",
      "dock/docking_report.csv",
      "dock/pose_*.pdb"
    ],
    "summary": "Blind docking complete: 3 ligands, top poses selected",
    "warnings": [],
    "errors": []
  },
  "next_action": "complex_setup",
  "error": null,
  "recommendations": [],
  "timestamp": "2026-04-19T08:30:00Z"
}
```

---

## 3. Decision Trees

### 3.1 Stage Progression Logic

Given current stage + status, determine next action:

| Current Stage | Status | Next Action |
|---------------|--------|-------------|
| any | `pending` | Load skill → invoke slash command |
| any | `running` | Monitor job → wait → re-check handoff |
| any | `complete` | Invoke `checker-validate` → if pass: advance; if fail: invoke `debugger-diagnose` |
| any | `needs_review` | Invoke `checker-validate` → present warnings → await human gate |
| any | `failed` | Invoke `debugger-diagnose` → apply fix → retry stage |
| any | `blocked` | Inspect handoff errors → resolve dependency → retry |
| `analysis` | `complete` | All stages complete → generate final report |

### 3.2 Checker-Validate Gate

```
Stage completes (status = complete)
    │
    ▼
Invoke checker-validate:
  scripts/commands/checker-validate.sh --config config.ini --stage <stage_id>
    │
    ├── PASS  → Advance to next stage
    │
    └── WARN  → Present warnings to human
                   │
                   ├── Human approves  → Advance to next stage
                   └── Human rejects   → Invoke debugger-diagnose → retry
    │
    └── FAIL  → Invoke debugger-diagnose → apply fix → retry stage
```

### 3.3 Debugger-Diagnose Recovery

```
Stage fails (status = failed)
    │
    ▼
Invoke debugger-diagnose:
  scripts/commands/debugger-diagnose.sh --config config.ini --stage <stage_id>
    │
    ├── Fix identified → Apply fix → Retry stage (max 2 retries)
    │
    └── No fix / 2nd retry fails → Escalate to human review
                                       (write HandoffRecord with status=blocked)
```

### 3.4 Workflow Completion

```
analysis stage → status = complete → checker-validate passes
    │
    ▼
Generate final report:
  - Summarize all HandoffRecord outputs
  - List artifacts per stage
  - Highlight any warnings encountered
  - Write completion record to .handoffs/workflow_complete.json
```

---

## 4. Stage Preconditions and Postconditions

### Stage: `input_prep`

| | Detail |
|--|--------|
| **Command** | `scripts/commands/status.sh` |
| **Skill** | `.opencode/skills/status/SKILL.md` |
| **Required inputs** | `config.ini` (from `scripts/config.ini.template`) |
| **Required env** | `source ./scripts/setenv.sh` |
| **Required config sections** | `[general]`, `[slurm]`, `[receptor]`, `[dock]`, `[docking]` |
| **Expected outputs** | Validated config; resolved paths |
| **Validation checks** | Config sections present; input PDB exists; MDP dirs exist |

### Stage: `receptor_prep`

| | Detail |
|--|--------|
| **Command** | `scripts/commands/rec-ensemble.sh` |
| **Skill** | `.opencode/skills/rec-ensemble/SKILL.md` |
| **Script** | `scripts/rec/0_prep.sh` |
| **Required inputs** | `[receptor] input_pdb` (*.pdb); FF files |
| **Required env** | GROMACS ≥ 2022; conda env active |
| **Expected outputs** | `rec/` dir; protonated/solvated PDB; `.tpr` for equilibration |
| **Validation checks** | Output `.tpr` exists; no topology errors in log |

### Stage: `receptor_md`

| | Detail |
|--|--------|
| **Command** | `scripts/commands/rec-ensemble.sh` |
| **Skill** | `.opencode/skills/rec-ensemble/SKILL.md` |
| **Script** | `scripts/rec/1_pr_rec.sh` |
| **Required inputs** | Equilibrated receptor from `receptor_prep`; `[receptor] n_trials` |
| **Required env** | GROMACS ≥ 2022; Slurm (HPC) or local |
| **Expected outputs** | `rec/trial_*/prod_*.xtc` trajectories |
| **Validation checks** | `n_trials` trajectory files present; no early termination in logs |

### Stage: `receptor_cluster`

| | Detail |
|--|--------|
| **Command** | `scripts/commands/rec-ensemble.sh` |
| **Skill** | `.opencode/skills/rec-ensemble/SKILL.md` |
| **Script** | `scripts/rec/4_cluster.sh` |
| **Required inputs** | Merged trajectory from `3_ana.sh`; `[receptor] cluster_*` config |
| **Required env** | GROMACS ≥ 2022; MDAnalysis |
| **Expected outputs** | `rec/rec*.pdb` ensemble conformers (glob: `rec/rec[0-9]*.pdb`) |
| **Validation checks** | At least 1 conformer file; cluster count matches `ensemble_size` |

### Stage: `receptor_align` (Mode A only)

| | Detail |
|--|--------|
| **Command** | `scripts/commands/rec-ensemble.sh` |
| **Skill** | `.opencode/skills/rec-ensemble/SKILL.md` |
| **Script** | `scripts/rec/5_align.py` |
| **Required inputs** | Receptor ensemble from `receptor_cluster`; reference structure |
| **Required env** | MDAnalysis; python 3.10+ |
| **Expected outputs** | Aligned `rec*.pdb` files |
| **Validation checks** | Aligned files overwrite or supplement originals; no MDAnalysis errors |

### Stage: `docking`

| | Detail |
|--|--------|
| **Command** | `scripts/commands/dock-run.sh` |
| **Skill** | `.opencode/skills/dock-run/SKILL.md` |
| **Scripts** | `scripts/dock/0_gro2mol2.sh` → `1_rec4dock.sh` → `2_gnina.sh` → `3_dock_report.sh` → `4_dock2com_1.py` |
| **Required inputs** | Receptor conformers (`rec/rec*.pdb`); ligand files in `[dock] ligand_dir` |
| **Required env** | gnina; GROMACS ≥ 2022; Open Babel (optional) |
| **Expected outputs** | `dock/gnina_output/*.sdf`; `dock/docking_report.csv`; `dock/pose_*.pdb` |
| **Validation checks** | SDF files non-empty; docking report has score column; at least 1 pose per ligand |

### Stage: `complex_setup`

| | Detail |
|--|--------|
| **Command** | `scripts/commands/com-setup.sh` |
| **Skill** | `.opencode/skills/com-setup/SKILL.md` |
| **Scripts** | `scripts/dock/4_dock2com*.sh` + `4_dock2com_2*.py` → `scripts/com/0_prep.sh` |
| **Required inputs** | Selected poses from `docking`; `[complex]` config section |
| **Required env** | GROMACS ≥ 2022; FF files (AMBER or CHARMM36m/CGenFF) |
| **Expected outputs** | Per-ligand `com/*/com.gro`; `com/*/sys.top`; `com/*/index.ndx`; `posre_lig.itp` |
| **Validation checks** | `com.gro` + `sys.top` + `index.ndx` exist per ligand; no topology mismatch errors |

### Stage: `complex_md`

| | Detail |
|--|--------|
| **Command** | `scripts/commands/com-md.sh` |
| **Skill** | `.opencode/skills/com-md/SKILL.md` |
| **Script** | `scripts/com/1_pr_prod.sh` |
| **Required inputs** | Complex systems from `complex_setup`; `[production]` config |
| **Required env** | GROMACS ≥ 2022; Slurm or local |
| **Expected outputs** | `com/*/prod_*.xtc`; `com/*/prod_*.tpr` |
| **Validation checks** | Production trajectories exist; RMSD < 3Å (key stability threshold); no gromacs crash |

### Stage: `mmpbsa`

| | Detail |
|--|--------|
| **Command** | `scripts/commands/com-mmpbsa.sh` |
| **Skill** | `.opencode/skills/com-mmpbsa/SKILL.md` |
| **Scripts** | `scripts/com/2_run_mmpbsa.sh` → `2_trj4mmpbsa.sh` → `2_sub_mmpbsa.sh` → `2_mmpbsa.sh` |
| **Required inputs** | Production trajectories; `[mmpbsa]` config; AMBER or CHARMM topology |
| **Required env** | gmx_MMPBSA; GROMACS ≥ 2022; `scripts/com/mmpbsa.in` template |
| **Expected outputs** | `mmpbsa/mmpbsa_*/FINAL_RESULTS_MMPBSA.dat`; summary CSV |
| **Validation checks** | MMPBSA result files non-empty; binding energy values present (negative for binders) |

### Stage: `analysis`

| | Detail |
|--|--------|
| **Command** | `scripts/commands/com-analyze.sh` |
| **Skill** | `.opencode/skills/com-analyze/SKILL.md` |
| **Scripts** | `scripts/com/3_ana.sh` → `3_com_ana_trj.py` → `4_cal_fp.sh` / `4_fp.py` |
| **Required inputs** | Production trajectories; `[analysis]` config |
| **Required env** | MDAnalysis; python 3.10+; matplotlib |
| **Expected outputs** | RMSD/RMSF/contact/H-bond plots per ligand; optional fingerprint matrices |
| **Validation checks** | Output plots/CSVs exist; no NaN in RMSD arrays |

---

## 5. Orchestration Protocol

Step-by-step for an orchestrator agent managing the full pipeline:

### Step 1: Initialize Session

```bash
source ./scripts/setenv.sh
```

- Locate workspace: `find_workspace_root` (see `scripts/commands/common.sh`)
- Load config: `scripts/infra/config_loader.sh --config config.ini`
- Create handoffs directory: `mkdir -p .handoffs`

### Step 2: Load or Resume State

```bash
# Check for latest handoff
LATEST=$(ls -t .handoffs/*.json 2>/dev/null | head -1)
```

- If `LATEST` exists: parse `stage` + `status` fields → determine resume point
- If no handoffs: start from `input_prep`
- For resume: load `orchestrator-resume` skill @ `.opencode/skills/orchestrator-resume/SKILL.md`
- Invoke: `scripts/commands/orchestrator-resume.sh --config config.ini`

### Step 3: Determine Current Stage

```python
# Decision logic (pseudo-code)
def next_stage(handoff):
    if handoff.status in ("complete",):
        if checker_validate(handoff.stage) == "pass":
            return TRANSITIONS[handoff.stage]  # advance
        else:
            return "debug"
    elif handoff.status == "failed":
        return "debug"
    elif handoff.status == "needs_review":
        return "human_review"
    else:
        return handoff.stage  # retry or continue
```

### Step 4: Load Skill and Invoke Command

```bash
# Load appropriate skill based on stage
# Skill paths by stage:
# input_prep       → .opencode/skills/status/SKILL.md
# receptor_*       → .opencode/skills/rec-ensemble/SKILL.md
# docking          → .opencode/skills/dock-run/SKILL.md
# complex_setup    → .opencode/skills/com-setup/SKILL.md
# complex_md       → .opencode/skills/com-md/SKILL.md
# mmpbsa           → .opencode/skills/com-mmpbsa/SKILL.md
# analysis         → .opencode/skills/com-analyze/SKILL.md

# Invoke command (example for docking):
scripts/commands/dock-run.sh --config config.ini
```

### Step 5: Capture Outputs and Update HandoffRecord

```bash
# Check handoff written by command script
check_handoff_result "docking"   # uses scripts/commands/common.sh::check_handoff_result()

# Returns:
#   0 → success
#   1 → failure/blocked
#   2 → needs_review
```

### Step 6: Run Checker-Validate

```bash
scripts/commands/checker-validate.sh --config config.ini --stage docking
```

- Load skill: `.opencode/skills/checker-validate/SKILL.md`
- On pass → update HandoffRecord `next_action` → advance to next stage
- On warn → present to human; await approval
- On fail → proceed to debugger-diagnose

### Step 7: Handle Failure (if needed)

```bash
scripts/commands/debugger-diagnose.sh --config config.ini --stage docking
```

- Load skill: `.opencode/skills/debugger-diagnose/SKILL.md`
- Apply recommended fix
- Retry stage (max 2 retries)
- If still failing: write `status=blocked` HandoffRecord; escalate to human

### Step 8: Advance State or Complete

```bash
# Write updated HandoffRecord with next stage
# Repeat Steps 3–7 for each stage until analysis completes

# On workflow completion:
# Write .handoffs/workflow_complete.json with status=complete
# Generate summary from all stage HandoffRecords
```

---

## 6. All Skill File Paths (Quick Reference)

| Skill | Path |
|-------|------|
| rec-ensemble | `.opencode/skills/rec-ensemble/SKILL.md` |
| dock-run | `.opencode/skills/dock-run/SKILL.md` |
| com-setup | `.opencode/skills/com-setup/SKILL.md` |
| com-md | `.opencode/skills/com-md/SKILL.md` |
| com-mmpbsa | `.opencode/skills/com-mmpbsa/SKILL.md` |
| com-analyze | `.opencode/skills/com-analyze/SKILL.md` |
| checker-validate | `.opencode/skills/checker-validate/SKILL.md` |
| debugger-diagnose | `.opencode/skills/debugger-diagnose/SKILL.md` |
| orchestrator-resume | `.opencode/skills/orchestrator-resume/SKILL.md` |
| status | `.opencode/skills/status/SKILL.md` |

## 7. All Command Script Paths (Quick Reference)

| Command | Script |
|---------|--------|
| `/rec-ensemble` | `scripts/commands/rec-ensemble.sh` |
| `/dock-run` | `scripts/commands/dock-run.sh` |
| `/com-setup` | `scripts/commands/com-setup.sh` |
| `/com-md` | `scripts/commands/com-md.sh` |
| `/com-mmpbsa` | `scripts/commands/com-mmpbsa.sh` |
| `/com-analyze` | `scripts/commands/com-analyze.sh` |
| `/checker-validate` | `scripts/commands/checker-validate.sh` |
| `/debugger-diagnose` | `scripts/commands/debugger-diagnose.sh` |
| `/orchestrator-resume` | `scripts/commands/orchestrator-resume.sh` |
| `/status` | `scripts/commands/status.sh` |

**Shared utilities:** `scripts/commands/common.sh` (sourced by all above).

---

## 8. Known Pitfalls (Agent Awareness)

| Issue | Stage | Detection | Mitigation |
|-------|-------|-----------|------------|
| Force field incompatibility | complex_setup | GROMACS fatal error in log | Match FF: AMBER protein + AMBER ligand; CHARMM36m + CGenFF |
| Missing hydrogen atoms | receptor_prep | GROMACS warnings; bad H-bond counts | Run `pdb2pqr` / `gmx pdb2gmx` with correct protonation |
| RMSD instability | complex_md | RMSD > 3Å threshold | Check `complex_setup` topology; verify periodic boundary conditions |
| MMPBSA topology mismatch | mmpbsa | gmx_MMPBSA fatal error | AMBER topology must match GROMACS `.tpr`; verify FF branch consistency |
| Context window overflow | orchestrator | (internal) | Use file-based HandoffRecord; load only current-stage skill |

---

*Document version: 1.0*
*Last updated: 2026-04-19*
*For human workflow reference: see `WORKFLOW.md`*
*For agent role overview: see `AGENTS.md`*
