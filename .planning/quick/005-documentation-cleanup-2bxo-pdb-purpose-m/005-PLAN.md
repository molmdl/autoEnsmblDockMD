---
phase: quick-005
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - work/input/README.md
  - .opencode/skills/aedmd-checker-validate/SKILL.md
  - .opencode/skills/aedmd-debugger-diagnose/SKILL.md
  - .opencode/skills/aedmd-orchestrator-resume/SKILL.md
autonomous: true

must_haves:
  truths:
    - "2bxo.pdb purpose is clearly documented in work/input/README.md"
    - "metadata.stage values match wrapper token names (checker_validate, debugger_diagnose, orchestrator_resume)"
    - "general.config is correctly marked as CLI flag, not INI config key"
  artifacts:
    - path: "work/input/README.md"
      provides: "Clear documentation of 2bxo.pdb as starting receptor for ensemble generation"
      contains: "2bxo.pdb"
    - path: ".opencode/skills/aedmd-checker-validate/SKILL.md"
      provides: "Corrected metadata.stage = checker_validate"
      pattern: "stage: checker_validate"
    - path: ".opencode/skills/aedmd-debugger-diagnose/SKILL.md"
      provides: "Corrected metadata.stage = debugger_diagnose"
      pattern: "stage: debugger_diagnose"
    - path: ".opencode/skills/aedmd-orchestrator-resume/SKILL.md"
      provides: "Corrected metadata.stage = orchestrator_resume"
      pattern: "stage: orchestrator_resume"
  key_links:
    - from: ".opencode/skills/*.SKILL.md metadata.stage"
      to: "scripts/commands/*.sh dispatch_agent calls"
      via: "stage token alignment"
      pattern: "dispatch_agent.*\"(checker_validate|debugger_diagnose|orchestrator_resume)\""
---

<objective>
Fix three documentation drift issues identified in quick-003 dry-run analysis: clarify 2bxo.pdb purpose, harmonize metadata-stage naming across three skills, and fix general.config parameter drift.

Purpose: Eliminate confusion between starting receptor (2bxo.pdb) and alignment target (rec.pdb), align skill metadata stage tokens with wrapper dispatch names, and correctly categorize general.config as CLI flag rather than INI config parameter.

Output: Updated README.md and three SKILL.md files with corrected documentation.
</objective>

<execution_context>
Quick task mode: focused documentation fixes with no research or checker phase required.
</execution_context>

<context>
@.planning/STATE.md
@work/input/README.md
@.opencode/skills/aedmd-checker-validate/SKILL.md
@.opencode/skills/aedmd-debugger-diagnose/SKILL.md
@.opencode/skills/aedmd-orchestrator-resume/SKILL.md
@AGENTS.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Clarify 2bxo.pdb purpose in work/input/README.md</name>
  <files>work/input/README.md</files>
  <action>
Update line 4 in work/input/README.md to clarify 2bxo.pdb purpose:

Current line 4:
```
2bxo.pdb
```

Replace with:
```
2bxo.pdb: starting receptor for ensemble generation (aligned to rec.pdb target after MD sampling)
```

This distinguishes:
- **2bxo.pdb** = input receptor for ensemble MD workflow
- **rec.pdb** = reference structure for alignment after ensemble generation

Follow existing README.md style (lowercase prefix before colon, descriptive explanation after).
  </action>
  <verify>
```bash
grep "2bxo.pdb.*starting receptor.*ensemble" work/input/README.md
```
Expect: Match showing clarified purpose.
  </verify>
  <done>
work/input/README.md line 4 explicitly states 2bxo.pdb is the starting receptor for ensemble generation with alignment to rec.pdb target.
  </done>
</task>

<task type="auto">
  <name>Task 2: Fix metadata.stage naming drift in three SKILL.md files</name>
  <files>
.opencode/skills/aedmd-checker-validate/SKILL.md
.opencode/skills/aedmd-debugger-diagnose/SKILL.md
.opencode/skills/aedmd-orchestrator-resume/SKILL.md
  </files>
  <action>
