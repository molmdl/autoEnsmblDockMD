---
name: aedmd-com-md
description: Use when running equilibration and production molecular dynamics for prepared receptor-ligand complexes.
license: MIT
compatibility: Requires gnina, gromacs 2022+, python 3.10+
metadata:
  author: autoEnsmblDockMD
  version: "1.0"
  agent: runner
  stage: complex_md
---

# Complex MD Production

This skill runs configured equilibration and production MD trials for each prepared complex, producing trajectories and simulation logs for downstream energy and structural analysis.

## When to use this skill
- Complex systems are prepared and ready for simulation.
- You need production trajectories for MM/PBSA and trajectory analysis.
- You want standardized multi-trial MD submission on local or Slurm environments.
- You need to enforce configured MDP protocol across ligands.

## Prerequisites
- Complex preparation outputs exist in `complex.workdir`.
- Required MDP files are available in `production.mdp_dir`.
- `config.ini` contains a valid `[production]` section.

## Usage
Command: `scripts/commands/aedmd-com-md.sh --config config.ini`
Agent dispatch: `python -m scripts.agents --agent runner --input handoff.json`

## Parameters
| Parameter | Config Key | CLI Flag | Default | Description |
|-----------|------------|----------|---------|-------------|
| Production workdir | `production.workdir` | `--workdir` | `${complex:workdir}` | Root directory containing ligand complex jobs. |
| Number of trials | `production.n_trials` | `--n-trials` | `4` | Independent production trajectories per ligand. |
| Equilibration stages | `production.n_equilibration_stages` | `--n-equil-stages` | `1` | Additional equilibration stages before production. |
| Production MDP | `production.production_mdp` | `--production-mdp` | `md.mdp` | MDP file for production run. |
| CPU threads | `production.ntomp` | `--ntomp` | `8` | OpenMP threads used by GROMACS jobs. |
| Slurm partition | `production.partition` | `--partition` | `rtx4090` | Target partition for submitted jobs. |

## Expected Output
- Production trajectories (`prod_*.xtc`/`prod_*.tpr`) and logs per ligand.
- Completed MD run directories under `com/LIGAND_ID/`.
- Handoff record at `.handoffs/complex_md.json`.

## Troubleshooting
- `grompp` failure: validate ligand/receptor topology includes and index groups.
- Jobs pending/failing on Slurm: verify `partition`, GPU, and CPU resource settings.
- Unstable trajectories: review equilibration protocol and restraints in MDP files.
