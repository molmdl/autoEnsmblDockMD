# 05-07 Structural Validation Report

Date: 2026-04-19 (UTC)
Plan: 05-07

## 1) File Existence Check

### Core docs
- ✅ `README.md`
- ✅ `WORKFLOW.md`
- ✅ `AGENTS.md`
- ✅ `docs/GUIDE.md`
- ❌ `EXPERIMENTAL.md` (missing)

### Skill docs (10 required)
- ✅ `.opencode/skills/rec-ensemble/SKILL.md`
- ✅ `.opencode/skills/dock-run/SKILL.md`
- ✅ `.opencode/skills/com-setup/SKILL.md`
- ✅ `.opencode/skills/com-md/SKILL.md`
- ✅ `.opencode/skills/com-mmpbsa/SKILL.md`
- ✅ `.opencode/skills/com-analyze/SKILL.md`
- ✅ `.opencode/skills/checker-validate/SKILL.md`
- ✅ `.opencode/skills/debugger-diagnose/SKILL.md`
- ✅ `.opencode/skills/orchestrator-resume/SKILL.md`
- ✅ `.opencode/skills/status/SKILL.md`

Result: **FAIL** (1 missing required file)

## 2) Cross-reference Validation

### README references
- ✅ `WORKFLOW.md` referenced and exists
- ✅ `docs/GUIDE.md` referenced and exists
- ✅ `AGENTS.md` referenced and exists

### AGENTS skill references
- ✅ All 10 referenced `.opencode/skills/*/SKILL.md` paths exist

### WORKFLOW script references
- ✅ All referenced script paths resolve on disk
- Checked references under `scripts/rec/`, `scripts/dock/`, `scripts/com/`, `scripts/infra/`, `scripts/commands/`

### GUIDE references
- ✅ `WORKFLOW.md` referenced and exists
- ✅ `scripts/config.ini.template` referenced and exists

Result: **PASS**

## 3) Consistency Checks

### Mode A/B consistency across README, WORKFLOW, GUIDE
- ✅ Mode A and Mode B are documented in all three files
- ✅ Semantics consistent (A=targeted/test reference-pocket AMBER-oriented; B=blind CHARMM-oriented)

### Stage naming consistency
- ✅ All docs consistently cover Stage 0–6
- ✅ Stage concepts align: Input preparation, Receptor ensemble, Docking, Complex setup, MD simulation, MM/PBSA, Analysis

### Script path consistency: WORKFLOW vs SKILL docs
- ✅ Script paths listed in SKILL docs exist on disk
- ✅ Stage script paths referenced in SKILL docs are represented in WORKFLOW stage sections

### Internal terminology mismatch detected
- ⚠️ `AGENTS.md` “File-Based Handoff Pattern” cites workspace `com_md/` while workflow/workspace docs use `com/`

Result: **WARN** (1 non-blocking consistency issue)

## 4) Balance Check (line counts)

### Human-facing docs
- `README.md`: 211 lines
- `WORKFLOW.md`: 255 lines
- `docs/GUIDE.md`: 633 lines
- **Total human docs**: 1099 lines

### Agent-facing docs
- `AGENTS.md`: 134 lines
- 10x `SKILL.md`: 415 lines total
- **Total agent docs**: 549 lines

Human:Agent ratio ≈ **2.00:1**

Result: **PASS** (both audiences covered with substantial depth)

## 5) SKILL.md Structure Consistency

Required sections in each of 10 files:
- `## Capability`
- `## Parameters`
- `## Success Criteria`
- `## Usage Example`

Validation:
- ✅ 40/40 required section headers found (10 files × 4 headers)

Result: **PASS**

## Overall Summary

- File existence: **FAIL** (missing `EXPERIMENTAL.md`)
- Cross-references: **PASS**
- Consistency: **WARN** (`com_md/` vs `com/` directory naming in AGENTS)
- Human/agent balance: **PASS**
- SKILL structure consistency: **PASS**

## Issues Found (Unresolved)

1. Missing required file: `EXPERIMENTAL.md`
2. Documentation terminology mismatch: `AGENTS.md` references `com_md/` while workflow docs use `com/`

Per plan instruction, issues are reported and **not fixed** in this task.
