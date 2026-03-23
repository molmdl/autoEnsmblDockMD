---
phase: quick-001
plan: 001
type: execute
wave: 1
depends_on: []
files_modified: [WORKFLOW.md]
autonomous: true
must_haves:
  truths:
    - "WORKFLOW.md references agent roles from AGENTS.md"
    - "Human checkpoints are clearly marked in workflow stages"
    - "Stage-to-requirement mapping is explicit"
    - "TO BE FINALIZED banner remains at top"
  artifacts:
    - path: "WORKFLOW.md"
      provides: "Workflow definition with agent integration"
      contains: "Agent Responsibilities section"
  key_links:
    - from: "WORKFLOW.md"
      to: "AGENTS.md"
      via: "reference to agent roles"
      pattern: "orchestrator|runner|analyzer|checker|debugger"
---

<objective>
Update WORKFLOW.md to integrate agent roles, checkpoint requirements, and stage-to-requirement mapping while preserving the TO BE FINALIZED banner.

Purpose: Ensure WORKFLOW.md serves as the authoritative workflow document that references AGENTS.md agent responsibilities and aligns with REQUIREMENTS.md checkpoint system.
Output: Updated WORKFLOW.md with agent integration and requirement traceability.
</objective>

<execution_context>
@~/.config/opencode/get-shit-done/workflows/execute-plan.md
@~/.config/opencode/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/REQUIREMENTS.md
@AGENTS.md
@WORKFLOW.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add Agent Context Section to WORKFLOW.md Header</name>
  <files>WORKFLOW.md</files>
  <action>
    Add a new section after "Input Files Required" (before Stage 0) called "Agent Responsibilities" that:

    1. References AGENTS.md agent types (orchestrator, runner, analyzer, checker, debugger)
    2. Briefly describes which agent handles which workflow stages:
       - **Orchestrator**: Manages overall workflow state, checkpoints, spawns other agents
       - **Runner**: Executes stage scripts, handles parameters
       - **Analyzer**: Runs standard analysis (RMSD, contacts, plots), custom analysis
       - **Checker**: Validates results, generates warnings/suggestions
       - **Debugger**: Diagnoses failures, follows GSD workflow
    3. Notes the experimental status of agent automation per AGENTS.md

    Then add a "Notes for Agents" subsection referencing key constraints from AGENTS.md:
    - No `rm` commands except in test directories
    - Never require sudo permission
    - Source `./scripts/setenv.sh` before operations
    - Conda environment only
    - Report task summaries to md files

    Preserve all existing content. Only add new sections.
  </action>
  <verify>
    grep -q "Agent Responsibilities" WORKFLOW.md && grep -q "orchestrator" WORKFLOW.md && grep -q "runner" WORKFLOW.md && grep -q "checker" WORKFLOW.md && grep -q "debugger" WORKFLOW.md
  </verify>
  <done>
    WORKFLOW.md contains Agent Responsibilities section referencing AGENTS.md agent types, and Notes for Agents subsection with key constraints.
  </done>
</task>

<task type="auto">
  <name>Task 2: Add Requirement Traceability to Workflow Stages</name>
  <files>WORKFLOW.md</files>
  <action>
    Update each Stage header (Stage 0 through Stage 9) to include a "Requirements" line that maps to REQUIREMENTS.md IDs:

    Example format for Stage 0:
    ```
    ## Stage 0: Input Validation & Setup
    **Requirements:** CHECK-01, CHECK-02, EXEC-01
    ```

    Mappings:
    - Stage 0: CHECK-01 (stage checkpoints), CHECK-02 (human verification), EXEC-01 (local execution)
    - Stage 1-3: SCRIPT-01 (receptor scripts), CHECK-01, EXEC-01
    - Stage 4-5: SCRIPT-03 (docking scripts), CHECK-01, CHECK-02, EXEC-05 (parallel jobs)
    - Stage 6-7: SCRIPT-04, SCRIPT-05 (MD scripts), CHECK-01, EXEC-02 (Slurm)
    - Stage 8: SCRIPT-06 (MMPBSA scripts), CHECK-01, EXEC-02, EXEC-05
    - Stage 9: SCRIPT-07 (analysis scripts), DOC-01, DOC-02

    Also add explicit "Checkpoint" markers that align with CHECK requirements:
    - Mark stages that require human verification (CHECK-02)
    - Mark stages that save intermediate state (CHECK-01)

    Preserve all existing stage content. Only add Requirements lines and clarify checkpoint markers.
  </action>
  <verify>
    grep -q "Requirements:" WORKFLOW.md && grep -q "CHECK-01" WORKFLOW.md && grep -q "EXEC-" WORKFLOW.md && grep -q "SCRIPT-" WORKFLOW.md
  </verify>
  <done>
    Each Stage header includes Requirements line mapping to REQUIREMENTS.md IDs. Checkpoint markers are explicit.
  </done>
</task>

<task type="auto">
  <name>Task 3: Update Scripts Status Table with Script Categories</name>
  <files>WORKFLOW.md</files>
  <action>
    Update the "Scripts Status" section near the end of WORKFLOW.md to:

    1. Add a "Category" column that groups scripts by their purpose:
       - **Input/Validation**: validate_input
       - **Receptor**: rec_clean, rec_addH, rec_topol
       - **Ensemble/MD**: md_em, md_nvt, md_npt, md_prod, ensemble_extract, cluster_rmsd, ensemble_select
       - **Docking**: dock_prep_grid, dock_gnina, dock_rmsd, dock_ligands, dock_aggregate
       - **Complex/MD**: com_select_poses, com_build_topol, com_solvate, md_em_complex, md_equilibrate, md_prod_complex
       - **MMPBSA**: mmpbsa_prep, mmpbsa_run, mmpbsa_aggregate
       - **Analysis**: analysis_ranking, analysis_plots, analysis_report

    2. Add "CLI Support" column indicating if script will support CLI flags (SCRIPT-08 requirement):
       - Mark as "PLANNED" for all scripts

    3. Keep the STATUS and LOCATION columns as-is

    The table should help agents understand which scripts work together.
  </action>
  <verify>
    grep -q "Category" WORKFLOW.md && grep -q "CLI Support" WORKFLOW.md && grep -q "Receptor" WORKFLOW.md && grep -q "Docking" WORKFLOW.md
  </verify>
  <done>
    Scripts Status table has Category and CLI Support columns, grouping scripts by purpose and indicating CLI flag support.
  </done>
</task>

</tasks>

<verification>
- WORKFLOW.md still contains TO BE FINALIZED banner at top
- Agent Responsibilities section references all 5 agent types from AGENTS.md
- Each stage has Requirements line mapping to REQUIREMENTS.md
- Scripts Status table has Category and CLI Support columns
- File remains syntactically valid markdown
</verification>

<success_criteria>
- WORKFLOW.md updated with agent context, requirement traceability, and enhanced script table
- All existing workflow content preserved
- TO BE FINALIZED banner remains at line 1
- Clear mapping between workflow stages and requirements
</success_criteria>

<output>
After completion, create `.planning/quick/001-update-workflow-template/001-SUMMARY.md`
</output>