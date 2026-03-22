# Agent Practices Research

**Domain:** Agentic Workflow Design for Scientific Computing
**Researched:** 2026-03-23
**Confidence:** MEDIUM

## Executive Summary

This research documents best practices for designing coding agents, agent skills, and slash commands for automated scientific workflows in the autoEnsmblDockMD project. Based on the project requirements and established patterns from OpenCode and similar agentic systems, this document provides actionable recommendations for implementing the five planned agent types (orchestrator, runner, analyzer, checker, debugger), skill file formats, slash command structures, state management approaches, and human checkpoint integration.

The key insight from this research is that agentic workflows for scientific computing require a separation of concerns where each agent type has a specific, limited responsibility. This design principle, combined with file-based state tracking and explicit checkpoint mechanisms, enables reliable workflow automation while preserving human oversight. The recommended approach prioritizes script-based execution over dynamic command generation, configuration-driven parameters over hardcoded values, and structured file formats for inter-agent communication.

## Recommended Agent Design

### Agent Type Responsibilities

| Agent Type | Primary Responsibility | Boundaries |
|------------|----------------------|------------|
| Orchestrator | Workflow coordination, agent spawning, stage transitions | Does not execute scripts directly; delegates to runner |
| Runner | Script execution, parameter handling, output generation | Executes only defined scripts; returns results to orchestrator |
| Analyzer | Data processing, metrics calculation, result parsing | Produces structured output consumed by checker |
| Checker | Result evaluation, threshold comparison, warning generation | Makes binary decisions; defers fixes to debugger |
| Debugger | Error diagnosis, script modification, issue resolution | Follows gsd-debugger workflow; reports back to checker |

### Agent Communication Protocol

The orchestrator-agent communication should follow a structured message-passing pattern using JSON-formatted state files. Each agent reads its input state from a designated file, processes the task, and writes output to a new state file for the next agent to consume. This approach enables checkpoint recovery and prevents context window overflow by limiting the amount of state each agent must maintain in memory.

The orchestrator maintains a workflow state machine that tracks which stage is active, which agents have been spawned, and what checkpoint markers exist. When a human verification point is reached, the orchestrator pauses and signals the need for human input through a status file that the user can inspect. The runner agent receives stage parameters from the orchestrator, loads the appropriate workflow script, executes it with the provided parameters, and captures both stdout and stderr for logging and error handling.

The analyzer agent operates on the output files produced by the runner, parsing formats such as PDB, GRO, XVG, and CSV depending on the scientific domain. For molecular dynamics workflows, the analyzer might extract RMSD values from trajectory analysis, binding energies from docking results, or MM/PBSA calculations from free energy outputs. The checker agent receives the analyzed results and compares them against configurable thresholds, generating warnings or proceeding based on pass/fail criteria.

### Agent State Management

Each agent should maintain minimal in-memory state, relying instead on file-based state tracking. The recommended pattern is a stage directory structure where each stage has an input/ subdirectory containing the state file, an output/ subdirectory for results, and a metadata.json file tracking execution status. The state file follows this structure:

```json
{
  "stage_id": "em_minimization",
  "status": "pending|running|completed|failed|awaiting_verification",
  "parameters": {},
  "results": {},
  "artifacts": [],
  "checkpoint_required": true,
  "previous_stage": "ligand_prep"
}
```

When an agent starts, it reads the current state file to understand what work has been done. When it completes successfully, it updates the status and writes results to the state file before exiting. This pattern enables the orchestrator to recover from failures by inspecting the state file rather than requiring full workflow restart.

## Skill File Format

### Recommended Structure

Skills should be stored as individual YAML or Markdown files in a designated skills directory, with each skill having a consistent structure that enables agents to load and use them without additional parsing. Based on the project requirements for "minimal but sufficient" skill content, the recommended format includes four sections: capability metadata, usage instructions, parameter definitions, and examples.

The capability metadata section identifies the skill name, version, required environment, and dependencies. The usage instructions provide terse but complete guidance on invoking the skill from an agent, including the command format and expected inputs. The parameter definitions specify each configurable option with its type, default value, and validation constraints. The examples section shows concrete usage cases covering common scenarios.

```yaml
name: file-format-conversion
version: 1.0.0
description: Convert between molecular file formats including PDB, GRO, and topology formats
environment: conda
dependencies:
  - python >=3.9
  - MDAnalysis
  - biopython

usage:
  command: python -m scripts.convert_format --input <file> --output <format> [--options]
  input_format: pdb|gro|mol2|sdf
  output_format: pdb|gro|mol2|sdf

parameters:
  - name: input
    type: string
    required: true
    description: Input molecular file path
  - name: output_format
    type: string
    required: true
    enum: [pdb, gro, mol2, sdf]
    description: Target molecular file format
  - name: strip_hydrogens
    type: boolean
    default: false
    description: Remove hydrogen atoms from output

examples:
  - description: Convert ligand PDB to GRO format
    command: python -m scripts.convert_format --input ligand.pdb --output_format gro
  - description: Convert receptor with explicit hydrogens
    command: python -m scripts.convert_format --input receptor.pdb --output_format gro --strip_hydrogens false
```

### Skill Loading Mechanism

Agents should load skills dynamically at runtime rather than having them baked into the agent prompt. This approach reduces context window usage and enables skills to be updated independently of agent code. When an agent recognizes a task that matches a skill capability, it loads the skill file, extracts the relevant parameters, and constructs the appropriate command or API call.

