# 003 Automation Opportunities (Hooks/Plugins) — Token Savings Focus

## Scope

This document identifies automation candidates that reduce repeated context loading and repetitive reasoning during workflow support.

- Mode: dry-run analysis only
- No script execution performed
- Focus: hook/plugin/agent opportunities with estimated token savings

---

## Executive Ranking (Highest Estimated Savings First)

| Rank | Opportunity | Automation type | Est. token savings / run | Complexity | Priority |
|---:|---|---|---:|---|---|
| 1 | Preflight validation bundle | Hook + plugin | 2,000–4,000 | Medium | High |
| 2 | Workspace init + input copy blueprint | Plugin | 1,500–3,000 | Low | High |
| 3 | Stage-schema-aware handoff inspector | Hook | 1,200–2,500 | Medium | High |
| 4 | Conversion cache manager (SDF/GRO/MOL2) | Plugin | 1,000–2,000 | Medium | High |
| 5 | MM/PBSA group-ID consistency checker | Hook | 900–1,800 | Medium | High |
| 6 | Slurm state monitor + summarizer | Background agent/hook | 800–1,600 | Medium | Medium |
| 7 | Error-signature diagnosis dispatcher | Hook + debugger integration | 700–1,500 | High | Medium |
| 8 | Config-derivation assistant (MDP/topology/index defaults) | Plugin | 600–1,400 | High | Medium |

---

## 1) Repetitive Validation Patterns

### Current implementation (evidence)

- `scripts/dock/0_gro2mol2.sh:65-73,79-93` → repeated required config/file checks.
- `scripts/dock/0_sdf2gro.sh:67-73,87-90` → similar file/pattern checks.
- `scripts/com/2_trj4mmpbsa.sh:99-110,275-278,297-300` → chunk and group-id validation.
- `scripts/commands/common.sh:46-61,192-234` → stage mapping + handoff status checks.

### Token-cost pattern

Agents repeatedly load script docs/config and reason through the same validation logic each run.

### Proposed automation

- **Preflight validation hook** that reads `config.ini` + expected workspace files and emits pass/fail JSON once.
- Reused by runner/checker/debugger wrappers before task logic.

### Savings estimate

- **2,000–4,000 tokens/run** (avoid repeating large config/validation context interpretation).

### Complexity / priority

- Complexity: **Medium**
- Priority: **High**

---

## 2) Workspace Setup Pattern Automation (Required by user clarification)

### Current pattern

- Inputs originate in `work/input/` and should be copied to isolated run workspace (`work/test/` or `work/run_YYYY-MM-DD/`).
- This is documented, but setup remains manual and repeated.

### Current implementation references

- `AGENTS.md:156-157` notes copy-to-new-workspace guidance.
- `WORKFLOW.md:49-62` describes expected workspace structure.
- `scripts/config.ini.template:16` defaults `workdir=./work/test`.

### Proposed automation

- **workspace-init plugin**:
  1. Create `work/run_DATE/` skeleton.
  2. Copy selected files from `work/input/` with manifest.
  3. Generate `config.ini` from template with workspace-specific paths.
  4. Validate required files and emit readiness report.

### Savings estimate

- **1,500–3,000 tokens/run** by eliminating repeated setup instructions, path reasoning, and manual validation loops.

### Complexity / priority

- Complexity: **Low**
- Priority: **High**

---

## 3) Handoff Status Parsing + Stage Contract Hook

### Current implementation (evidence)

- `scripts/commands/common.sh:192-234` parses statuses and emits warnings/errors.
- Handoff status contract in `AGENTS.md:93-104`.

### Token-cost pattern

In analysis/debug sessions, agents repeatedly inspect `.handoffs/*.json` and map statuses to user guidance.

### Proposed automation

- **Handoff inspector hook** with normalized output:
  - last stage
  - status
  - blocking errors
  - actionable next command

### Savings estimate

- **1,200–2,500 tokens/run** in checkpoint/resume/debug-heavy flows.

### Complexity / priority

- Complexity: **Medium**
- Priority: **High**

---

## 4) File Transformation Pipeline Caching

### Current implementation (evidence)

- `scripts/dock/0_sdf2gro.sh` for SDF→GRO conversion.
- `scripts/dock/0_gro2mol2.sh` + `0_gro_itp_to_mol2.py` for GRO/ITP→MOL2.

### Token-cost pattern

Agents repeatedly re-check conversion requirements and output expectations for unchanged inputs.

