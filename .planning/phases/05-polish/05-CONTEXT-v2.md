# Phase 5: Polish - Replanning Context (v2)

**Gathered:** 2026-04-19
**Status:** Replanning required — Phase 5 execution damaged SKILL.md format
**Supersedes:** 05-CONTEXT.md (v1 decisions still apply unless overridden below)

---

<domain>
## Phase Boundary

Same as v1: Finalize all documentation (README, WORKFLOW, AGENTS, GUIDE) and perform end-to-end validation. Ligand preparation (SCRIPT-02) deferred to v2.

**Critical change:** Phase 5 plans 05-02 and 05-03 executed incorrectly and must be reverted/redone. Plans 05-01, 05-04, 05-05, 05-06 are potentially acceptable but need review against the corrected skill format.

</domain>

<what_went_wrong>
## What Phase 5 Execution Broke

### SKILL.md Format Destruction (Plan 05-03)

Plan 05-03 ("Audit and standardize all 10 SKILL.md files") **stripped the established YAML frontmatter format** from all 10 skills and replaced it with a flat markdown structure.

**Original format (origin/main) — MUST BE RESTORED:**
```yaml
---
name: rec-ensemble
description: Use when preparing receptor ensembles from a receptor PDB...
license: MIT
compatibility: Requires gnina, gromacs 2022+, python 3.10+
metadata:
  author: autoEnsmblDockMD
  version: "1.0"
  agent: runner
  stage: receptor_cluster
---

# Receptor Ensemble Generation

This skill orchestrates receptor preparation...

## When to use this skill
- ...

## Prerequisites
- ...

## Usage
Command: `scripts/commands/rec-ensemble.sh --config config.ini`
Agent dispatch: `python -m scripts.agents --agent runner --input handoff.json`

## Parameters
| Parameter | Config Key | CLI Flag | Default | Description |
|-----------|------------|----------|---------|-------------|
| ... | ... | ... | ... | ... |

## Expected Output
- ...

## Troubleshooting
- ...
```

**What 05-03 replaced it with (BROKEN — do not use):**
```markdown
# Skill: rec-ensemble
**Stage:** receptor_cluster
**Agent:** runner

## Capability
...
## Parameters  (lost CLI Flag + Default columns)
## Scripts
## Success Criteria
## Usage Example
## Workflow
```

**Specific losses:**
1. YAML frontmatter removed — machine-parseable metadata gone (name, description, license, compatibility, metadata block)
2. "When to use this skill" section removed — critical for agent decision-making
3. "Prerequisites" section removed — agents need to know pre-conditions
4. Parameters table lost `CLI Flag` and `Default` columns — agents need these for command construction
5. "Expected Output" section replaced with vague "Success Criteria"
6. "Troubleshooting" section demoted to inline text

### AGENTS.md Rewrite (Plan 05-02)

AGENTS.md was rewritten from a requirements-style doc to an agent-type overview. The new structure (organized by agent type with skill cross-references, command mapping table, safety constraints) is arguably an improvement but needs review against the restored skill format.

### Commits to revert (05-03 skill damage)
- `a8e7c1a` docs(05-03): define standard skill metadata template
- `10d28b9` docs(05-03): standardize metadata across remaining skill files

### Plans that executed and may be acceptable
- 05-01: WORKFLOW.md rewrite — likely fine, review needed
- 05-04: README.md — likely fine, review needed
- 05-05: docs/GUIDE.md Part 1 — likely fine, review needed
- 05-06: docs/GUIDE.md Part 2 — likely fine, review needed

### Plan that was in progress (checkpoint)
- 05-07: Validation + human review — abandon current checkpoint, redo after fixes

</what_went_wrong>

<decisions>
## Implementation Decisions (carries forward from v1 + additions)

### SKILL.md Format — LOCKED
- **YAML frontmatter is mandatory** — name, description, license, compatibility, metadata (author, version, agent, stage)
- **Preserve ALL original sections:** "When to use", "Prerequisites", "Usage", "Parameters" (with CLI Flag + Default columns), "Expected Output", "Troubleshooting"
- **Allowed additions only:** If new sections add value (e.g. Scripts table, Workflow steps), they may be APPENDED to the existing structure. Never remove or replace existing sections.
- Format: YAML frontmatter + Markdown body (hybrid, as specified in v1 context)
- The origin/main versions of all 10 SKILL.md files are the baseline truth

### Agent-Targeted Documentation (DOC-02)
- Agent-optimized documentation may live in SKILL.md files (expanded) OR in separate on-demand docs
- Agent docs may or may not be the same files as human-facing docs — optimize for agent consumption
- Key requirement: agents must be able to load documentation at runtime with parseable metadata
- Consider whether agents need more than what SKILLs currently provide (e.g. detailed stage workflows, decision trees, output interpretation)
- If separate agent docs are needed, they could live under `.opencode/docs/` or `docs/agent/` — planner's discretion

### README Structure & Audience (unchanged from v1)
- Quick start first, full pipeline walkthrough, human-optimized primary audience
- Linear narrative flow

### AGENTS.md (review needed)
- The restructured version (agent-type organization, skill cross-refs) may be kept if it works with restored skills
- Must cross-reference correct SKILL.md format/paths
- Experimental status clearly marked

### End-to-End Validation (unchanged from v1)
- Structure correct + values acceptable
- Test data from `work/input`

</decisions>

<revert_plan>
## Revert Strategy

Before replanning, the following must happen:

1. **Revert 05-03 commits** to restore all 10 SKILL.md files to origin/main state:
   ```bash
   git revert --no-commit 10d28b9  # standardize metadata across remaining skills
   git revert --no-commit a8e7c1a  # define standard skill metadata template
   git commit -m "revert(05-03): restore original SKILL.md YAML frontmatter format"
   ```

2. **Review 05-02 (AGENTS.md)** — keep if compatible with restored skills, revert if not

3. **Review 05-01, 05-04, 05-05, 05-06** — keep if acceptable, flag issues

4. **Delete 05-03-SUMMARY.md** and any other invalidated summaries

5. **Replan remaining work** based on what survived vs what needs redo

</revert_plan>

<specifics>
## Specific Guidance for Replanner

- The skill format from Phase 4 (origin/main) was carefully designed. Do NOT "standardize" by flattening it.
- Any skill improvements must ADD to the existing format, not replace sections.
- Agent documentation is a first-class deliverable (DOC-02), not an afterthought. Consider whether skills alone are sufficient or if agents need richer on-demand docs.
- Human docs (README, GUIDE, WORKFLOW) and agent docs serve different audiences — they may share content but the format/structure should be optimized for each audience.
- Plans that touch SKILL.md files must explicitly reference the origin/main format as the baseline.

</specifics>

<deferred>
## Deferred Ideas (unchanged from v1)

- SCRIPT-02 (ligand preparation automation) — Phase v2
- API documentation or interactive skill explorer — future enhancement
- Auto-generation of agent docs from code annotations — future automation

</deferred>

---

*Phase: 05-polish*
*Replanning context gathered: 2026-04-19*
*Reason: Phase 5 execution broke SKILL.md format, needs targeted revert + replan*
