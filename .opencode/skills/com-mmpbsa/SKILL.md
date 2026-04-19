# Skill: com-mmpbsa
**Stage:** complex_mmpbsa
**Agent:** runner

## Capability
Calculate ligand binding free energies from completed complex MD trajectories using chunked MM/PBSA workflows. Prepare trajectory/index inputs and execute configured MM/PBSA jobs for scalable throughput.

## Parameters
| Parameter | Config Key | Required | Description |
|-----------|------------|----------|-------------|
| MM/PBSA workdir | `mmpbsa.workdir` | Yes | Root directory containing ligand MD outputs used for MM/PBSA. |
| Ligand source dir | `mmpbsa.ligand_dir` | Yes | Directory scanned for ligand targets for MM/PBSA execution. |
| Ligand selector | `mmpbsa.ligand_pattern` | Yes | Pattern used to select ligand folders to process. |
| Chunk count | `mmpbsa.n_chunks` | Yes | Number of trajectory chunks per trial for parallel MM/PBSA jobs. |
| Chunk prefix | `mmpbsa.chunk_dir_prefix` | Yes | Prefix used when creating per-chunk MM/PBSA directories. |
| Receptor group | `mmpbsa.receptor_group` | Yes | Index group name for receptor atoms. |
| Ligand group | `mmpbsa.ligand_group` | Yes | Index group name for ligand atoms. |
| MM/PBSA input file | `mmpbsa.mmpbsa_input` | Yes | Input configuration file consumed by gmx_MMPBSA runs. |
| MPI ranks | `mmpbsa.mpi_ranks` | Yes | MPI ranks used for chunk-level MM/PBSA execution. |
| Force-field selector | `mmpbsa.ff` | Yes | Force-field mode controlling topology-selection logic. |

## Scripts
| Script | Purpose |
|--------|---------|
| `scripts/commands/com-mmpbsa.sh` | Command entrypoint that dispatches MM/PBSA workflow. |
| `scripts/com/2_run_mmpbsa.sh` | Orchestrate trajectory prep and chunked MM/PBSA submission flow. |
| `scripts/com/2_trj4mmpbsa.sh` | Prepare trajectory/index files for chunk-based MM/PBSA jobs. |
| `scripts/com/2_sub_mmpbsa.sh` | Submit chunk array jobs for MM/PBSA execution. |
| `scripts/com/2_mmpbsa.sh` | Execute a chunk-level MM/PBSA calculation wrapper. |

## Success Criteria
- MM/PBSA result files are generated for target ligands with chunk jobs completing successfully.
- Stage handoff `.handoffs/complex_mmpbsa.json` reports completion and output paths for review.

## Usage Example
Slash command: `/com-mmpbsa --config config.ini`

Agent invocation: `python -m scripts.agents --agent runner --input handoff.json`

## Workflow
1. Validate prerequisite MD outputs, topology selection keys, and required `[mmpbsa]` config fields.
2. Resolve ligand targets and prepare trajectories/indexes for chunked MM/PBSA execution.
3. Submit or run chunk-level MM/PBSA jobs using configured CPU/MPI settings.
4. Collect MM/PBSA outputs and verify expected result files/logs exist.
5. Write handoff metadata for downstream validation and analysis.
6. If issues occur, inspect topology consistency, index group definitions, and chunk job logs.
