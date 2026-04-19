---
name: aedmd-com-mmpbsa
description: Use when calculating binding free energies with MM/PBSA from completed complex MD trajectories.
license: MIT
compatibility: Requires gnina, gromacs 2022+, python 3.10+
metadata:
  author: autoEnsmblDockMD
  version: "1.0"
  agent: runner
  stage: complex_mmpbsa
---

# Complex MM/PBSA Calculation

This skill prepares trajectories for MM/PBSA chunking and submits/runs binding free-energy calculations with configured topology and group selections.

## When to use this skill
- Complex MD trajectories are complete and quality-checked.
- You need per-ligand binding energy estimates and decomposition outputs.
- You want chunked MM/PBSA execution for parallel throughput.
- You need standardized handoff outputs for checker/analyzer review.

## Prerequisites
- Production trajectories (`prod_*.xtc`/`prod_*.tpr`) are available.
- Topology selection (AMBER/CHARMM) is configured correctly.
- `config.ini` contains a valid `[mmpbsa]` section.

## Usage
Command: `scripts/commands/aedmd-com-mmpbsa.sh --config config.ini`
Agent dispatch: `python -m scripts.agents --agent runner --input handoff.json`

## Parameters
| Parameter | Config Key | CLI Flag | Default | Description |
|-----------|------------|----------|---------|-------------|
| MM/PBSA workdir | `mmpbsa.workdir` | `--workdir` | `${complex:workdir}` | Ligand directories containing production trajectories. |
| Chunk count | `mmpbsa.n_chunks` | `--n-chunks` | `4` | Number of trajectory chunks per trial for parallel jobs. |
| Receptor group | `mmpbsa.receptor_group` | `--receptor-group` | `Protein` | Group name used in index splitting. |
| Ligand group | `mmpbsa.ligand_group` | `--ligand-group` | `Other` | Group name representing ligand atoms. |
| Group IDs file | `mmpbsa.group_ids_file` | `--group-ids-file` | `mmpbsa_groups.dat` | Persisted receptor/ligand/complex group-ID mapping file. |
| MPI ranks | `mmpbsa.mpi_ranks` | `--mpi-ranks` | `16` | MPI ranks used in MM/PBSA chunk execution. |
| Topology mode | `mmpbsa.ff` | `--ff` | `${complex:ff}` | Force-field mode controlling topology choice logic. |

## Expected Output
- MM/PBSA chunk directories (e.g., `mmpbsa_*/`) with energy outputs.
- Per-ligand MM/PBSA result files and logs.
- Handoff record at `.handoffs/complex_mmpbsa.json`.

Execution model note:

- MM/PBSA chunk submissions are asynchronous in Slurm-backed runs.
- Confirm all chunk jobs are complete before interpreting summary energies.

## Troubleshooting
- Topology mismatch errors: ensure selected topology file matches trajectory system.
- Missing index groups: confirm receptor/ligand groups exist in `index.ndx`.
- Empty results: validate chunk submission completed and logs for each chunk are successful.