Update metadata.stage values in YAML frontmatter to match wrapper token names used in dispatch_agent calls:

**File 1: aedmd-checker-validate/SKILL.md**
- Current line 10: `stage: quality_validation`
- Replace with: `stage: checker_validate`

**File 2: aedmd-debugger-diagnose/SKILL.md**
- Current line 10: `stage: failure_diagnosis`
- Replace with: `stage: debugger_diagnose`

**File 3: aedmd-orchestrator-resume/SKILL.md**
- Current line 10: `stage: workflow_resume`
- Replace with: `stage: orchestrator_resume`

**Rationale:** Wrapper scripts call `dispatch_agent "checker" "checker_validate"` etc. (verified in scripts/commands/common.sh STAGE_SCRIPT_MAP). Skill metadata should reflect actual dispatch token names for consistency.
  </action>
  <verify>
```bash
grep "stage: checker_validate" .opencode/skills/aedmd-checker-validate/SKILL.md
grep "stage: debugger_diagnose" .opencode/skills/aedmd-debugger-diagnose/SKILL.md
grep "stage: orchestrator_resume" .opencode/skills/aedmd-orchestrator-resume/SKILL.md
```
All three greps must return matches.
  </verify>
  <done>
All three SKILL.md frontmatter metadata.stage values now match wrapper dispatch token names (checker_validate, debugger_diagnose, orchestrator_resume).
  </done>
</task>

<task type="auto">
  <name>Task 3: Fix general.config parameter drift in three SKILL.md files</name>
  <files>
.opencode/skills/aedmd-checker-validate/SKILL.md
.opencode/skills/aedmd-debugger-diagnose/SKILL.md
.opencode/skills/aedmd-orchestrator-resume/SKILL.md
  </files>
  <action>
Fix parameter table rows showing `general.config` as Config Key. This is a CLI wrapper argument, not an INI config section key.

**For all three files (checker-validate, debugger-diagnose, orchestrator-resume):**

Find parameter table row (example from checker-validate line 33):
```
| Config file | general.config | --config | config.ini | Path to workflow configuration used for validation context. |
```

Replace with:
```
| Config file | *(CLI flag)* | `--config` | `config.ini` | Path to workflow configuration used for validation context. |
```

Apply identical fix to corresponding rows in debugger-diagnose and orchestrator-resume SKILL.md files.

**Rationale:** `--config` is a wrapper CLI flag pointing to the INI file. It is not a section key within config.ini (which contains `[general]`, `[receptor]`, etc.). Marking as `*(CLI flag)*` prevents confusion.
  </action>
  <verify>
```bash
grep "| Config file | \*\(CLI flag\)\* | \`--config\`" .opencode/skills/aedmd-checker-validate/SKILL.md
grep "| Config file | \*\(CLI flag\)\* | \`--config\`" .opencode/skills/aedmd-debugger-diagnose/SKILL.md
grep "| Config file | \*\(CLI flag\)\* | \`--config\`" .opencode/skills/aedmd-orchestrator-resume/SKILL.md
```
All three greps must return matches showing corrected Config Key column.
  </verify>
  <done>
All three SKILL.md parameter tables correctly mark general.config as `*(CLI flag)*` in Config Key column, eliminating config drift documentation.
  </done>
</task>

</tasks>

<verification>
1. Verify 2bxo.pdb purpose is clear in work/input/README.md
2. Verify metadata.stage alignment with wrapper tokens in three SKILL.md files
3. Verify general.config correctly marked as CLI flag in three SKILL.md parameter tables
4. Run grep validation commands from each task's verify section
</verification>

<success_criteria>
- work/input/README.md line 4 states 2bxo.pdb is starting receptor for ensemble generation
- Three SKILL.md files have metadata.stage values matching wrapper dispatch tokens
- Three SKILL.md parameter tables correctly categorize --config as CLI flag
- All grep verification commands return expected matches
- No regression in existing documentation structure or formatting
</success_criteria>

<output>
After completion, create `.planning/quick/005-documentation-cleanup-2bxo-pdb-purpose-m/005-SUMMARY.md`
</output>
