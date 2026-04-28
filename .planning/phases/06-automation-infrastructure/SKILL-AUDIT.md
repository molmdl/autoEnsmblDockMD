# Phase 6 Skill Audit: Superpowers Writing-Skills Alignment

**Date:** 2026-04-28  
**Scope:**
- `.opencode/skills/aedmd-workspace-init/SKILL.md`
- `.opencode/skills/aedmd-preflight/SKILL.md`
- `.opencode/skills/aedmd-handoff-inspect/SKILL.md`
- `.opencode/skills/aedmd-group-id-check/SKILL.md`
- `.opencode/skills/aedmd-conversion-cache/SKILL.md`

## Executive Summary

- **Compliance rate (critical checks):** 2/5 skills fully compliant at baseline.
- **Major gaps found:**
  - 3 skills had descriptions that did not start with "Use when...".
  - 3 skills described workflow behavior instead of discovery triggers/symptoms.
  - None of the 5 skills used a consistent **Overview / When to Use / Quick Reference / Common Mistakes** structure.
- **Recommended fixes:**
  1. Normalize frontmatter descriptions for CSO trigger-based discovery.
  2. Standardize section layout for scan speed and consistency.
  3. Add stronger keyword coverage (error/status/tool terms) for retrieval quality.

## Critical Best Practices Checklist

Reference criteria are adapted from:
- superpowers writing-skills: https://github.com/obra/superpowers/tree/main/skills/writing-skills
- Anthropic best practices companion in that skill package
- agentskills.io specification: https://agentskills.io/specification

### aedmd-workspace-init

#### YAML Frontmatter
- [x] Has `name`
- [x] Has `description`
- [x] Description starts with "Use when..."
- [~] Description mostly trigger-oriented but too generic
- [x] Third-person phrasing

#### Claude Search Optimization (CSO)
- [~] Trigger keywords present but sparse
- [x] Active, verb-oriented name
- [~] Trigger context could include more concrete symptoms
- [~] Description still partially implies workflow summary

#### Structure
- [ ] Explicit "Overview" heading
- [ ] Standard "When to Use" heading (title-case)
- [ ] Quick Reference section
- [ ] Implementation section (explicit)
- [ ] Common Mistakes section

#### Token Efficiency
- [x] Compact enough
- [x] No storytelling
- [x] No heavy redundant examples

### aedmd-preflight

#### YAML Frontmatter
- [x] Has `name`
- [x] Has `description`
- [x] Description starts with "Use when..."
- [x] Description is trigger-first
- [x] Third-person phrasing

#### Claude Search Optimization (CSO)
- [x] Good trigger terms (config/tools/inputs)
- [x] Name is active and specific
- [~] Could include stronger error symptom terms (missing section/key)
- [x] Description does not expose workflow details

#### Structure
- [ ] Explicit "Overview" heading
- [ ] Standard "When to Use" heading (title-case)
- [ ] Quick Reference section
- [ ] Implementation section (explicit)
- [ ] Common Mistakes section

#### Token Efficiency
- [x] Efficient length
- [x] Good density

### aedmd-handoff-inspect

#### YAML Frontmatter
- [x] Has `name`
- [x] Has `description`
- [ ] Description starts with "Use when..."
- [ ] Description is trigger-oriented (current text is workflow summary)
- [x] Third-person phrasing

#### Claude Search Optimization (CSO)
- [~] Some status keywords present
- [x] Name is clear and action-oriented
- [ ] Lacks concrete trigger/symptom language in description
- [ ] Description currently summarizes behavior

#### Structure
- [ ] Explicit "Overview" heading
- [ ] Standard "When to Use" heading (title-case)
- [ ] Quick Reference section
- [ ] Implementation section (explicit)
- [ ] Common Mistakes section

#### Token Efficiency
- [x] Efficient length

### aedmd-group-id-check

#### YAML Frontmatter
- [x] Has `name`
- [x] Has `description`
- [ ] Description starts with "Use when..."
- [ ] Description is trigger-oriented (current text states action)
- [x] Third-person phrasing