The skill loading should be triggered by pattern matching against task descriptions. For example, if the user requests ligand preparation and the orchestrator spawns a runner agent with that task, the runner should detect that this task maps to the ligand_prep skill, load that skill file, and execute the corresponding script with parameters from the state file.

## Slash Command Structure

### Command Naming Conventions

Slash commands should follow a hierarchical naming convention that reflects the workflow structure. The primary command identifies the workflow stage, and optional subcommands specify the action. Commands should use lowercase letters with hyphens for multi-word names, avoiding special characters that may cause parsing issues. The recommended pattern is /stage-action where stage identifies the workflow phase and action specifies what to do.

For a molecular dynamics ensemble docking workflow, example commands include /docking-run to execute ensemble docking, /docking-analyze to process results, /md-prepare to set up molecular dynamics, /md-run to execute production MD, and /analysis-binding to calculate binding energies. Each command should have a corresponding script in the scripts/ directory that the runner agent will invoke.

### Command Implementation

Each slash command should map to a shell script that the runner agent executes. The command handler receives the command name and any arguments, validates them against the skill parameters, and constructs the appropriate execution context. The runner agent should handle common error cases such as missing input files, invalid parameters, and script failures, providing clear error messages that enable debugging.

Commands should support both interactive and batch execution modes. In interactive mode, the command waits for human confirmation at each checkpoint. In batch mode, the command runs autonomously based on configuration. The mode should be specified through a flag or inferred from the presence of a --batch flag in the command arguments.

## State and Checkpoint Management

### Checkpoint Architecture

The checkpoint system should combine time-based and event-based triggers to balance automation speed with human oversight. Time-based triggers activate after a configurable number of stages or at workflow boundaries. Event-based triggers activate when results fall outside expected ranges or when specific critical stages complete.

Each checkpoint should create a verification state file that the user can inspect. This file should contain the stage identifier, a summary of completed work, key metrics that require verification, and explicit instructions for the user on what to check and how to proceed. The checkpoint file should use a consistent naming pattern like checkpoint_<stage_id>.json to enable easy discovery.

```json
{
  "checkpoint_id": "em_completed",
  "stage": "energy_minimization",
  "completed_steps": ["ligand_prep", "receptor_prep", "complex_prep"],
  "pending_steps": ["md_equilibration", "md_production", "analysis"],
  "metrics": {
    "rmsd_final": 0.23,
    "energy_final": -1.2e6,
    "rms_force": 42.5
  },
  "verification_required": true,
  "verification_prompt": "Check if RMSD has converged and energy is stable. If acceptable, run /docking-analyze to proceed.",
  "resume_command": "/docking-analyze --from_checkpoint em_completed"
}
```

### Context Window Management

For long-running workflows with many stages, context window management is critical to prevent token limit errors. The recommended approach is checkpoint-based session management where each human verification point implicitly creates a session boundary. When the workflow pauses for human verification, the agent releases its context and the user starts a new session that loads the checkpoint state file to resume.

To further reduce context usage, agents should avoid accumulating long conversation histories. Instead, the orchestrator should write intermediate state to files and have spawned agents read only the minimal context needed for their specific task. The analyzer and checker agents in particular should operate stateless on their input files, producing structured outputs that the next agent can consume without needing to understand the full conversation history.

## Human Verification Integration

### Verification Prompts

Human verification prompts should be specific and actionable, providing clear instructions on what to check, what criteria constitute acceptable results, and what commands to run to proceed or abort. The verification prompt should include a summary of the completed work, the key metrics requiring attention, any warnings generated by the checker agent, and explicit next-step commands.

The prompt format should follow this template: first, a brief statement of what was accomplished, second, a list of key metrics with context, third, any warnings or concerns that require human judgment, and fourth, the exact command strings for proceeding, requesting more analysis, or aborting. This structured format enables users to quickly understand the workflow state and take action without needing to trace through conversation history.

### Verification Workflow

The verification workflow should support three outcomes: proceed to the next stage, request additional analysis or modification, or abort the workflow. When the user responds with a proceed command, the orchestrator loads the checkpoint state and spawns the next agent. When the user requests modification, the orchestrator spawns the debugger agent with the specific issue to address. When the user aborts, the orchestrator writes a final state file with abort status and cleans up any temporary resources.

## Implementation Recommendations

### Phase 1: Foundation

In the first implementation phase, prioritize the orchestrator and runner agents since they form the backbone of workflow automation. The orchestrator should implement the state machine for tracking workflow stages, and the runner should implement script execution with proper error handling. Establish the checkpoint file format and verification prompt structure during this phase, even if human verification is not yet fully integrated.

### Phase 2: Analysis and Checking

The second phase should implement the analyzer and checker agents. Define the output formats that scripts must produce for the analyzer to consume. Implement threshold comparison in the checker with configurable thresholds loaded from a configuration file. Create the initial set of analysis skills that the analyzer uses to process molecular dynamics outputs.

### Phase 3: Debugging and Polish

The third phase implements the debugger agent following the gsd-debugger workflow pattern. Implement error diagnosis capabilities that can identify common failure modes in GROMACS, gnina, and gmx_MMPBSA. Add human checkpoint integration with verification prompts and response handling.

## Sources

- OpenCode skills directory structure at `/share/home/nglokwan/opencode/pylib_han/.opencode/skills/`
- Project AGENTS.md requirements document for agent types and workflow structure
- Workflow.md (pending finalization) for stage definitions
- Restack agent experience documentation for enterprise agent patterns

---

*Agent practices research for autoEnsmblDockMD project*
*Researched: 2026-03-23*