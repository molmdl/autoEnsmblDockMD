---
name: aedmd-dock-run
description: Use when running gnina ensemble docking in targeted or blind mode after receptor ensemble preparation and ligand setup.
license: MIT
compatibility: Requires gnina, gromacs 2022+, python 3.10+
metadata:
  author: autoEnsmblDockMD
  version: "1.0"
  agent: runner
  stage: docking_run
---

# Ensemble Docking Execution

This skill executes ligand conversion/prep and gnina docking against receptor ensembles using configuration-driven mode selection (`blind`, `targeted`, or validation `test`).

## When to use this skill
- Receptor ensemble structures are ready and you need docking results.
- You need targeted docking with reference-ligand autoboxing.
- You need blind docking for exploratory binding-site discovery.
- You want standardized docking reports and ranked poses.

## Prerequisites
- Receptor ensemble files are available for docking.
- Ligand inputs are present in configured docking directories.
- `config.ini` contains `[dock]` and `[docking]` sections.

## Usage
Command: `scripts/commands/aedmd-dock-run.sh --config config.ini`
Agent dispatch: `python -m scripts.agents --agent runner --input handoff.json`

## Parameters
| Parameter | Config Key | CLI Flag | Default | Description |
|-----------|------------|----------|---------|-------------|
| Docking mode | `docking.mode` | `--mode` | `blind` | Selects gnina workflow: `blind`, `targeted`, or `test`. |
| Dock directory | `docking.dock_dir` | `--dock-dir` | `${general:workdir}/dock` | Workspace for receptor/ligand docking artifacts. |
| Ligand pattern | `docking.ligand_pattern` | `--ligand-pattern` | `lig*` | Ligand discovery pattern under `docking.ligands_dir`. |
| Exhaustiveness | `docking.exhaustiveness` | `--exhaustiveness` | `100` | gnina search thoroughness. |
| Number of modes | `docking.num_modes` | `--num-modes` | `32` | Maximum poses generated per docking run. |
| Autobox padding | `docking.autobox_add` | `--autobox-add` | `4` | Padding around autobox ligand or receptor. |
| Reference ligand | `docking.reference_ligand` | `--reference-ligand` | *(empty; required for `mode=targeted`)* | Path to reference ligand structure for targeted/test mode validation and optional autobox source. |
| Autobox ligand source | `docking.autobox_ligand` | `--autobox-ligand` | `receptor` | Autobox source selector: `receptor` (box from receptor), or path to reference ligand structure file. |

### Targeted Mode Parameter Clarification

For `mode=targeted` or `mode=test`:

- **`reference_ligand`**: File path to the reference ligand structure (used for redocking validation in test mode, and available as autobox source in targeted mode).
- **`autobox_ligand`**: Controls which structure defines the docking box:
  - `receptor`: Box centered on each receptor conformer (default for blind mode).
  - Path to file: Box centered on specified reference ligand (typical for targeted mode).

**Common targeted workflow:** Set `autobox_ligand = ${docking:reference_ligand}` to dock around the reference binding pocket consistently across ensemble.

> **Note:** `mode=targeted` requires `autobox_ligand` to specify a reference structure path (not `receptor`), otherwise behavior defaults to blind-like autoboxing per receptor.

## Expected Output
- Docking poses/logs under `dock/LIGAND_ID/` directories.
- Ranked docking report such as `${docking.report_output}`.
- Handoff record at `.handoffs/docking_run.json`.

Wrapper note:

- `scripts/commands/aedmd-dock-run.sh` dispatches canonical stage token `docking_run`.
- `scripts/commands/common.sh` may also expose compatibility alias handoff names for older tooling.

## Troubleshooting
- `gnina` not found: source `scripts/setenv.sh` and verify CLI availability.
- No receptors discovered: validate `docking.receptor_dir` and receptor prefix.
- Targeted mode mis-boxed: confirm `docking.reference_ligand` and `autobox_ligand` settings.
