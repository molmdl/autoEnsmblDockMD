# 003 Skill Audit (Dry Run)

## Scope

- Reviewed all 10 skills under `.opencode/skills/aedmd-*/SKILL.md`.
- Cross-checked against:
  - `AGENTS.md` skill contract and slash-command table
  - `scripts/commands/aedmd-*.sh` wrappers
  - `scripts/commands/common.sh` dispatch + stage map
  - `scripts/config.ini.template`
- No scripts executed; static review only.

---

## Inventory Reviewed

1. `aedmd-rec-ensemble`
2. `aedmd-dock-run`
3. `aedmd-com-setup`
4. `aedmd-com-md`
5. `aedmd-com-mmpbsa`
6. `aedmd-com-analyze`
7. `aedmd-checker-validate`
8. `aedmd-debugger-diagnose`
9. `aedmd-orchestrator-resume`
10. `aedmd-status`

---

## Frontmatter Contract Validation

All 10 skills include required frontmatter keys:

- `name`
- `description`
- `license`
- `compatibility`
- `metadata`

Name-to-directory consistency is correct across all 10 skills.

---

## Documentation Completeness Check

All 10 skills include required body sections:

- When to use this skill
- Prerequisites
- Usage
- Parameters (table)
- Expected Output
- Troubleshooting

Completeness is structurally good; content quality issues are listed below.

---

## Findings (Severity-Categorized)

| Skill | Category | Severity | Evidence (file:line) | Finding | Recommendation |
|---|---|---|---|---|---|
| aedmd-dock-run | Targeted mode parameter coverage | **critical** | `.opencode/skills/aedmd-dock-run/SKILL.md:32-41` | Parameters table omits explicit `docking.reference_ligand` and `docking.autobox_ligand` rows, despite targeted mode requiring these semantics. | Add both keys with defaults and examples; include mode-specific requirement note. |
| aedmd-dock-run | Targeted semantics clarity | warning | `.opencode/skills/aedmd-dock-run/SKILL.md:55`; `scripts/config.ini.template:140-141`; `scripts/dock/2_gnina.sh:15-16,141,155` | Skill does not clearly explain difference between `reference_ligand` (reference file) and `autobox_ligand` (token/path selecting box source). | Add short comparison subsection with targeted examples. |
| aedmd-checker-validate | Metadata stage/token alignment | warning | `.opencode/skills/aedmd-checker-validate/SKILL.md:10`; `scripts/commands/aedmd-checker-validate.sh:13`; `scripts/commands/common.sh:35` | `metadata.stage` is `quality_validation`, but wrapper dispatches `checker_validate`. | Harmonize stage naming in skill metadata or document canonical-vs-wrapper alias policy. |
| aedmd-debugger-diagnose | Metadata stage/token alignment | warning | `.opencode/skills/aedmd-debugger-diagnose/SKILL.md:10`; `scripts/commands/aedmd-debugger-diagnose.sh:13`; `scripts/commands/common.sh:36` | `metadata.stage` is `failure_diagnosis`, wrapper uses `debugger_diagnose`. | Align metadata stage or document alias mapping explicitly. |
| aedmd-orchestrator-resume | Metadata stage/token alignment | warning | `.opencode/skills/aedmd-orchestrator-resume/SKILL.md:10`; `scripts/commands/aedmd-orchestrator-resume.sh:13` | `metadata.stage` is `workflow_resume`, wrapper dispatches `orchestrator_resume`. | Align naming or add explicit alias section in skill. |
| aedmd-status | Metadata agent mismatch | warning | `.opencode/skills/aedmd-status/SKILL.md:9`; `AGENTS.md:25-35` | Status skill uses `metadata.agent: none`, while AGENTS groups it under orchestrator skill set. | Prefer `metadata.agent: orchestrator` or document `none` as intentional special case in AGENTS contract. |
| checker/debugger/orchestrator/status skills | Expected output handoff path specificity | warning | `aedmd-checker-validate/SKILL.md:36-39`; `aedmd-debugger-diagnose/SKILL.md:36-39`; `aedmd-orchestrator-resume/SKILL.md:37-40`; `aedmd-status/SKILL.md:37-40` | Expected Output sections do not consistently state handoff file path convention (`.handoffs/{stage}.json`). | Add explicit handoff path for each command where applicable; for status clarify no handoff file generated. |
| aedmd-checker-validate | Config key mapping accuracy | warning | `.opencode/skills/aedmd-checker-validate/SKILL.md:33`; `scripts/config.ini.template` (no `general.config`) | Uses `general.config` key in parameters table; this key is not present in template and `--config` is wrapper-level CLI argument, not INI value. | Replace with “N/A (wrapper flag)” or valid config section/keys used by checker logic. |
| aedmd-debugger-diagnose | Config key mapping accuracy | warning | `.opencode/skills/aedmd-debugger-diagnose/SKILL.md:33`; `scripts/config.ini.template` | Same `general.config` mismatch as checker. | Same fix as checker. |
| aedmd-orchestrator-resume | Config key mapping accuracy | warning | `.opencode/skills/aedmd-orchestrator-resume/SKILL.md:33`; `scripts/config.ini.template` | Same `general.config` mismatch. | Same fix: mark wrapper CLI arg as external to INI schema. |
| aedmd-rec-ensemble | Handoff status vocabulary not documented | info | `.opencode/skills/aedmd-rec-ensemble/SKILL.md:42-50`; `AGENTS.md:93-104` | Skill does not mention expected handoff status values (`success/needs_review/failure/blocked`). | Add short “Handoff statuses” note linked to AGENTS table. |
| aedmd-dock-run | Handoff status vocabulary not documented | info | `.opencode/skills/aedmd-dock-run/SKILL.md:42-55`; `AGENTS.md:93-104` | Same gap as above. | Add status vocabulary note. |
| aedmd-com-setup | Handoff status vocabulary not documented | info | `.opencode/skills/aedmd-com-setup/SKILL.md:43-51`; `AGENTS.md:93-104` | Same gap as above. | Add status vocabulary note. |
| aedmd-com-md | Handoff status vocabulary not documented | info | `.opencode/skills/aedmd-com-md/SKILL.md:42-55`; `AGENTS.md:93-104` | Same gap as above. | Add status vocabulary note. |
| aedmd-com-mmpbsa | Handoff status vocabulary not documented | info | `.opencode/skills/aedmd-com-mmpbsa/SKILL.md:43-56`; `AGENTS.md:93-104` | Same gap as above. | Add status vocabulary note. |
| aedmd-com-analyze | Handoff status vocabulary not documented | info | `.opencode/skills/aedmd-com-analyze/SKILL.md:43-51`; `AGENTS.md:93-104` | Same gap as above. | Add status vocabulary note. |

