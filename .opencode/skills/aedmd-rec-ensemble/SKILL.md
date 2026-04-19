---
name: aedmd-rec-ensemble
description: Use when preparing receptor ensembles from a receptor PDB through preparation, receptor MD sampling, clustering, and structure alignment for downstream docking.
license: MIT
compatibility: Requires gnina, gromacs 2022+, python 3.10+
metadata:
  author: autoEnsmblDockMD
  version: "1.0"
  agent: runner
  stage: receptor_prep
---

# Receptor Ensemble Generation

This skill orchestrates receptor preparation, equilibration/production sampling, clustering, and alignment to produce a structurally diverse aligned receptor ensemble for docking.

## When to use this skill
- You need to generate receptor conformers from a new receptor PDB.
- You are starting a new docking campaign and `rec/aligned/` does not exist.
- You want reproducible ensemble generation using configured Slurm/local settings.
- You need aligned receptor structures before running `aedmd-dock-run`.

## Prerequisites
- Receptor PDB input exists in the receptor workspace.
- `config.ini` contains a valid `[receptor]` section.
- Environment is prepared with `source scripts/setenv.sh`.

## Usage
Command: `scripts/commands/aedmd-rec-ensemble.sh --config config.ini`
Agent dispatch: `python -m scripts.agents --agent runner --input handoff.json`

## Parameters
| Parameter | Config Key | CLI Flag | Default | Description |
|-----------|------------|----------|---------|-------------|
| Workspace root | `general.workdir` | `--workdir` | `./work/test` | Root workspace containing `rec/`, `dock/`, and related stage folders. |
| Receptor PDB | `receptor.input_pdb` | `--input-pdb` | `receptor.pdb` | Input receptor structure used for preparation. |
| Force field | `receptor.ff` | `--ff` | `charmm36` | Protein force field passed to receptor setup. |
| Trials | `receptor.n_trials` | `--n-trials` | `4` | Number of receptor production trials for ensemble sampling. |
| Ensemble size | `receptor.ensemble_size` | `--ensemble-size` | `10` | Number of clustered conformers to export. |
| Align reference | `receptor.align_reference` | `--align-reference` | `${general:workdir}/dock/ref.pdb` | Reference structure for alignment. |

## Expected Output
- Receptor trajectories and clustering products under `rec/`.
- Aligned ensemble PDBs under `rec/aligned/`.
- Handoff record at `.handoffs/receptor_prep.json`.

## Troubleshooting
- Missing receptor file: confirm `receptor.input_pdb` exists in `receptor.workdir`.
- Clustering fails: verify trajectory files were produced by receptor MD trials.
- Alignment errors: check `receptor.align_reference` path and atom selection compatibility.
