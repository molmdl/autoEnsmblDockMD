# Skill: rec-ensemble
**Stage:** receptor_cluster
**Agent:** runner

## Capability
Prepare a receptor ensemble from a receptor PDB through setup, MD sampling, clustering, and structural alignment. Use this to produce reproducible aligned receptor conformers for downstream docking.

## Parameters
| Parameter | Config Key | Required | Description |
|-----------|------------|----------|-------------|
| Workspace root | `general.workdir` | Yes | Root workspace containing receptor, docking, and downstream stage directories. |
| Receptor workdir | `receptor.workdir` | Yes | Receptor-stage working directory where preparation and MD artifacts are generated. |
| Receptor PDB | `receptor.input_pdb` | Yes | Input receptor structure used for protonation, solvation, and setup. |
| Force field | `receptor.ff` | Yes | Protein force field passed to receptor preparation (`pdb2gmx`) steps. |
| Water model | `receptor.water_model` | Yes | Water model used during receptor system preparation. |
| Number of trials | `receptor.n_trials` | Yes | Number of receptor production trials for ensemble sampling. |
| Ensemble size | `receptor.ensemble_size` | Yes | Number of clustered conformers expected/exported for docking. |
| Alignment inputs | `receptor.align_structures` | Yes | Structure list/pattern used by alignment utility. |
| Alignment reference | `receptor.align_reference` | Yes | Reference structure used to align receptor conformers. |
| Alignment output dir | `receptor.align_output_dir` | Yes | Destination directory for aligned ensemble structures. |

## Scripts
| Script | Purpose |
|--------|---------|
| `scripts/commands/rec-ensemble.sh` | Command entrypoint that dispatches receptor ensemble workflow. |
| `scripts/run_pipeline.sh --stage rec_prep` | Receptor preparation, solvation, and equilibration setup. |
| `scripts/run_pipeline.sh --stage rec_md` | Receptor production MD sampling runs. |
| `scripts/run_pipeline.sh --stage rec_cluster` | Cluster sampled receptor trajectories into ensemble conformers. |
| `scripts/rec/5_align.py` | Align receptor conformers to a common reference frame. |

## Success Criteria
- Aligned receptor ensemble structures are generated under `receptor.align_output_dir`.
- Stage handoff `.handoffs/receptor_cluster.json` reports successful completion with expected outputs.

## Usage Example
Slash command: `/rec-ensemble --config config.ini`

Agent invocation: `python -m scripts.agents --agent runner --input handoff.json`

## Workflow
1. Validate prerequisites: receptor input exists, environment is sourced, and `[receptor]` config keys are present.
2. Run receptor preparation and equilibration setup from configured `receptor.workdir`.
3. Launch receptor MD sampling using configured `receptor.n_trials` and compute settings.
4. Merge/analyze trajectories and cluster conformations to target `receptor.ensemble_size`.
5. Align exported receptor structures to `receptor.align_reference` into `receptor.align_output_dir`.
6. Write handoff metadata for downstream docking consumption.

Troubleshooting:
- Missing receptor file: confirm `receptor.input_pdb` exists in `receptor.workdir`.
- Clustering fails: verify trajectory files were produced by receptor MD trials.
- Alignment errors: check `receptor.align_reference` path and atom-selection compatibility.
