# Architecture Patterns for Automated Molecular Docking and MD Simulation Workflow Systems

**Domain:** Computational Chemistry Workflow Automation
**Project:** autoEnsmblDockMD
**Researched:** 2026-03-23
**Confidence:** MEDIUM

## Executive Summary

Automated molecular docking and MD simulation workflow systems typically follow a **stage-based pipeline architecture** with distinct components for input processing, computational execution, result validation, and output generation. Based on research of established workflow management systems (CWL, Snakemake) and computational chemistry practices, the recommended architecture for autoEnsmblDockMD consists of six core component layers: **Workflow Orchestration**, **Agent Management**, **Script Execution**, **Data Management**, **Configuration**, and **Documentation**.

The system should be built as a **modular pipeline** where each stage (receptor prep → ligand prep → docking → complex MD → MMPBSA) operates as an independent but interconnected module, with clear input/output contracts and checkpoint-based human verification points.

## Recommended Architecture

### Component Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        WORKFLOW ORCHESTRATION LAYER                         │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     Orchestrator Agent                                │   │
│  │  • Manages workflow state machine                                     │   │
│  │  • Controls stage transitions and checkpoint gates                   │   │
│  │  • Spawns runner agents for parallel ligand processing               │   │
│  │  • Routes results between stages                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           AGENT MANAGEMENT LAYER                            │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐  ┌────────────┐  │
│  │ Runner Agent  │  │Analyzer Agent │  │ Checker Agent │  │ Debugger   │  │
│  │               │  │               │  │               │  │ Agent      │  │
│  │ • Executes    │  │ • Runs        │  │ • Validates   │  │ • Follows  │  │
│  │   stage       │  │   standard    │  │   results     │  │   GSD      │  │
│  │   scripts     │  │   analysis    │  │   quality     │  │   workflow │  │
│  │ • Loads       │  │ • Creates     │  │ • Judges      │  │ • Fixes    │  │
│  │   workflow    │  │   custom      │  │   warnings    │  │   issues   │  │
│  │   for stage   │  │   scripts     │  │   suggests    │  │   aware of │  │
│  │               │  │               │  │               │  │   manuals  │  │
│  └───────────────┘  └───────────────┘  └───────────────┘  └────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          SCRIPT EXECUTION LAYER                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Stage-Specific Scripts                             │   │
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐            │   │
│  │  │ Receptor Prep │  │ Ligand Prep   │  │   Docking     │            │   │
│  │  │ • PDB cleaning│  │ • SDF→PDB     │  │ • gnina       │            │   │
│  │  │ • Hydrogens   │  │ • AM1-BCC     │  │ • AutoDock    │            │   │
│  │  │ • Box define  │  │ • Param assign│  │   Vina        │            │   │
│  │  └───────────────┘  └───────────────┘  └───────────────┘            │   │
│  │  ┌───────────────┐  ┌───────────────┐                               │   │
│  │  │ Complex MD    │  │   MMPBSA      │                               │   │
│  │  │ • Energy min  │  │ • Trajectory  │                               │   │
│  │  │ • NVT/NPT     │  │   processing  │                               │   │
│  │  │ • Production  │  │ • Binding     │                               │   │
│  │  │               │  │   energy calc │                               │   │
│  │  └───────────────┘  └───────────────┘                               │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Shared Utility Scripts                            │   │
│  │  • File format conversion (PDB↔GRO)                                 │   │
│  │  • Topology processing (itp generation)                             │   │
│  │  • Trajectory analysis (RMSD, RMSF, H-bond)                         │   │
│  │  • MMPBSA input generation                                          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DATA MANAGEMENT LAYER                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Workspace Structure                               │   │
│  │  work/input/    → User-provided inputs (receptor PDB, ligand SDF)   │   │
│  │  work/workspace/→ Stage outputs with identical structure           │   │
│  │  expected/      → Reference outputs for validation                  │   │
│  │  scripts/       → Generalized executable scripts                    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Checkpoint System                                 │   │
│  │  • Each stage writes completion marker                              │   │
│  │  • Human verification gates between stages                          │   │
│  │  • Resume capability from last checkpoint                           │   │
│  │  • State persistence to avoid context overflow                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          CONFIGURATION LAYER                                │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Configuration Hierarchy                           │   │
│  │  global.yaml    → Shared parameters (software paths, force fields) │   │
│  │  stage.yaml     → Stage-specific MDP parameters                     │   │
│  │  ligand.yaml    → Per-ligand overrides                              │   │
│  │  SLURM profile  → HPC execution parameters                          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Environment Management                            │   │
│  │  env.yml         → Conda environment definition                    │   │
│  │  setenv.sh       → Source script for environment loading           │   │
│  │  Software versions: GROMACS >2022, gnina, gmx_MMPBSA              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DOCUMENTATION LAYER                                 │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Documentation Structure                           │   │
│  │  README.md        → Minimal human-facing documentation             │   │
│  │  AGENTS.md        → Agent-specific workflow guidelines              │   │
│  │  WORKFLOW.md      → Stage-by-stage workflow specification          │   │
│  │  skills/*         → Agent-loadable skill definitions                │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Component Boundaries

| Component | Responsibility | Communicates With | Boundary |
|-----------|---------------|-------------------|----------|
| **Orchestrator Agent** | Workflow state machine, stage routing, checkpoint gates | Runner agents, Checker agent | Entry point - owns workflow state |
| **Runner Agent** | Executes stage scripts, loads workflow definitions | Scripts, Analyzer agent | Per-stage execution |
| **Analyzer Agent** | Runs standard analyses, creates custom scripts | Scripts, output data | Post-stage analysis |
| **Checker Agent** | Validates result quality, judges warnings | All components | Quality gate |
| **Debugger Agent** | Follows GSD-debugger workflow, fixes issues | Scripts, manuals | Issue resolution |
| **Stage Scripts** | Core computational execution (GROMACS, gnina, MMPBSA) | File system, job scheduler | Tool interface |
| **Config Manager** | Loads and merges configuration hierarchy | All components | Read-only access |

### Data Flow

```
User Input
    │
    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│ Stage 1: Receptor Preparation                                           │
│ Input: receptor.pdb → Scripts: clean_pdb, add_h, define_box            │
│ Output: rec_processed.pdb, rec_box.gro                                 │
│ Checkpoint: rec_complete                                               │
└──────────────────────────────────────────────────────────────────────────┘
    │
    ▼ (Human Verification Gate)
┌──────────────────────────────────────────────────────────────────────────┐
│ Stage 2: Ligand Preparation                                             │
│ Input: ligands.sdf → Scripts: sdf2pdb, antechamber, param_assign       │
│ Output: lig_{1..N}.pdb, lig_{1..N}.itp                                 │
│ Checkpoint: lig_complete                                               │
└──────────────────────────────────────────────────────────────────────────┘
    │
    ▼ (Human Verification Gate)
┌──────────────────────────────────────────────────────────────────────────┐
│ Stage 3: Docking (Parallel for N ligands)                               │
│ Input: rec_processed.pdb + lig_{i}.pdb → Scripts: gnina, redock_val   │
│ Output: dock_{1..N}_poses.sdf, docking_scores.csv                      │
│ Checkpoint: dock_complete                                              │
└──────────────────────────────────────────────────────────────────────────┘
    │
    ▼ (Human Verification Gate)
┌──────────────────────────────────────────────────────────────────────────┐
│ Stage 4: Complex MD Simulation                                          │
│ Input: top_{1..N}.pdb + lig_{1..N}.pdb → Scripts: complex_builder,    │
│        gmx_energy_min, gmx_nvt, gmx_npt, gmx_prod                      │
│ Output: traj_{1..N}.xtc, top_{1..N}.tpr                                │
│ Checkpoint: md_complete                                                │
└──────────────────────────────────────────────────────────────────────────┘
    │
    ▼ (Human Verification Gate)
┌──────────────────────────────────────────────────────────────────────────┐
│ Stage 5: MMPBSA Binding Free Energy                                     │
│ Input: traj_{1..N}.xtc, top_{1..N}.tpr → Scripts: trjconv, gmx_MMPBSA │
│ Output: deltaG_{1..N}.csv, decomposition_{1..N}.csv                    │
│ Checkpoint: mmpbsa_complete                                            │
└──────────────────────────────────────────────────────────────────────────┘
    │
    ▼
Final Results (Binding energies, ranked ligands)
```

### Parallel Execution Patterns

The architecture must support parallel execution at multiple levels:

1. **Ligand-level parallelism**: Multiple ligands processed simultaneously via Slurm job arrays
2. **Stage-level parallelism**: Independent ligands can enter MD simulation concurrently
3. **Analysis parallelism**: Multiple trajectories analyzed in parallel

```
                         ┌──────────────────┐
                         │  Orchestrator    │
                         │    Agent         │
                         └────────┬─────────┘
                                  │
              ┌───────────────────┼───────────────────┐
              │                   │                   │
              ▼                   ▼                   ▼
    ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
    │  Runner Agent   │  │  Runner Agent   │  │  Runner Agent   │
    │  (Ligand 1)     │  │  (Ligand 2)     │  │  (Ligand N)     │
    └────────┬────────┘  └────────┬────────┘  └────────┬────────┘
             │                    │                    │
             ▼                    ▼                    ▼
    ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
    │ Dock→MD→MMPBSA  │  │ Dock→MD→MMPBSA  │  │ Dock→MD→MMPBSA  │
    │   Pipeline      │  │   Pipeline      │  │   Pipeline      │
    └─────────────────┘  └─────────────────┘  └─────────────────┘
```

## Patterns to Follow

### Pattern 1: Stage-Gated Pipeline with Checkpoints

**What:** Each workflow stage writes a completion checkpoint before proceeding to the next stage, with optional human verification gate.

**When:** Default behavior for all stages - ensures human oversight and resumability.

**Example:**
```bash
# After receptor prep stage completes
echo "$(date +%Y-%m-%d_%H:%M:%S) rec_prep_complete" > work/workspace/checkpoints/rec_prep.done

# Before proceeding to ligand prep
if [ ! -f work/workspace/checkpoints/rec_prep.done ]; then
    echo "ERROR: Receptor preparation not complete"
    exit 1
fi
```

### Pattern 2: Configuration Hierarchy with Overrides

**What:** Configuration flows from global → stage → ligand-specific, with later sources overriding earlier ones.

**When:** Required for flexible workflow customization without code changes.

**Example:**
```yaml
# global.yaml
gromacs:
  version: "2023.5"
  mdp_path: "./expected/mdp"

# Stage override (ligand.yaml)
gromacs:
  mdp_path: "./custom_mdp"  # Override for this stage only
```

### Pattern 3: Agent Skill Loading

**What:** Agents load minimal but sufficient skill definitions from external files rather than hardcoded instructions.

**When:** Required for agent adaptability and OpenCode compatibility.

**Example:**
```bash
# Agent loads skill before execution
skill load molecular-data-processing
skill load free-energy-analysis
```

### Pattern 4: Input/Output Contract Enforcement

**What:** Each stage declares expected input files and produces defined output files with consistent naming.

**When:** Critical for pipeline reliability and debugging.

**Example:**
```bash
# Stage 1 receptor prep contract
INPUT_REQUIRED=(
    "work/input/rec/receptor.pdb"
)
OUTPUT_PRODUCED=(
    "work/workspace/rec/rec_processed.pdb"
    "work/workspace/rec/rec_box.gro"
    "work/workspace/rec/rec_index.ndx"
)
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Hardcoded File Paths

**What:** Scripts embed absolute paths or paths relative to specific user directories.

**Why bad:** Breaks portability, prevents workspace relocation, causes failures on different systems.

**Instead:** Use configuration-driven paths with workspace-relative references:
```bash
# Bad
python script.py /home/user/project/input.pdb

# Good
python script.py "${WORKSPACE}/input.pdb" --config config.yaml
```

### Anti-Pattern 2: No Checkpoint Persistence

**What:** Workflow assumes continuous execution without state persistence.

**Why bad:** Context window overflow in LLM sessions, inability to resume after interruption, no human verification points.

**Instead:** Implement checkpoint files at each stage boundary:
```bash
# Write checkpoint after each stage
checkpoint_write "ligand_prep" "${WORKSPACE}/checkpoints/"
```

### Anti-Pattern 3: Monolithic Script

**What:** Single script attempts to handle all stages and all ligands.

**Why bad:** Impossible to debug, no parallelization, no selective re-run capability.

**Instead:** Modular scripts per stage with clear input/output contracts:
```bash
# scripts/rec_prep.sh    - Receptor preparation only
# scripts/lig_prep.sh    - Ligand preparation only  
# scripts/dock.sh        - Docking only
# scripts/complex_md.sh  - Complex MD only
# scripts/mmpbsa.sh      - MMPBSA only
```

### Anti-Pattern 4: Missing Error Propagation

**What:** Errors in early stages silently allow progression to later stages.

**Why bad:** Wastes computation on invalid inputs, produces misleading results.

**Instead:** Implement stage-gated progression with explicit error checking:
```bash
# After each stage, check for critical output
if [ ! -s "${OUTPUT_DIR}/ligand.pdb" ]; then
    echo "ERROR: Ligand preparation failed - no output"
    exit 1
fi
```

## Scalability Considerations

| Concern | At 10 ligands | At 100 ligands | At 1000 ligands |
|---------|--------------|----------------|-----------------|
| **Storage** | Local filesystem | Shared filesystem | Distributed storage |
| **Parallel Jobs** | Slurm array (10) | Slurm array (100) | Batch scheduling |
| **Checkpoint Size** | <1MB | ~10MB | ~100MB (compress) |
| **Memory** | <10GB | ~50GB | Distributed |
| **Runtime** | Hours | Days | Weeks (priority queue) |

## Build Order Recommendations

Based on dependency analysis, the recommended build sequence is:

### Phase 1: Foundation (Weeks 1-2)
1. **Configuration system** - Hierarchical config loading
2. **Environment setup** - env.yml + setenv.sh validation
3. **Checkpoint system** - Basic file-based state persistence
4. **Script framework** - Stage template with input/output contracts

**Rationale:** No other component can be built without configuration and environment foundation.

### Phase 2: Core Stages (Weeks 3-5)
1. **Receptor preparation scripts** - First stage implementation
2. **Ligand preparation scripts** - Second stage implementation  
3. **Docking scripts** - Third stage with parallel support
4. **MD simulation scripts** - Fourth stage with GROMACS
5. **MMPBSA scripts** - Fifth stage with gmx_MMPBSA

**Rationale:** These are the computational core - workflow cannot function without executable stage scripts.

### Phase 3: Agent Infrastructure (Weeks 6-7)
1. **Orchestrator agent** - Workflow state machine
2. **Runner agent** - Stage execution controller
3. **Checker agent** - Result validation
4. **Debugger agent** - Issue resolution

**Rationale:** Agents require stable scripts to orchestrate - build after core stages are functional.

### Phase 4: Integration (Weeks 8-10)
1. **Slash commands** - User-facing stage triggers
2. **Agent skills** - Loadable skill definitions
3. **Analysis tools** - Analyzer agent capabilities
4. **Full workflow integration** - End-to-end testing

**Rationale:** Integration requires all components to be available for testing.

### Phase 5: Polish (Weeks 11-12)
1. **Documentation** - README, AGENTS.md, WORKFLOW.md
2. **Error handling** - Comprehensive validation
3. **Performance optimization** - Parallel execution tuning
4. **User acceptance testing** - Human verification workflow

**Rationale:** Final refinement after all functional components are complete.

## Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Component boundaries | MEDIUM | Based on workflow management best practices (CWL, Snakemake), adapted for computational chemistry |
| Data flow | HIGH | Follows established stage-gated pipeline pattern used in scientific workflows |
| Build order | MEDIUM | Dependency analysis is sound, but may need adjustment based on actual script complexity |
| Anti-patterns | HIGH | Common pitfalls well-documented in workflow automation literature |

## Sources

- **Common Workflow Language (CWL)** - Open standard for scientific workflow description: https://www.commonwl.org/
- **Snakemake** - Popular Python-based workflow management system: https://snakemake.readthedocs.io/
- **autoEnsmblDockMD Project Context** - Existing AGENTS.md, WORKFLOW.md, PROJECT.md specifications
- **Computational Chemistry Practices** - Standard stages: receptor prep → ligand prep → docking → MD → MMPBSA

## Gaps to Address

- **Limited web access:** Could not verify current state of specific tools (gnina, gmx_MMPBSA) - recommend validating during implementation
- **Parallel execution details:** Need to verify Slurm job array compatibility during Phase 3
- **MMPBSA analysis specifics:** May need phase-specific research on trajectory processing requirements