---

## Code-Skill Alignment Matrix

| Skill | Wrapper exists | Wrapper dispatch matches intent | Stage token in `common.sh` map | Result |
|---|---|---|---|---|
| aedmd-rec-ensemble | yes | `runner/receptor_prep` | yes (`receptor_prep`) | pass |
| aedmd-dock-run | yes | `runner/docking_run` | yes (`docking_run`) | pass |
| aedmd-com-setup | yes | `runner/complex_prep` | yes (`complex_prep`) | pass |
| aedmd-com-md | yes | `runner/complex_md` | yes (`complex_md`) | pass |
| aedmd-com-mmpbsa | yes | `runner/complex_mmpbsa` | yes (`complex_mmpbsa`) | pass |
| aedmd-com-analyze | yes | `analyzer/complex_analysis` | yes (`complex_analysis`) | pass |
| aedmd-checker-validate | yes | `checker/checker_validate` | yes (`checker_validate`) | pass (metadata naming drift) |
| aedmd-debugger-diagnose | yes | `debugger/debugger_diagnose` | yes (`debugger_diagnose`) | pass (metadata naming drift) |
| aedmd-orchestrator-resume | yes | `orchestrator/orchestrator_resume` | no direct map entry, but dispatch does not require script for orchestrator | pass (document special behavior) |
| aedmd-status | yes | no dispatch_agent call (status-only local wrapper) | N/A | pass (special-case command) |

---

## Targeted Docking Checks (Required)

| Check | Evidence | Assessment |
|---|---|---|
| `mode=targeted` documented | `aedmd-dock-run/SKILL.md:15,35` | ✅ present |
| `reference_ligand` documented | Mentioned in prose/troubleshooting (`:19`, `:55`) but not parameter row | ⚠ partial |
| `autobox_ligand` documented | Not in parameter table; only implied in troubleshooting (`:55`) | ⚠ partial |
| Difference between `reference_ligand` and `autobox_ligand` explained | No direct explanation | ❌ missing |

---

## Summary Counts

- Skills reviewed: **10/10**
- Issues found:
  - **Critical:** 1
  - **Warning:** 9
  - **Info:** 6

Top priority before first user run: fix targeted docking parameter documentation gap in `aedmd-dock-run` and normalize metadata stage naming drift for non-runner skills.

---

## Dry-Run Compliance

No pipeline scripts were executed. Findings are based entirely on static file inspection.
