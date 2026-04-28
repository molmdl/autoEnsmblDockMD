# 003 Targeted Docking Workflow Dry-Run Report

## 1) Executive Summary

### Confidence assessment

- **Workflow understanding confidence:** **High** for stage mapping and wrapper/skill dispatch chain.
- **Readiness for first actual run:** **Medium** (documentation and metadata alignment issues should be fixed first).

### Issue totals

| Severity | Count | Notes |
|---|---:|---|
| Critical | 1 | Targeted-docking parameter documentation gap in `aedmd-dock-run` skill |
| Warning | 9 | Metadata token drift + handoff/config documentation inconsistencies |
| Info | 6 | Handoff status vocabulary not repeated in most skills |

### Overall readiness statement

The codebase appears structurally ready for targeted workflow execution, but user-facing documentation has several precision gaps that can cause setup confusion (especially around `reference_ligand` vs `autobox_ligand`, and non-runner skill stage naming).

---

## 2) Workflow Analysis

### Targeted workflow summary (Mode A)

From `WORKFLOW.md`, targeted mode follows Stage 0 preflight and Stages 1–6:

1. Input preparation
2. Receptor ensemble generation
3. Docking (`mode=targeted`)
4. Complex setup (AMBER branch)
5. Production MD
6. MM/PBSA
7. Analysis

Detailed mapping is documented in:

- `.planning/quick/003-dry-run-targeted-docking-workflow-analys/003-WORKFLOW-MAPPING.md`

### Input → output flow (user perspective)

```text
work/input/*
  ├─ rec.pdb
  ├─ ref.pdb
  ├─ dzp/, ibp/
  └─ optional 2bxo.pdb
      ↓ copy into isolated workspace (work/test/ or work/run_DATE/)
config.ini + rec/ + dock/ + com/ + mdp/
      ↓
Stage 1 rec/* artifacts
      ↓
Stage 2 dock/* poses/reports
      ↓
Stage 3 com/* MD-ready systems (com.gro, sys.top, index.ndx)
      ↓
Stage 4 prod_*.xtc/prod_*.tpr
      ↓
Stage 5 mmpbsa_* outputs
      ↓
Stage 6 analysis outputs
```

### Critical dependencies/checkpoints

| Dependency | Why critical | Failure effect |
|---|---|---|
| `work/input/ref.pdb` copied to workspace | Needed for targeted autobox behavior | Stage 2 targeted run cannot box correctly |
| `[docking] mode=targeted` + `reference_ligand` | Selects targeted workflow branch | Docking semantics diverge from intended mode |
| Valid receptor+ligand topologies in Stage 3 | Required for MD prep integrity | downstream MD/MMPBSA invalid or blocked |
| `mmpbsa_groups.dat` generation/usage | Required group ID integrity | MM/PBSA may compute wrong groups |
| Workspace isolation pattern | Reproducibility and safety | input pollution, accidental overwrite |

---

## 3) Issues Found

### Critical issues (execution-readiness blocker for documentation)

| ID | Affected files | Description | Impact | Recommendation |
|---|---|---|---|---|
| C-01 | `.opencode/skills/aedmd-dock-run/SKILL.md:32-41` | Parameter table does not explicitly include `docking.reference_ligand` and `docking.autobox_ligand` for targeted mode. | Users may configure targeted mode incompletely or misinterpret autobox source behavior. | Add both keys to table, include examples and targeted-only requirement callout. |

### Warnings

| ID | Affected files | Description | Impact | Recommendation |
|---|---|---|---|---|
| W-01 | `aedmd-checker-validate/SKILL.md:10`, `scripts/commands/aedmd-checker-validate.sh:13` | Metadata stage (`quality_validation`) differs from wrapper token (`checker_validate`). | Traceability and tooling consistency risk for metadata consumers. | Harmonize names or define explicit alias policy in docs. |
| W-02 | `aedmd-debugger-diagnose/SKILL.md:10`, `scripts/commands/aedmd-debugger-diagnose.sh:13` | Metadata stage (`failure_diagnosis`) differs from wrapper token (`debugger_diagnose`). | Same as above. | Same as above. |
| W-03 | `aedmd-orchestrator-resume/SKILL.md:10`, `scripts/commands/aedmd-orchestrator-resume.sh:13` | Metadata stage (`workflow_resume`) differs from wrapper token (`orchestrator_resume`). | Same as above. | Same as above. |
| W-04 | `aedmd-status/SKILL.md:9`, `AGENTS.md:25-35` | `metadata.agent` is `none` while AGENTS positions status under orchestrator skills. | Minor role-model inconsistency. | Document status as intentional non-dispatch special-case or align metadata. |
| W-05 | `aedmd-checker-validate/SKILL.md:33` | Uses non-template config key `general.config` in parameter table. | Misleading config expectations for users. | Mark as wrapper CLI arg, not INI key. |
| W-06 | `aedmd-debugger-diagnose/SKILL.md:33` | Same `general.config` drift. | Same. | Same. |
| W-07 | `aedmd-orchestrator-resume/SKILL.md:33` | Same `general.config` drift. | Same. | Same. |
| W-08 | `aedmd-dock-run/SKILL.md:55`, `scripts/config.ini.template:140-141` | Difference between `reference_ligand` and `autobox_ligand` not clearly explained. | Targeted-mode setup confusion likely. | Add explicit comparison subsection. |
| W-09 | checker/debugger/orchestrator/status skill outputs | Handoff file conventions not consistently explicit in Expected Output sections. | Users may not know where to inspect state/results. | Add `.handoffs/{stage}.json` specifics where applicable. |

