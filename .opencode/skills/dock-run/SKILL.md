# Skill: dock-run
**Stage:** docking_run
**Agent:** runner

## Capability
Run ensemble docking using gnina in blind, targeted, or test mode against prepared receptor conformers and ligands. Produce ranked docking outputs and handoff metadata for downstream setup stages.

## Parameters
| Parameter | Config Key | Required | Description |
|-----------|------------|----------|-------------|
| Workspace root | `general.workdir` | Yes | Root workspace that contains docking directories and shared stage outputs. |
| Docking workdir | `docking.dock_dir` | Yes | Main directory for receptor/ligand docking artifacts and reports. |
| Docking mode | `docking.mode` | Yes | Docking mode selector: `blind`, `targeted`, or `test`. |
| Ligand source directory | `docking.ligands_dir` | Yes | Directory from which ligands are discovered for docking jobs. |
| Ligand discovery pattern | `docking.ligand_pattern` | Yes | Pattern used to select ligand folders/files. |
| Receptor directory | `docking.receptor_dir` | Yes | Directory containing receptor conformers used for gnina runs. |
| Exhaustiveness | `docking.exhaustiveness` | Yes | gnina search thoroughness for each ligand-receptor pair. |
| Number of modes | `docking.num_modes` | Yes | Maximum poses generated per docking run. |
| Autobox padding | `docking.autobox_add` | Yes | Padding added to autobox dimensions. |
| Report output | `docking.report_output` | Yes | Output path for ranked docking report generation. |

## Scripts
| Script | Purpose |
|--------|---------|
| `scripts/commands/dock-run.sh` | Command entrypoint that dispatches docking workflow. |
| `scripts/dock/1_rec4dock.sh` | Prepare receptor ensemble files in docking workspace. |
| `scripts/dock/2_gnina.sh` | Execute gnina docking in configured mode. |
| `scripts/dock/3_dock_report.sh` | Parse pose scores and create ranked docking report. |

## Success Criteria
- Docking pose outputs and logs are generated for selected ligands under docking workspace folders.
- Stage handoff `.handoffs/docking_run.json` indicates successful docking and report generation.

## Usage Example
Slash command: `/dock-run --config config.ini`

Agent invocation: `python -m scripts.agents --agent runner --input handoff.json`

## Workflow
1. Validate that receptor conformers and ligand inputs exist in configured docking directories.
2. Prepare docking workspace inputs (receptors/ligands) according to mode and config.
3. Run gnina docking with configured search and scoring parameters.
4. Generate ranked docking reports and persist output artifacts.
5. Emit handoff metadata for downstream complex setup.
6. Handle common failures by checking gnina availability, receptor discovery paths, and targeted-mode autobox settings.
