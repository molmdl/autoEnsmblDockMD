---
name: aedmd-com-setup
description: Use when preparing receptor-ligand complex systems after docking, including topology assembly, solvation, ionization, and minimization setup.
license: MIT
compatibility: Requires gnina, gromacs 2022+, python 3.10+
metadata:
  author: autoEnsmblDockMD
  version: "1.0"
  agent: runner
  stage: complex_prep
---

# Complex System Preparation

This skill converts docked poses into simulation-ready receptor-ligand complexes and prepares solvated/ionized GROMACS systems for production MD.

## When to use this skill
- Docking poses are ready and you need MD-ready complex systems.
- You need topology assembly for AMBER or CHARMM complex workflows.
- You want automated solvent box and ion preparation for all ligands.
- You are preparing inputs for the `aedmd-com-md` stage.

## Prerequisites
- Docking outputs exist for target ligands.
- Ligand topology/parameter files are available as required by selected force field.
- `config.ini` contains `[complex]` (and relevant `dock2com*`) sections.

## Usage
Command: `scripts/commands/aedmd-com-setup.sh --config config.ini`
Agent dispatch: `python -m scripts.agents --agent runner --input handoff.json`

## Parameters
| Parameter | Config Key | CLI Flag | Default | Description |
|-----------|------------|----------|---------|-------------|
| Complex workdir | `complex.workdir` | `--workdir` | `${general:workdir}/com` | Output root for prepared complex systems. |
| Force-field mode | `complex.mode` | `--mode` | `charmm` | Complex prep mode (`amber` or `charmm`). |
| Ligand selector | `complex.ligand_pattern` | `--ligand-pattern` | `lig*` | Ligand folders to process for setup. |
| Receptor GRO | `complex.receptor_gro` | `--receptor-gro` | `${general:workdir}/rec/prot.gro` | Receptor coordinates for assembly. |
| Receptor TOP | `complex.receptor_top` | `--receptor-top` | `${general:workdir}/rec/topol.top` | Receptor topology for merge operations. |
| Box distance | `complex.box_distance` | `--box-distance` | `1.0` | Solvation box distance in nm. |

## Expected Output
- Prepared ligand-specific complex directories under `com/`.
- GROMACS topology/coordinates (`sys.top`, `.gro`, index) for MD initialization.
- Handoff record at `.handoffs/complex_prep.json`.

## Troubleshooting
- Topology merge failures: verify ligand `.itp` compatibility with selected mode.
- Solvation/ionization errors: check box dimensions and solvent model settings.
- AMBER-specific issues: confirm `complex.bypass_script` is available and executable.
