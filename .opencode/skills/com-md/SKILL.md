# Skill: com-md
**Stage:** complex_md
**Agent:** runner

## Capability
Run equilibration and production molecular dynamics for prepared receptor-ligand complexes across ligands and trials. Produce standardized trajectory outputs for MM/PBSA and analysis stages.

## Parameters
| Parameter | Config Key | Required | Description |
|-----------|------------|----------|-------------|
| Production workdir | `production.workdir` | Yes | Root directory containing prepared ligand complex jobs. |
| Ligand source dir | `production.ligand_dir` | Yes | Directory scanned for ligand folders to execute MD runs. |
| Ligand selector | `production.ligand_pattern` | Yes | Pattern used to select ligands for production execution. |
| Number of trials | `production.n_trials` | Yes | Independent production trajectories per ligand. |
| Equilibration stages | `production.n_equilibration_stages` | Yes | Number of additional equilibration stages after `pr0`. |
| MDP directory | `production.mdp_dir` | Yes | Directory containing equilibration and production MDP files. |
| Production MDP | `production.production_mdp` | Yes | MDP file used for production simulation jobs. |
| OpenMP threads | `production.ntomp` | Yes | Thread count passed to GROMACS runtime/jobs. |
| Slurm partition | `production.partition` | Yes | Cluster partition used for production submissions. |
| GPU count | `production.gpus` | Yes | GPUs requested per production job when scheduled on Slurm. |

## Scripts
| Script | Purpose |
|--------|---------|
| `scripts/commands/com-md.sh` | Command entrypoint that dispatches complex MD workflow. |
| `scripts/com/1_pr_prod.sh` | Submit/execute equilibration and production MD runs with dependencies. |

## Success Criteria
- Production outputs (`prod_*.xtc`, `prod_*.tpr`, logs) are generated for configured ligands and trials.
- Stage handoff `.handoffs/complex_md.json` confirms successful MD execution ready for downstream analysis.

## Usage Example
Slash command: `/com-md --config config.ini`

Agent invocation: `python -m scripts.agents --agent runner --input handoff.json`

## Workflow
1. Validate that complex setup artifacts and required production MDP files are present.
2. Resolve ligand targets from `production.ligand_dir` and selection keys.
3. Launch equilibration sequence and production MD trials via configured scheduler/runtime settings.
4. Monitor run completion and verify expected trajectory/topology outputs per ligand.
5. Write handoff metadata for MM/PBSA and trajectory analysis consumers.
6. On failure, inspect `grompp` inputs, scheduler resource constraints, and stability indications in logs.
