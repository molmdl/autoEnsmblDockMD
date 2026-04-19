# Skill: com-setup
**Stage:** complex_prep
**Agent:** runner

## Capability
Convert docked poses into simulation-ready receptor-ligand complexes and prepare solvated, ionized systems for MD. Support both AMBER and CHARMM topology assembly paths through configuration.

## Parameters
| Parameter | Config Key | Required | Description |
|-----------|------------|----------|-------------|
| Workspace root | `general.workdir` | Yes | Root workspace containing docking outputs and complex setup directories. |
| Complex workdir | `complex.workdir` | Yes | Target directory where prepared complex systems are generated. |
| Force-field mode | `complex.mode` | Yes | Complex preparation mode (`amber` or `charmm`). |
| Ligand source dir | `complex.ligand_dir` | Yes | Directory containing ligands/docked poses used for setup. |
| Ligand selector | `complex.ligand_pattern` | Yes | Pattern used to discover ligands for setup batch processing. |
| Receptor coordinates | `complex.receptor_gro` | Yes | Receptor coordinates used for complex assembly. |
| Receptor topology | `complex.receptor_top` | Yes | Receptor topology merged with ligand parameters. |
| Force field tag | `complex.ff` | Yes | Force field family used to derive setup defaults and includes. |
| Solvation box distance | `complex.box_distance` | Yes | Solvation box buffer distance (nm) for system preparation. |
| Ion concentration | `complex.ion_conc` | Yes | Target ion concentration (M) used during neutralization/ionization. |

## Scripts
| Script | Purpose |
|--------|---------|
| `scripts/commands/com-setup.sh` | Command entrypoint that dispatches complex setup workflow. |
| `scripts/dock/4_dock2com.sh` | Build new-ligand complex inputs from docking poses. |
| `scripts/dock/4_dock2com_ref.sh` | Build reference-ligand complex inputs when required. |
| `scripts/com/0_prep.sh` | Run unified AMBER/CHARMM complex solvation and minimization setup. |

## Success Criteria
- Ligand-specific complex folders are created with valid topology and coordinate files for MD startup.
- Stage handoff `.handoffs/complex_prep.json` indicates successful preparation for downstream production runs.

## Usage Example
Slash command: `/com-setup --config config.ini`

Agent invocation: `python -m scripts.agents --agent runner --input handoff.json`

## Workflow
1. Validate docking outputs, ligand parameters, and required `[complex]`/`[dock2com*]` config keys.
2. Convert selected docked poses into complex-ready ligand/receptor assemblies.
3. Execute complex preparation (`scripts/com/0_prep.sh`) for solvation, ionization, and minimization setup.
4. Confirm required outputs (`sys.top`, coordinates, index/restrained files) are present per ligand.
5. Publish handoff metadata for `com-md` stage consumption.
6. If preparation fails, triage topology-merge compatibility, solvent-box settings, and AMBER bypass utility availability.
