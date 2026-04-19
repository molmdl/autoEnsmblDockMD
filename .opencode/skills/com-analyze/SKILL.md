# Skill: com-analyze
**Stage:** complex_analysis
**Agent:** runner

## Capability
Perform post-MD complex trajectory analysis to generate RMSD, RMSF, hydrogen-bond, and contact metrics for ligand comparison. Produce standardized plots and summary artifacts for validation and reporting.

## Parameters
| Parameter | Config Key | Required | Description |
|-----------|------------|----------|-------------|
| Output subdirectory | `analysis.output_subdir` | Yes | Per-ligand subdirectory where analysis artifacts are written. |
| Run RMSD block | `analysis.run_rmsd` | Yes | Enable RMSD calculations and associated plot/output generation. |
| Run RMSF block | `analysis.run_rmsf` | Yes | Enable RMSF calculations and associated plot/output generation. |
| Run H-bond block | `analysis.run_hbond` | Yes | Enable hydrogen-bond analysis between configured groups. |
| Run advanced block | `analysis.run_advanced` | Yes | Enable MDAnalysis-based advanced analysis pipeline. |
| Plot format | `analysis.plot_format` | Yes | Image format for generated analysis plots (e.g., `png`). |
| Plot DPI | `analysis.plot_dpi` | Yes | Resolution used for plot rendering outputs. |
| Contact cutoff | `analysis.contact_cutoff` | Yes | Distance threshold (Å) for contact calculations. |
| RMSD reference group | `analysis.gmx_rmsd_ref_group` | Yes | GROMACS group ID used as RMSD reference selection. |
| H-bond group B | `analysis.gmx_hbond_group_b` | Yes | GROMACS group ID for ligand/partner in H-bond analysis. |

## Scripts
| Script | Purpose |
|--------|---------|
| `scripts/commands/com-analyze.sh` | Command entrypoint that dispatches complex analysis workflow. |
| `scripts/com/3_ana.sh` | Unified GROMACS + Python analysis runner for post-MD metrics. |
| `scripts/com/3_com_ana_trj.py` | Advanced trajectory-analysis core for contact-centric metrics. |
| `scripts/com/3_selection_defaults.py` | Default atom/group selection helper for analysis routines. |

## Success Criteria
- Requested analysis blocks complete and generate expected plots/data under configured output directories.
- Stage handoff `.handoffs/complex_analysis.json` records successful analysis completion and artifact paths.

## Usage Example
Slash command: `/com-analyze --config config.ini`

Agent invocation: `python -m scripts.agents --agent runner --input handoff.json`

## Workflow
1. Validate trajectory/topology inputs and required `[analysis]` configuration keys.
2. Resolve target ligands and analysis toggles (RMSD/RMSF/H-bond/advanced).
3. Run configured analysis blocks and generate per-ligand data/plots.
4. Aggregate outputs and verify expected artifact files are present.
5. Emit analysis handoff metadata for checker review.
6. If outputs are incomplete, inspect group IDs, selection defaults, and advanced-analysis settings.
