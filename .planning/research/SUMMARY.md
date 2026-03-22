# Project Research Summary

**Project:** autoEnsmblDockMD
**Domain:** Computational Chemistry / Molecular Dynamics Workflow Automation
**Researched:** 2026-03-23
**Confidence:** MEDIUM-HIGH

## Executive Summary

autoEnsmblDockMD is an agentic workflow automation system for ensemble molecular docking and MD simulation, targeting computational chemistry researchers who need to systematically evaluate ligand-receptor binding affinities. The system orchestrates a five-stage pipeline: receptor preparation → ligand preparation → docking (gnina) → complex MD (GROMACS) → MMPBSA binding free energy calculations.

Research conclusions indicate a modular stage-gated pipeline architecture with checkpoint-based human verification is essential for this domain. The recommended stack leverages GROMACS 2025.x, gnina 1.3.x for CNN-enhanced docking, and gmx_MMPBSA for binding free energy calculations. Critical pitfalls include force field incompatibility between protein and ligand, missing hydrogen atoms in input structures, and context window overflow in long multi-stage agentic workflows. The MVP should prioritize table stakes—functional stage scripts with proper error handling—before adding agentic orchestration features. Ligand preparation automation and ffnonbond.itp edits should be explicitly deferred to v2+ as these are error-prone and require deep domain expertise.

## Key Findings

### Recommended Stack

**Core technologies:**
- **GROMACS 2025.4+** — Industry-standard MD simulation engine with GPU acceleration; required version >2022 per project spec
- **gnina 1.3.x** — Deep learning-enhanced molecular docking with CNN scoring; fork of AutoDock Vina with GPU support
- **gmx_MMPBSA 1.6.4+** — Binding free energy calculations integrated with GROMACS trajectories
- **MDAnalysis 2.10.0+** — Trajectory analysis supporting GROMACS XTC/TRR/TPR formats
- **RDKit 2025.09.6+** — Cheminformatics library for ligand processing; install via conda-forge
- **Python 3.11+** — Required by MDAnalysis 2.10.0+ and modern scientific stack
- **Conda** — Environment management for complex scientific software stacks

**Installation:** Core simulation tools (GROMACS, gnina) installed separately from conda; gmx_MMPBSA via pip. Conda environment defined in existing env.yml with periodic updates from conda-forge.

### Expected Features

**Must have (table stakes):**
- Receptor preparation — PDB loading, hydrogen addition, protonation, structure cleanup, binding pocket identification
- Ligand preparation — SDF/SMILES loading, force field parameter assignment, 3D structure generation, charge assignment
- Docking execution — Grid box definition, gnina execution, pose extraction and ranking
- MD simulation setup — Complex building, solvation, ion addition, energy minimization, NVT/NPT equilibration
- MD production run — Long trajectory generation with proper temperature/pressure control
- MMPBSA analysis — Trajectory processing, binding free energy calculation, result extraction
- File format support — PDB, GRO, MOL2/SDF, topology (ITP/TOP), trajectory (XTC/TRR)
- Execution environment — Local execution, HPC Slurm support, job monitoring, error detection
- Checkpoint & resume — Stage checkpoints, resume capability, human verification points

**Should have (competitive):**
- Ensemble docking — Multiple receptor conformations, consensus scoring
- Workflow orchestration — End-to-end automation, slash command interface, agent skills, configuration-driven
- Multi-ligand processing — Parallel docking, ligand ranking, batch processing
- Agent-based automation — Orchestrator, runner, analyzer, checker, debugger agents
- Advanced analysis — Custom scripts, trajectory clustering, interaction fingerprints

**Defer (v2+):**
- Ligand preparation automation — Complex chemistry, error-prone; user provides prepared ligands
- ffnonbond.itp edits automation — Force field knowledge required; user provides custom force field
- Real-time visualization — Not required for MVP
- Web interface, cloud execution, GUIs — Out of scope; CLI-focused

### Architecture Approach

The recommended architecture follows a **stage-based pipeline** with six component layers: **Workflow Orchestration** (orchestrator agent managing state machine), **Agent Management** (five agent types with distinct responsibilities), **Script Execution** (stage-specific and shared utility scripts), **Data Management** (workspace structure, checkpoint system), **Configuration** (hierarchical YAML with global/stage/ligand overrides), and **Documentation** (README, AGENTS.md, WORKFLOW.md, skills/).

**Major components:**
1. **Orchestrator Agent** — Workflow state machine, stage routing, checkpoint gates, agent spawning
2. **Runner Agent** — Stage script execution, parameter handling, output generation
3. **Analyzer Agent** — Data processing, metrics extraction, result parsing (PDB, GRO, XVG, CSV)
4. **Checker Agent** — Result validation, threshold comparison, warning generation
5. **Debugger Agent** — Error diagnosis, issue resolution, follows GSD-debugger workflow

### Critical Pitfalls

1. **Force field incompatibility** — AMBER protein + CGenFF ligand causes crashes; validate FF consistency before simulation
2. **Missing hydrogen atoms** — Leads to failed docking/MD/MMPBSA; require explicit hydrogen addition step
3. **Context window overflow** — Long workflows exhaust LLM context; implement checkpoint-based session management
4. **Ignoring simulation stability** — Unstable MD produces invalid MMPBSA; verify RMSD <3Å before proceeding
5. **MMPBSA topology mismatch** — AMBER topology must match GROMACS structure; regenerate from exact MD structure

