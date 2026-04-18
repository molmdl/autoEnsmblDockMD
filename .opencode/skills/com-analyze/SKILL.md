---
name: com-analyze
description: Use when analyzing complex MD trajectories to generate RMSD, RMSF, contact, and hydrogen-bond summaries for ligand comparison.
license: MIT
compatibility: Requires gnina, gromacs 2022+, python 3.10+
metadata:
  author: autoEnsmblDockMD
  version: "1.0"
  agent: analyzer
  stage: complex_analysis
---

# Complex Trajectory Analysis

This skill runs standard post-MD analysis workflows and optional advanced trajectory analytics to produce per-ligand metrics, plots, and comparative summaries.

## When to use this skill
- Production MD and (optionally) MM/PBSA are complete.
- You need RMSD/RMSF/H-bond trends for stability assessment.
- You need contact metrics and analysis artifacts for reporting.
- You want standardized analysis outputs before checker validation.

## Prerequisites
- Complex trajectory files exist in ligand run directories.
- `config.ini` contains `[analysis]` settings and valid group selections.
- GROMACS and Python analysis dependencies are available.

## Usage
Command: `scripts/commands/com-analyze.sh --config config.ini`
Agent dispatch: `python -m scripts.agents --agent analyzer --input handoff.json`

## Parameters
| Parameter | Config Key | CLI Flag | Default | Description |
|-----------|------------|----------|---------|-------------|
| Output subdirectory | `analysis.output_subdir` | `--output-subdir` | `analysis` | Folder name for generated analysis artifacts. |
| Run RMSD | `analysis.run_rmsd` | `--run-rmsd` | `true` | Enable RMSD calculations and plots. |
| Run RMSF | `analysis.run_rmsf` | `--run-rmsf` | `true` | Enable RMSF calculations and plots. |
| Run H-bond | `analysis.run_hbond` | `--run-hbond` | `true` | Enable hydrogen-bond analysis between groups. |
| Run advanced | `analysis.run_advanced` | `--run-advanced` | `true` | Enable MDAnalysis-based advanced analytics. |
| Contact cutoff | `analysis.contact_cutoff` | `--contact-cutoff` | `4.5` | Distance cutoff (Å) for contact analysis. |

## Expected Output
- Per-ligand plots/data under `com*/LIGAND_ID/analysis/`.
- Comparative analysis artifacts in `com_ana/` when enabled by workflow.
- Handoff record at `.handoffs/complex_analysis.json`.

## Troubleshooting
- Missing analysis files: verify trajectory and topology filenames expected by analysis scripts.
- Group selection errors: adjust `analysis.gmx_*` group IDs in config.
- Empty advanced metrics: check atom selections and contact cutoff appropriateness.
