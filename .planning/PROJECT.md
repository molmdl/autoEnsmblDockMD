# autoEnsmblDockMD

## What This Is

A toolkit for automated ensemble docking and molecular dynamics simulations using GROMACS and gnina. Provides scripts, slash commands, and agent skills that enable both humans and coding agents to run reproducible docking-to-MMPBSA pipelines with minimal manual intervention.

## Core Value

Human-run pipeline producing validated, reproducible scientific outputs with minimal commands. Agent autonomy is secondary/experimental — useful but subject to uncertainties.

## Requirements

### Validated

(None yet — greenfield project, working scripts being finalized)

### Active

- [ ] **WORKFLOW**: Full pipeline automated via slash commands or agent skills
- [ ] **AGENTS**: Orchestrator, runner, analyzer, checker, debugger agents that know how and when to use commands/skills
- [ ] **SLASH-COMMANDS**: User-facing commands to run major workflow stages
- [ ] **AGENT-SKILLS**: Minimal but sufficient skill definitions loadable by agents
- [ ] **SCRIPTS**: Generalized Python/bash scripts in `./scripts/` with CLI flags or config input, derived from manual workflow
- [ ] **DOCUMENTATION**: README.md for humans, agent-optimized detailed docs

### Out of Scope

- Ligand preparation automation — deferred to future (mentioned in AGENTS.md Future section)
- ffnonbond.itp edits automation — deferred to future

## Context

### Project Background
- Manual workflow scripts exist in `./expected/` subdirectories (being finalized)
- User is actively running manual tests to generate reference outputs
- AGENTS.md contains detailed element breakdown and agent design
- WORKFLOW.md marked "TO BE FINALIZED" — do not proceed to plan related stages until banner removed

### Technical Environment
- Target platform: HPC with Slurm + local execution support
- Required software: GROMACS >2022, gnina, gmx_MMPBSA
- Conda environment via `env.yml`
- Environment setup: `source ./scripts/setenv.sh`

### Pipeline Stages (from expected/ structure)
1. Receptor preparation (`rec/`)
2. Ligand preparation (`lig/`)
3. Docking (`dock/`)
4. Complex MD (`com_md/`)
5. MMPBSA binding free energy (`mmpbsa/`)

### Directory Structure
- `./work/input/` — user-provided inputs for each stage
- `./expected/` — reference outputs from manual runs (same structure as work/input)
- `./scripts/` — generalized scripts for the workflow

## Constraints

- **Agent Platform**: OpenCode is basic requirement; attempt agent-agnostic design where possible
- **Execution Environment**: Must support both HPC (Slurm) and local execution
- **Software Versions**: GROMACS >2022, gnina, gmx_MMPBSA (via pip in conda env)
- **No System Modifications**: Never require sudo, conda environment only
- **Safety**: No `rm` commands except in test directories (must report and seek approval)
- **Multi-job Support**: Must preserve multi-job manager support in shell scripts
- **Configuration-driven**: Preferred over hardcoded values

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| OpenCode-first, attempt agent-agnostic | OpenCode is available and capable; general naming allows future compatibility | — Pending |
| Human automation over agent autonomy | Agent behavior has uncertainties; validated human workflow is priority | — Pending |
| Defer codebase mapping | Workflow/scripts being finalized; map after stabilization | — Pending |

---
*Last updated: 2026-03-23 after initialization*
