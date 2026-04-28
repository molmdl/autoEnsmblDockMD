---
phase: quick-004
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .opencode/skills/aedmd-dock-run/SKILL.md
autonomous: true

must_haves:
  truths:
    - "Users can distinguish between reference_ligand (file path) and autobox_ligand (box source selector)"
    - "Targeted mode parameter requirements are complete and unambiguous"
    - "Both reference_ligand and autobox_ligand are visible in parameter table"
  artifacts:
    - path: ".opencode/skills/aedmd-dock-run/SKILL.md"
      provides: "Complete targeted mode parameter documentation"
      min_lines: 65
      contains: "reference_ligand"
  key_links:
    - from: "Parameter table"
      to: "scripts/config.ini.template docking section"
      via: "Config key column alignment"
      pattern: "docking\\.(reference_ligand|autobox_ligand)"
---

<objective>
Fix CRITICAL documentation gap (C-01) in aedmd-dock-run skill by adding missing targeted mode parameters and clarifying their distinct roles.

Purpose: Eliminate configuration ambiguity for targeted docking mode before Phase 7 controlled execution.
Output: Updated SKILL.md with complete parameter table, comparison subsection, and targeted mode requirements.
</objective>

<execution_context>
@~/.config/opencode/get-shit-done/workflows/execute-plan.md
@~/.config/opencode/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/STATE.md
@.planning/quick/003-dry-run-targeted-docking-workflow-analys/003-SKILL-AUDIT.md
@scripts/config.ini.template
@scripts/dock/2_gnina.sh
@WORKFLOW.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add missing targeted mode parameters to aedmd-dock-run SKILL.md</name>
  <files>.opencode/skills/aedmd-dock-run/SKILL.md</files>
  <action>
Add two missing parameter rows to the Parameters table (after line 41):

**Add after `autobox_add` row:**

1. **reference_ligand row:**
   - Parameter: "Reference ligand"
   - Config Key: `docking.reference_ligand`
   - CLI Flag: `--reference-ligand`
   - Default: (empty - required for `mode=targeted`)
   - Description: "Path to reference ligand structure for targeted/test mode validation and optional autobox source."

2. **autobox_ligand row:**
   - Parameter: "Autobox ligand source"
   - Config Key: `docking.autobox_ligand`
   - CLI Flag: `--autobox-ligand`
   - Default: `receptor`
   - Description: "Autobox source selector: `receptor` (box from receptor), or path to reference ligand structure file."

**Add comparison subsection after Parameters table (before Expected Output section):**

### Targeted Mode Parameter Clarification

For `mode=targeted` or `mode=test`:

- **`reference_ligand`**: File path to the reference ligand structure (used for redocking validation in test mode, and available as autobox source in targeted mode).
- **`autobox_ligand`**: Controls which structure defines the docking box:
  - `receptor`: Box centered on each receptor conformer (default for blind mode).
  - Path to file: Box centered on specified reference ligand (typical for targeted mode).

**Common targeted workflow:** Set `autobox_ligand = ${docking:reference_ligand}` to dock around the reference binding pocket consistently across ensemble.

**Add mode-specific requirement callout before Expected Output:**

> **Note:** `mode=targeted` requires `autobox_ligand` to specify a reference structure path (not `receptor`), otherwise behavior defaults to blind-like autoboxing per receptor.

Alignment sources:
- `scripts/config.ini.template:131,140-141` (both keys present with inline comment)
- `scripts/dock/2_gnina.sh:37,42` (both keys consumed)
- `WORKFLOW.md:151` (documents both in Mode A input requirements)
  </action>
  <verify>
1. `grep -E "(reference_ligand|autobox_ligand)" .opencode/skills/aedmd-dock-run/SKILL.md | wc -l` returns ≥6 (table rows + subsection mentions)
2. Parameter table includes both `docking.reference_ligand` and `docking.autobox_ligand` rows
3. Comparison subsection clearly distinguishes their roles
4. Targeted mode requirement callout is present
  </verify>
  <done>
- ✅ Parameter table has 7+ rows (original 5 + reference_ligand + autobox_ligand)
- ✅ Comparison subsection explains difference between the two parameters with targeted workflow example
- ✅ Targeted mode requirement callout warns against using `autobox_ligand=receptor` for targeted mode
- ✅ All references align with config.ini.template, 2_gnina.sh, and WORKFLOW.md
  </done>
</task>

</tasks>

<verification>
1. Read updated SKILL.md and confirm parameter table completeness
2. Verify targeted mode parameter guidance matches actual script behavior in 2_gnina.sh
3. Confirm no regression in existing parameter documentation
</verification>

<success_criteria>
- aedmd-dock-run SKILL.md parameter table includes both `reference_ligand` and `autobox_ligand`
- Comparison subsection clearly explains the difference and typical targeted workflow pattern
- Mode-specific requirement callout prevents misconfiguration
- C-01 (CRITICAL gap from quick-003 audit) is resolved
- Phase 7 (First Controlled Execution) documentation blocker is cleared
</success_criteria>

<output>
After completion, create `.planning/quick/004-fix-targeted-docking-parameter-documenta/004-SUMMARY.md`
</output>