### Proposed automation

- **File-transform plugin with cache manifest** (hash input + config slice + tool version):
  - skip unchanged conversions
  - expose deterministic conversion ledger

### Savings estimate

- **1,000–2,000 tokens/run** and less repeated explanation around conversion steps.

### Complexity / priority

- Complexity: **Medium**
- Priority: **High**

---

## 5) MM/PBSA Group-ID and Topology Consistency Hook

### Current implementation (evidence)

- `scripts/com/2_trj4mmpbsa.sh:172-238` resolves and writes `mmpbsa_groups.dat`.
- `scripts/com/2_mmpbsa.sh` consumes and validates group IDs/topology behavior.

### Token-cost pattern

MM/PBSA failures trigger repeated group-ID reasoning and index-file inspection.

### Proposed automation

- **Group consistency hook**:
  - validate `index.ndx` group names/ids
  - ensure `mmpbsa_groups.dat` coherence
  - verify selected topology path mode

### Savings estimate

- **900–1,800 tokens/run** during MM/PBSA prep and debugging.

### Complexity / priority

- Complexity: **Medium**
- Priority: **High**

---

## 6) Status Monitoring Workflow (Slurm + Artifacts)

### Current implementation (evidence)

- Async behavior noted in `WORKFLOW.md:75-87`.
- Slurm submission in `scripts/com/2_sub_mmpbsa.sh:143-155`.

### Token-cost pattern

Agents repeatedly explain/check `squeue/sacct` and infer completion readiness.

### Proposed automation

- **Background monitoring agent/hook**:
  - polls scheduler + artifact markers
  - emits concise stage progress summary
  - flags stalled/failed jobs with direct links

### Savings estimate

- **800–1,600 tokens/run** in long asynchronous runs.

### Complexity / priority

- Complexity: **Medium**
- Priority: **Medium**

---

## 7) Error Diagnosis Signature Router

### Current implementation (evidence)

- `scripts/infra/monitor.py` has rich error/warning/completion pattern registry.
- Debugger skill exists but diagnostics are still session-context heavy.

### Token-cost pattern

Repeated human/agent triage of known error signatures burns tokens.

### Proposed automation

- **Debugger hook** that maps known signatures to remediation templates:
  - topology mismatch
  - missing binary/dependency
  - scheduler resource mismatch
  - force-field incompatibility patterns

### Savings estimate

- **700–1,500 tokens/run** in failure scenarios.

### Complexity / priority

- Complexity: **High**
- Priority: **Medium**

---

## 8) Config Derivation Assistant

### Current implementation (evidence)

- Rich template comments in `scripts/config.ini.template`.
- Multiple stages derive defaults from other sections.

### Token-cost pattern

Agents repeatedly reason over cross-section dependencies and default propagation.

### Proposed automation

- **Config-derivation plugin** that outputs:
  - resolved effective config
  - missing/ambiguous keys
  - mode-specific recommendations (targeted AMBER, blind CHARMM)

### Savings estimate

- **600–1,400 tokens/run** during setup and troubleshooting.

### Complexity / priority

- Complexity: **High**
- Priority: **Medium**

---

## Cross-Cutting Hook/Plugin Architecture Suggestion

### Suggested integration points

| Lifecycle point | Hook/plugin |
|---|---|
| Before any wrapper dispatch | Preflight validation hook |
| Workspace creation | workspace-init plugin |
| After each stage handoff write | handoff inspector hook |
| Before MM/PBSA stage | group consistency hook |
| During async phases | scheduler monitor agent |
| On failure/blocked status | error-signature debugger hook |

### Why this saves tokens

These components produce concise machine-readable summaries, reducing the need for the agent to reload large docs/scripts repeatedly in each interaction.

---

## Implementation Roadmap (Minimal to Advanced)

1. **Phase A (quick wins):** workspace-init plugin + preflight validation hook.
2. **Phase B (mid):** handoff inspector + MM/PBSA group consistency hook.
3. **Phase C (advanced):** conversion cache + scheduler monitor + error-signature router.
4. **Phase D (optimization):** resolved-config derivation assistant with profile presets.

---

## Estimated Aggregate Savings

If top 5 opportunities are implemented, expected savings are approximately:

- **6,600–13,300 tokens per typical run-support cycle**

Actual savings will vary by run complexity and number of retries/checkpoints.

---

## Dry-Run Compliance Statement

This analysis was generated from static review of docs and source files only. No scripts were executed.