#### Claude Search Optimization (CSO)
- [x] Strong domain keywords (MM/PBSA, index.ndx)
- [x] Name is specific and active
- [~] Description should include mismatch symptom terms
- [ ] Description too workflow-centric

#### Structure
- [ ] Explicit "Overview" heading
- [ ] Standard "When to Use" heading (title-case)
- [ ] Quick Reference section
- [ ] Implementation section (explicit)
- [ ] Common Mistakes section

#### Token Efficiency
- [x] Compact and direct

### aedmd-conversion-cache

#### YAML Frontmatter
- [x] Has `name`
- [x] Has `description`
- [ ] Description starts with "Use when..."
- [ ] Description is trigger-oriented (currently function summary)
- [x] Third-person phrasing

#### Claude Search Optimization (CSO)
- [x] Relevant keywords (cache/staleness)
- [x] Name is explicit and discoverable
- [~] Could include cache miss/stale/recompute symptoms
- [ ] Description currently summarizes capability

#### Structure
- [ ] Explicit "Overview" heading
- [ ] Standard "When to Use" heading (title-case)
- [ ] Quick Reference section
- [ ] Implementation section (explicit)
- [ ] Common Mistakes section

#### Token Efficiency
- [x] Concise with low redundancy

## Per-Skill Findings

### aedmd-workspace-init
- **Compliance:** Strong metadata and practical operational content.
- **Gaps:** Missing standardized section headings and explicit common-mistakes layout.
- **Recommended fixes:** Add Overview/Quick Reference/Common Mistakes; enrich trigger keywords (`workspace exists`, `--force`, `work/input`).

### aedmd-preflight
- **Compliance:** Best baseline description quality and mode-aware technical details.
- **Gaps:** Structure not standardized; lacks explicit quick-scan section.
- **Recommended fixes:** Keep content but reframe into canonical heading pattern with compact quick reference.

### aedmd-handoff-inspect
- **Compliance:** Useful implementation details and status vocabulary context.
- **Gaps:** Description fails CSO trigger format and starts without "Use when...".
- **Recommended fixes:** Rewrite description to trigger/symptom form and add common mistakes tied to missing/unknown handoffs.

### aedmd-group-id-check
- **Compliance:** Strong domain specificity and practical troubleshooting.
- **Gaps:** Description reads as action summary, not trigger conditions.
- **Recommended fixes:** Reword to mismatch-symptom trigger language and standardize sections.

### aedmd-conversion-cache
- **Compliance:** Good technical correctness and architecture alignment.
- **Gaps:** Description not trigger-first; no explicit quick reference section.
- **Recommended fixes:** Use CSO trigger phrasing (`cache miss`, `stale conversion`) and add quick-reference matrix.

## Actionable Recommendations

### 1) Critical (blocks discovery)
1. Rewrite frontmatter descriptions for 3 non-compliant skills to start with **"Use when..."**.
2. Convert behavior summaries to trigger/symptom descriptions in descriptions.
3. Retain third-person voice and keep frontmatter concise.

### 2) High (degrades experience)
1. Standardize all skills to include:
   - `## Overview`
   - `## When to Use`
   - `## Quick Reference`
   - `## Implementation`
   - `## Common Mistakes`
2. Add keyword signals for discovery and triage:
   - statuses: `success`, `failure`, `needs_review`, `blocked`
   - symptoms: `missing config`, `cache miss`, `group mismatch`, `workspace exists`
   - tools: `gmx`, `gnina`, `gmx_MMPBSA`, wrapper names

### 3) Nice-to-have (polish)
1. Keep all skills within concise token budgets and avoid repeating prerequisites.
2. Add one compact example only where ambiguity remains.
3. Ensure cross-references use skill/command names rather than long narrative passages.

## References

- superpowers writing-skills: https://github.com/obra/superpowers/tree/main/skills/writing-skills
- superpowers writing-skills raw SKILL.md: https://raw.githubusercontent.com/obra/superpowers/main/skills/writing-skills/SKILL.md
- superpowers anthropic best practices: https://raw.githubusercontent.com/obra/superpowers/main/skills/writing-skills/anthropic-best-practices.md
- agentskills.io specification: https://agentskills.io/specification