**Moderate pitfalls to address:**
- HPC vs local execution path incompatibilities — Use relative paths, detect HPC environment
- Parallel multi-ligand race conditions — Unique output directories per ligand, GPU memory checks
- File format conversion loses information — Validate coordinate integrity after every conversion
- Incorrect box size/center for docking — Use autobox from known binder, visualize before docking
- Ion concentration mismatch — Match MMPBSA saltcon to MD conditions explicitly

### Agent Practices

Five agent types with distinct responsibilities using JSON state files for inter-agent communication. Skills stored as YAML files with capability metadata, usage instructions, parameter definitions, and examples. Slash commands follow hierarchical naming (/stage-action) mapping to shell scripts. Checkpoint system combines time-based and event-based triggers with verification prompts at human verification gates. Context window management via file-based state tracking rather than in-memory accumulation.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Foundation
**Rationale:** No other component can be built without configuration and environment foundation.
**Delivers:** Configuration system with hierarchical loading, environment setup validation (env.yml + setenv.sh), basic checkpoint system for state persistence, script framework with input/output contracts.
**Addresses:** Table stakes features (execution environment, checkpoint system)
**Avoids:** Pitfall: Context window overflow by implementing file-based state tracking from Day 1

### Phase 2: Core Pipeline Stages
**Rationale:** These are the computational core—workflow cannot function without executable stage scripts.
**Delivers:** Receptor preparation scripts, ligand preparation scripts, docking scripts (parallel support), MD simulation scripts (GROMACS), MMPBSA scripts (gmx_MMPBSA)
**Uses:** GROMACS 2025.x, gnina 1.3.x, gmx_MMPBSA 1.6.x, MDAnalysis
**Implements:** Script Execution Layer

### Phase 3: Agent Infrastructure
**Rationale:** Agents require stable scripts to orchestrate—build after core stages are functional.
**Delivers:** Orchestrator agent (workflow state machine), Runner agent (stage execution), Checker agent (result validation), Debugger agent (issue resolution)
**Implements:** Agent Management Layer

### Phase 4: Integration & Scale
**Rationale:** Integration requires all components available for testing.
**Delivers:** Slash commands (user-facing stage triggers), agent skills (loadable skill definitions), analysis tools, full workflow integration testing
**Implements:** Workflow Orchestration Layer, Documentation Layer

### Phase 5: Polish
**Rationale:** Final refinement after all functional components complete.
**Delivers:** Documentation (README, AGENTS.md, WORKFLOW.md), comprehensive error handling, performance optimization, user acceptance testing

### Phase Ordering Rationale

- **Foundation before stages:** Configuration and checkpoint system enable all downstream work
- **Stages before agents:** Agents orchestrate scripts; scripts must exist first
- **Agents before integration:** Full integration testing requires agent infrastructure
- **Integration before polish:** Documentation and error handling emerge from integration learnings
- **Avoids FF incompatibility:** Phase 2 receptor/ligand prep includes explicit FF validation
- **Avoids context overflow:** Phase 1 checkpoint design prevents later context issues

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2 (Docking):** gnina CNN scoring configuration, multi-ligand parallel execution validation
- **Phase 2 (MMPBSA):** trajectory processing requirements, topology generation edge cases
- **Phase 3 (Agent Infrastructure):** Slurm job array compatibility verification

Phases with standard patterns (skip research-phase):
- **Phase 1:** Configuration patterns well-documented, checkpoint systems follow standard file-based state approaches
- **Phase 4:** Integration patterns based on established workflow automation (Snakemake, CWL)

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Based on official documentation for GROMACS, gnina, gmx_MMPBSA, MDAnalysis |
| Features | MEDIUM | Based on standard computational chemistry workflow; some project-specific features |
| Architecture | MEDIUM | Based on workflow management best practices (CWL, Snakemake), adapted for domain |
| Pitfalls | HIGH | Domain knowledge from GROMACS/AMBER FF documentation, common error patterns |
| Agent Practices | MEDIUM | Based on OpenCode patterns and project requirements; some inference |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- **gnina version validation:** Could not verify current state of specific gnina releases—recommend validating during implementation
- **Parallel execution details:** Need to verify Slurm job array compatibility during Phase 3
- **MMPBSA analysis specifics:** May need phase-specific research on trajectory processing requirements
- **Agent communication scalability:** Limited research on multi-ligand parallel execution with multiple agents

## Sources

### Primary (HIGH confidence)
- GROMACS Documentation (2025 series) — https://manual.gromacs.org/documentation/
- gnina GitHub — https://github.com/gnina/gnina (v1.3.x releases)
- gmx_MMPBSA GitHub — https://github.com/Valdes-Tresanco-MS/gmx_MMPBSA (v1.6.4+)
- MDAnalysis Releases — https://github.com/MDAnalysis/mdanalysis/releases (2.10.0+)
- RDKit Documentation — https://www.rdkit.org/docs/ (2025.x quarterly releases)

### Secondary (MEDIUM confidence)
- Common Workflow Language (CWL) — https://www.commonwl.org/
- Snakemake workflow automation — https://snakemake.readthedocs.io/
- OpenCode skills directory structure — /share/home/nglokwan/opencode/pylib_han/.opencode/skills/

### Tertiary (LOW confidence)
- Community patterns (Snakemake/Nextflow for HPC) — inferring from general HPC workflow patterns
- Agent practices from OpenCode system — pattern inference from requirements

---

*Research completed: 2026-03-23*
*Ready for roadmap: yes*