### Informational findings

| ID | Affected files | Description | Recommendation |
|---|---|---|---|
| I-01 | runner/analyzer skill docs (multiple) | Most do not restate handoff status values (`success`, `needs_review`, `failure`, `blocked`). | Add concise status table or pointer to AGENTS section. |
| I-02 | `AGENTS.md` | Handoff status behavior is documented well and matches `common.sh`. | Keep this as canonical status source. |
| I-03 | `scripts/commands/common.sh` | Stage alias fallback exists for compatibility. | Document alias usage in skills consuming legacy tooling. |

---

## 4) Missing or Unclear Items

| Topic | Current state | Impact | Clarification needed |
|---|---|---|---|
| `2bxo.pdb` purpose | Mentioned in `work/input/README.md` without workflow role | User uncertainty during setup | State whether it is alternate receptor, alignment reference, or validation control |
| Ligand-prep provenance for `dzp/` and `ibp/` | Already contains `.itp/.gro/.mol2/.top`, but generation workflow not explained | Hard to reproduce for new ligands | Add ligand-preparation provenance or link to external prep protocol |
| AMBER vs CHARMM selection guidance | Present in scattered comments, not as a concise decision guide | New users may choose wrong branch | Add explicit “mode selection matrix” section in docs |
| Receptor alignment reference behavior | `align_reference` exists in config, behavior nuanced in workflow docs | Confusion on when alignment runs/required | Add clear conditions and examples |
| Handoff JSON schema location in AGENTS | AGENTS mentions HandoffRecord concept but not field schema details | Harder for custom tooling integration | Link directly to `scripts/agents/schemas/handoff.py` with field summary |

---

## 5) Code Quality Observations

### Wrapper consistency

- Strong consistency for runner/analyzer/checker/debugger/orchestrator wrappers:
  - `ensure_env`
  - workspace resolution
  - `parse_flags`
  - `dispatch_agent`
  - `check_handoff_result`

### Error handling coverage

- `scripts/commands/common.sh` has robust stage-script resolution checks and explicit unknown-stage handling.
- `check_handoff_result` enforces status gating and clear exit codes.

### Configuration validation approach

- Stage scripts consistently use `require_config`, `require_file`, `require_dir` patterns.
- Template (`scripts/config.ini.template`) provides broad defaults and inline guidance.

### Logging and debugging support

- `scripts/infra/monitor.py` offers reusable pattern-based log diagnosis.
- Script logs and handoff JSON pattern support downstream checker/debugger usage.

---

## 6) Recommendations

### Priority fixes before first full workflow run

1. **Update `aedmd-dock-run` parameter documentation** for targeted mode (`reference_ligand`, `autobox_ligand`).
2. **Normalize or explicitly alias metadata stages** for checker/debugger/orchestrator skills.
3. **Fix config-key drift** (`general.config`) in checker/debugger/orchestrator parameter tables.

### Documentation improvements

4. Add a dedicated section: “`reference_ligand` vs `autobox_ligand`”.
5. Add a short decision table for AMBER vs CHARMM branch selection.
6. Clarify `2bxo.pdb` role in `work/input/README.md` and workflow docs.
7. Add explicit handoff JSON path and status behavior notes to all skills.

### Config template clarifications

8. Keep and emphasize workspace pattern example (`work/input/` → `work/test/` or `work/run_DATE/`).
9. Add one focused targeted-mode example block in config comments.

### Example walkthrough need

10. Provide a concise non-executing walkthrough of Mode A using sample files (copy map + config stubs + expected artifact locations).

---

## 7) Next Steps

### Suggested remediation order

1. Fix skill documentation critical/warning items.
2. Add missing clarification sections in AGENTS/WORKFLOW/work-input README docs.
3. Re-run a documentation-only consistency check (no execution).
4. Then perform first controlled execution in isolated workspace (`work/test/`).

### Pre-execution checklist (for actual run later)

- [ ] Inputs copied from `work/input/` to run workspace
- [ ] `config.ini` created from template and updated for targeted mode
- [ ] `docking.mode=targeted`
- [ ] `docking.reference_ligand` points to copied `ref.pdb`
- [ ] `complex.mode` and `dock2com.ff` aligned for AMBER branch
- [ ] MDP directories and topology paths validated
- [ ] Handoff/log directories expected and writable

### Validation approach for first test run

- Start with one-ligand/small trial settings.
- Confirm stage-by-stage handoff status transitions.
- Validate outputs at each stage boundary before scaling.

---

## References

- Workflow mapping artifact: `003-WORKFLOW-MAPPING.md`
- Skill audit artifact: `003-SKILL-AUDIT.md`
- Automation opportunities artifact: `003-AUTOMATION-OPPORTUNITIES.md`

---

## Dry-Run Compliance Statement

This report was produced via documentation and code inspection only. No pipeline scripts were executed.
