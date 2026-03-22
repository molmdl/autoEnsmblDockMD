# Stack Research

**Domain:** Computational Chemistry / Molecular Dynamics Workflow Automation
**Researched:** 2026-03-23
**Confidence:** HIGH

## Recommended Stack

### Core Simulation Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| GROMACS | 2025.4 (or 2026.x) | MD simulations | Industry standard for biomolecular MD. 2025.x is the current stable series with improved performance and GPU acceleration. Version >2022 required per project spec. |
| gnina | 1.3.x | Molecular docking with CNN scoring | Deep learning-enhanced docking. Latest 1.3.x (July 2025) provides CNN scoring for pose prediction. Fork of AutoDock Vina with GPU acceleration. |
| gmx_MMPBSA | 1.6.4+ | Binding free energy calculations | Standard tool for end-state free energy calculations with GROMACS trajectories. Integrates with AmberTools. |

### Analysis & cheminformatics Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| MDAnalysis | 2.10.0+ | Trajectory analysis | The standard Python library for analyzing MD trajectories. Supports GROMACS XTC/TRR/TPR formats. Version 2.10.0 supports NumPy 2.0+ and Python 3.11-3.14. |
| MDTraj | 1.10.0+ | Trajectory analysis (lightweight) | Alternative analysis library. Lighter than MDAnalysis for basic operations. Already in current env.yml. |
| RDKit | 2025.09.6+ | Cheminformatics | Current quarterly release (Q3 2025). Essential for ligand preparation, SMILES handling, and molecular property calculation. Install via conda-forge. |
| parmed | 4.2.2+ | Parameter manipulation | Already in current env.yml. Critical for preparing GROMACS topologies and managing force field parameters. |

### Environment & Package Management

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Conda | Latest | Environment management | Already specified in project. Essential for managing complex scientific stacks with binary dependencies. |
| Python | 3.11+ | Runtime | MDAnalysis 2.10.0+ requires Python 3.11+. Current env.yml specifies >=3.11. |

### Workflow Orchestration (Optional/Deferred)

| Technology | Purpose | When to Use |
|------------|---------|-------------|
| Snakemake | Workflow automation | If full pipeline automation needed beyond current bash scripts. Supports SLURM, Conda integration. |
| Nextflow | Workflow automation | Alternative to Snakemake. Strong HPC support (SLURM, LSF, PBS). Used in nf-core pipelines. |

## Installation

```bash
# Core simulation tools (installed separately, not via pip)
# GROMACS 2025.x - install from source or HPC module
# gnina - pre-built binaries from GitHub releases
# gmx_MMPBSA - via pip (already in env.yml)

# Conda environment (env.yml already exists, update versions)
conda env create -f scripts/env.yml
conda update -n gmxMMPBSA -c conda-forge -c salilab --all

# Key updates to consider:
# - MDAnalysis: 2.7.0 → 2.10.0 (current stable)
# - RDKit: add from conda-forge for latest quarterly release
# - Python: ensure 3.11+ (already specified)
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| GROMACS 2025.x | OpenMM | If GPU-only workstation and no HPC access. OpenMM has better GPU performance but less HPC scheduler integration. |
| MDAnalysis | MDTraj | For basic trajectory operations where MDAnalysis overhead is too high. MDTraj is faster but has fewer analysis features. |
| gnina | AutoDock Vina 1.2+ | If CNN scoring not needed and simpler interface preferred. Vina is well-validated but lacks gnina's deep learning enhancement. |
| gmx_MMPBSA | FESetup + MMGBSA | If prefer modular approach over integrated gmx_MMPBSA tool. FESetup offers more flexibility but requires more configuration. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| GROMACS 2022.x (older) | Older version, missing 2025 performance improvements | GROMACS 2025.4+ for better GPU utilization and new features |
| MDAnalysis <2.7.0 | Older versions have NumPy compatibility issues | MDAnalysis 2.10.0+ with NumPy 2.0 support |
| Python 3.10 or older | Not supported by MDAnalysis 2.10.0+ | Python 3.11+ (already in env.yml) |
| MMTF-based workflows | Format deprecated in MDAnalysis 3.0 | Use PDB, CIF, or other supported formats |

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| GROMACS 2025.x | gmx_MMPBSA 1.6.x, MDAnalysis 2.7.0+ | Full TPR support |
| gnina 1.3.x | OpenBabel 3.1.2+ | Required for ligand processing |
| gmx_MMPBSA 1.6.x | AmberTools >=20, GROMACS any 202x | Check AmberTools version in env.yml (23.6) |
| MDAnalysis 2.10.0 | NumPy 1.26.x to 2.x | Supports both NumPy versions |
| RDKit 2025.x | Python 3.11+ | Quarterly releases need recent Python |

## Stack Patterns by Use Case

**If running on HPC (Slurm):**
- Use HPC module versions of GROMACS where available
- Keep bash scripts for job submission (current approach)
- Consider Snakemake for complex multi-stage workflows later

**If running locally with GPU:**
- Use GROMACS with CUDA support
- gnina for GPU-accelerated docking
- Ensure conda environment has proper GPU-enabled packages

**If need ligand preparation automation (future):**
- Add RDKit to env.yml for SMILES processing
- OpenBabel already needed by gnina
- Consider PyMOL for visualization if added later

## Sources

- GROMACS Documentation — https://manual.gromacs.org/documentation/ (2025 series current)
- gnina GitHub — https://github.com/gnina/gnina (v1.3.2 latest release)
- gmx_MMPBSA GitHub — https://github.com/Valdes-Tresanco-MS/gmx_MMPBSA (v1.6.4 latest)
- MDAnalysis Releases — https://github.com/MDAnalysis/mdanalysis/releases (2.10.0 current)
- RDKit Documentation — https://www.rdkit.org/docs/ (2025.09.6 quarterly release)
- Snakemake — https://snakemake.github.io/ (workflow automation)

---

*Stack research for: Molecular Docking and MD Simulation Workflow Automation*
*Researched: 2026-03-23*