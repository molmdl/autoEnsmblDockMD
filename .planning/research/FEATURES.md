# Feature Landscape

**Domain:** Automated molecular docking and MD simulation workflow tools
**Researched:** 2026-03-23
**Confidence:** MEDIUM

## Executive Summary

This document categorizes features for automated molecular docking and MD simulation workflow tools like autoEnsmblDockMD. The research identifies table stakes (essential features), differentiators (competitive advantages), and anti-features (deliberately excluded items). The pipeline covers receptor preparation → ligand preparation → docking (gnina) → complex MD (GROMACS) → MMPBSA binding free energy calculations.

## Table Stakes

Features users expect in any molecular docking/MD workflow tool. Missing these = product feels incomplete or unusable.

### 1. Receptor Preparation

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| PDB structure loading/parsing | Primary input format | Low | Must handle standard PDB format |
| Protein preparation (hydrogen addition, protonation) | Required for simulation | Medium | pH-dependent protonation states |
| Structure cleanup (remove water, ions, ligands) | Clean starting structure | Low | Automated detection and removal |
| Binding pocket identification | Define docking region | Medium | Reference ligand-based or algorithmic |
| Structure conversion to simulation format | GROMACS-compatible | Medium | Need to generate PSF/TOP |

### 2. Ligand Preparation

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| SDF/SMILES loading | Primary ligand input | Low | Must handle multiple formats |
| Force field parameter assignment | Required for MD | High | GAFF, AM1-BCC charges; error-prone |
| 3D structure generation | Must be 3D for docking | Medium | Conformer generation |
| Charge assignment | Required for docking/MD | High | Different methods affect results |
| Structure minimization | Remove clashes | Low | Standard in most tools |

### 3. Molecular Docking

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Grid box definition | Define search space | Medium | Center on binding pocket |
| Docking engine execution | Core function | Medium | AutoDock Vina, gnina |
| Pose extraction and ranking | Get top poses | Low | Sort by binding score |
| Binding affinity estimation | Quantitative metric | Low | From docking score |
| Multi-conformer docking | Account for flexibility | High | Ensemble vs single |

### 4. MD Simulation Setup

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Complex system building | Combine receptor + ligand | Medium | Merge topologies correctly |
| Force field assignment | Define interactions | Low | AMBER/CHARMM compatible |
| Solvation (water box/membrane) | Create simulation environment | Medium | Box size, shape matter |
| Ion addition | Neutralize system | Low | Na+/Cl- typical |
| Energy minimization | Remove clashes | Low | Before equilibration |
| Equilibration (NVT, NPT) | Stabilize system | Medium | Gradual release |

### 5. MD Production Run

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Production MD execution | Core simulation | Medium | Long trajectories (ns-μs) |
| Trajectory analysis | Extract insights | Medium | RMSD, RMSF, contacts |
| Periodic boundary conditions | Correct physics | Low | Standard |
| Temperature/pressure control | NPT conditions | Low | Standard coupling |

### 6. MMPBSA Analysis

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Trajectory processing | Extract snapshots | Medium | Need correct indexing |
| Binding free energy calculation | Quantitative binding | High | MM/PBSA or MM/GBSA |
| Energy decomposition | Per-residue contributions | High | Identify key interactions |
| Result extraction | Output parsing | Low | Parse CSV/text outputs |

### 7. File Format Support

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| PDB input/output | Universal format | Low | Standard |
| GRO output | GROMACS format | Low | Coordinate + box |
| MOL2/SDF input | Ligand formats | Low | Multiple ligands |
| Topology files (ITP, TOP) | GROMACS native | Medium | Merge correctly |
| Trajectory files (XTC, TRR) | MD output | Low | Compression matters |

### 8. Execution Environment

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Local execution | Developer testing | Low | Direct runtime |
| HPC Slurm support | Production runs | Medium | Job submission, queueing |
| Job monitoring | Track progress | Low | Log parsing |
| Error detection | Debug failures | Medium | Exit codes, logs |

### 9. Checkpoint & Resume

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Stage checkpoints | Long MD runs | Medium | Save intermediate states |
| Resume capability | Avoid restart | Medium | Match input/output |
| Human verification points | Quality control | Low | Pause for inspection |

## Differentiators

Features that set products apart. Not expected by default, but highly valued when present.

### 1. Ensemble Docking

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Multiple receptor conformations | Account for flexibility | High | Requires ensemble generation |
| Receptor flexibility handling | More accurate binding | High | Ensemble vs induced fit |
| Consensus scoring | Improved reliability | Medium | Combine multiple poses |
| Conformer generation | Cover chemical space | Medium | Multiple ligand states |

