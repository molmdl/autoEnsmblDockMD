# 05-10 Structural Validation Report

Date: 2026-04-19
Plan: 05-10

## Scope

- 10 skill definition files under `.opencode/skills/*/SKILL.md`
- Structural checks:
  1. YAML frontmatter integrity and required keys
  2. Required section completeness (including Parameters table with `CLI Flag` and `Default` columns)
  3. Absence of 05-03 flat-format artifacts (`## Capability`)

## Task 1 — SKILL.md Structural Validation

### Check Definitions

1. **YAML frontmatter check**
   - Must start with `---`
   - Must contain closing `---`
   - Must include: `name`, `description`, `license`, `compatibility`, `metadata`
   - `metadata` must include: `author`, `version`, `agent`, `stage`

2. **Required sections check**
   - `When to use` or `When to use this skill`
   - `Prerequisites`
   - `Usage`
   - `Parameters` with table columns containing `CLI Flag` and `Default`
   - `Expected Output`
   - `Troubleshooting`

3. **No 05-03 artifact check**
   - Must not contain top-level `## Capability`

### Results by Skill

| Skill | YAML Frontmatter | Required Sections | No 05-03 Artifacts | Result | Notes |
|---|---|---|---|---|---|
| `rec-ensemble` | PASS | PASS | PASS | PASS | — |
| `dock-run` | PASS | PASS | PASS | PASS | — |
| `com-setup` | PASS | PASS | PASS | PASS | — |
| `com-md` | PASS | PASS | PASS | PASS | — |
| `com-mmpbsa` | PASS | PASS | PASS | PASS | — |
| `com-analyze` | PASS | PASS | PASS | PASS | — |
| `checker-validate` | PASS | PASS | PASS | PASS | Added missing `## Parameters` section/table during validation remediation |
| `debugger-diagnose` | PASS | PASS | PASS | PASS | Added missing `## Parameters` section/table during validation remediation |
| `orchestrator-resume` | PASS | PASS | PASS | PASS | Added missing `## Parameters` section/table during validation remediation |
| `status` | PASS | PASS | PASS | PASS | Added missing `## Parameters` section/table during validation remediation |

### Task 1 Summary

- **Skills validated:** 10/10
- **All required checks passed:** YES
- **Remediation required:** YES (4 skills were missing `Parameters` sections and were corrected)

---

## Task 2 — Cross-Reference Validation

_To be appended in Task 2._