### 2. Workflow Orchestration

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| End-to-end automation | Minimal manual steps | High | Full pipeline execution |
| Slash command interface | User-friendly triggers | Medium | Single command per stage |
| Agent skills | Agent-executable | Medium | Structured for LLM consumption |
| Configuration-driven | Flexible parameters | Low | YAML/JSON config |

### 3. Multi-Ligand Processing

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Parallel ligand docking | Scale to many ligands | High | Batch processing |
| Ligand ranking/selection | Identify top binders | Medium | Score-based filtering |
| Batch processing | High throughput | High | Job array support |

### 4. Agent-Based Automation

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Orchestrator agent | Workflow management | High | Coordinate sub-agents |
| Runner agent | Stage execution | Medium | Execute scripts |
| Analyzer agent | Analysis automation | Medium | Generate reports |
| Checker agent | Result validation | Medium | Quality checks |
| Debugger agent | Error handling | High | Version-aware debugging |

### 5. Advanced Analysis

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Custom analysis scripts | Flexibility | Medium | Python/R scripting |
| Trajectory clustering | Conformer analysis | High | RMSD-based |
| Interaction fingerprint | Detailed contacts | Medium | H-bond, hydrophobic |
| Free energy decomposition | Per-residue insight | High | MM/PBSA decomposition |

### 6. Documentation

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| User-facing README | Onboarding | Low | Clear usage instructions |
| Agent-optimized docs | Tool reuse | Medium | Structured, searchable |
| Version-specific docs | Troubleshooting | Medium | Match installed versions |

## Anti-Features

Features to explicitly NOT build. Common mistakes in this domain or explicitly scoped out.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Ligand preparation automation | Complex chemistry, error-prone | Defer to future; user provides prepared ligands |
| ffnonbond.itp edits automation | Force field knowledge required | Defer to future; user provides custom force field |
| Real-time visualization | Not required for MVP; adds complexity | Post-analysis visualization only |
| Web interface | Out of scope; CLI-focused | CLI + scripts sufficient |
| Cloud execution | Not in target scope | HPC Slurm + local only |
| GUIs | Adds maintenance burden | Plain text configs and scripts |
| Automatic software installation | Environment complexity | User-managed conda environment |

## Feature Dependencies

```
Receptor Prep → Ligand Prep → Docking → Complex MD → MMPBSA
     ↓              ↓           ↓          ↓           ↓
  PDB input    SDF/SMILES   gnina      GROMACS    gmx_MMPBSA
                                         ↓
                                   Trajectory
                                     analysis
```

### Dependency Details

| Feature A | Depends On | Reason |
|-----------|-----------|--------|
| Ligand prep | Receptor prep | Need pocket location |
| Docking | Receptor + ligand prep | Need prepared receptor + ligand |
| Complex MD | Docking | Need docked complex |
| MMPBSA | Complex MD | Need MD trajectory |
| Analysis | MD production | Need trajectory data |

## MVP Recommendation

For MVP, prioritize these features in order:

### Phase 1: Core Pipeline (Must Have)

1. **Receptor preparation** - Basic cleanup and pocket identification
2. **Docking with gnina** - Single receptor, single ligand
3. **Complex MD setup** - System building, solvation, equilibration
4. **MMPBSA analysis** - Basic binding free energy

### Phase 2: Automation (Differentiators)

1. **Slash commands** - One command per stage
2. **Script generalization** - CLI flags, config files
3. **HPC Slurm support** - Job submission
4. **Checkpoint system** - Resume capability

### Phase 3: Scale (Differentiators)

1. **Multi-ligand processing** - Parallel docking
2. **Ensemble docking** - Multiple receptor conformations
3. **Agent orchestration** - Multi-agent workflow

### Defer to Post-MVP

- Ligand preparation automation
- ffnonbond.itp edits
- Advanced visualization
- Cloud deployment

## Confidence Assessment

| Area | Confidence | Reason |
|------|------------|--------|
| Table Stakes | HIGH | Based on standard computational chemistry workflow |
| Differentiators | MEDIUM | Surveyed workflow tools; some are project-specific |
| Anti-Features | HIGH | Explicitly scoped in project requirements |
| Dependencies | HIGH | Well-established pipeline order |

## Sources

- Project context: autoEnsmblDockMD AGENTS.md, WORKFLOW.md, PROJECT.md
- Domain knowledge: Standard computational chemistry pipeline (receptor → ligand → docking → MD → MMPBSA)
- Software documentation: GROMACS, gnina, gmx_MMPBSA
- Workflow patterns: HPC job scheduling, checkpoint/resume patterns