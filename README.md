# autoEnsmblDockMD

![Status: Experimental Agent Support](https://img.shields.io/badge/agents-experimental-orange)

Automated, reproducible ensemble docking → complex MD → MM/PBSA workflow toolkit built around GROMACS, gnina, and gmx_MMPBSA.

## What is this?

`autoEnsmblDockMD` is a script-first pipeline for structure-based screening and post-docking evaluation.
It combines receptor ensemble generation, ligand docking against multiple receptor conformers, complex simulation preparation, production molecular dynamics, and MM/PBSA free-energy estimation in one coherent workflow.
The project is designed for reproducibility and practical execution on both local machines and Slurm-based HPC systems.
Agent/slash-command support exists to assist orchestration, but the validated baseline remains the script-driven workflow.

## Quick Start (target: <5 minutes to first run)

These steps get you from clone to a runnable pipeline workspace quickly.

### 1) Clone repository

```bash
git clone https://github.com/molmdl/autoEnsmblDockMD.git
cd autoEnsmblDockMD
```

### 2) Create and activate Conda environment

```bash
conda env create -f env.yml
conda activate autoEnsmblDockMD
```

### 3) Load project environment

```bash
source ./scripts/setenv.sh
```

### 4) Create a run workspace and copy required inputs

```bash
mkdir -p work/test
cp scripts/config.ini.template work/test/config.ini
```

Then place your receptor/ligand/topology/MDP inputs in the workspace layout expected by your selected mode.

### 5) Configure `config.ini`

Edit `work/test/config.ini` (or your chosen run config) to set:

- `workdir`
- receptor input paths
- docking mode (`blind`, `targeted`, or `test`)
- force-field and stage-specific settings

### 6) Validate and run

```bash
bash scripts/run_pipeline.sh --config work/test/config.ini --list-stages
bash scripts/run_pipeline.sh --config work/test/config.ini
```

For stage-by-stage execution and full script details, see [WORKFLOW.md](./WORKFLOW.md).

## Pipeline Overview

The pipeline follows six computational stages after input preparation:

1. **Receptor Ensemble Generation**  
   Prepare receptor systems, run receptor MD sampling, and cluster trajectories into representative conformers.

2. **Docking**  
   Convert/prep structures, run gnina across receptor conformers, and rank/select ligand poses.

3. **Complex Setup**  
   Build receptor-ligand complex systems with topology assembly, solvation, ionization, and minimization/equilibration setup.

4. **MD Simulation**  
   Run equilibration chain and production trajectories per ligand/trial.

5. **MM/PBSA**  
   Process trajectories and compute binding free-energy estimates in chunked jobs.

6. **Analysis**  
   Generate RMSD/RMSF/contact/H-bond metrics plus optional fingerprint and archive/rerun helper outputs.

```text
Inputs (receptor + ligands + FF + MDP + config.ini)
                    |
                    v
[0] Input preparation
   scripts/infra/config_loader.sh + scripts/infra/common.sh
                    |
                    v
[1] Receptor ensemble generation
                    |
                    v
              Mode decision
          +--------------------+
          | A: targeted/test   |
          | B: blind           |
          +--------------------+
                    |
                    v
[2] Docking
                    |
                    v
[3] Complex setup
                    |
                    v
[4] MD simulation
                    |
                    v
[5] MM/PBSA
                    |
                    v
[6] Analysis
                    |
                    v
Outputs: ranks + trajectories + energies + reports
```

For complete stage script order and I/O reference, see [WORKFLOW.md](./WORKFLOW.md).

## Two Modes

| Mode | Primary Use | Docking Strategy | Typical FF/Topology Branch |
|---|---|---|---|
| **Mode A** | Reference-pocket workflows | `targeted` or `test` docking around known ligand pocket | Often AMBER-oriented handling |
| **Mode B** | Broader pocket exploration | `blind` docking without fixed pocket box | Often CHARMM36m/CGenFF-oriented handling |

Both modes share the same stage structure; differences are encoded through configuration and topology assets.

## Installation

### Prerequisites

- **Conda** (recommended environment manager)
- **GROMACS ≥ 2022**
- **gnina**
- **gmx_MMPBSA**
- Optional utilities depending on stage usage (for example Open Babel for specific conversion helpers)

### Environment setup

```bash
conda env create -f env.yml && conda activate autoEnsmblDockMD
source scripts/setenv.sh
```

### Validate tool availability

```bash
gmx --version
gnina --help
gmx_MMPBSA --help
```

If any command is missing, install it within your Conda/HPC environment before running production workloads.

## Configuration

The canonical template is [`scripts/config.ini.template`](./scripts/config.ini.template).

Core sections include:

- `[general]` (workspace root)
- `[receptor]` (ensemble generation)
- `[docking]` / `[dock]` (dock execution and conversion helpers)
- `[dock2com]` / `[dock2com_ref]` (pose-to-complex setup)
- `[complex]`, `[production]`, `[mmpbsa]`, `[analysis]`
- `[slurm]` (resource controls)

For detailed field-by-field guidance and practical examples, use [docs/GUIDE.md](./docs/GUIDE.md).

## Full Pipeline Walkthrough

Use the workflow reference as your authoritative stage manual:

1. Review prerequisites and workspace layout in [WORKFLOW.md](./WORKFLOW.md)
2. Create/edit your run config from `scripts/config.ini.template`
3. Initialize environment: `source ./scripts/setenv.sh`
4. Run either full pipeline or selected stage with `scripts/run_pipeline.sh`
5. Inspect stage outputs under your configured `workdir`
6. Continue to MM/PBSA and analysis outputs for ranking/interpretation

If you are new to this project, start with the full run once, then switch to stage-specific reruns as needed.

## Documentation

| Document | Description |
|---|---|
| [WORKFLOW.md](./WORKFLOW.md) | Step-by-step workflow reference and stage script map |
| [docs/GUIDE.md](./docs/GUIDE.md) | Detailed usage guide, configuration details, and troubleshooting |
| [AGENTS.md](./AGENTS.md) | Agent architecture and operating boundaries (experimental support) |

## Experimental: Agent Support

Agent-based execution is available but remains experimental.
The stable baseline for reproducible scientific runs is still the script workflow documented in [WORKFLOW.md](./WORKFLOW.md).
If you use slash commands or agent skills, treat them as orchestration accelerators around the same underlying scripts.
See [AGENTS.md](./AGENTS.md) for role boundaries, handoff pattern, and command mapping.

## Contributing

Contributions are welcome, especially around script robustness, validation, and documentation clarity.
Please preserve configuration-driven behavior and backward-compatible script interfaces when proposing changes.

## License

This project is licensed under **GNU GPL v3.0**. See [LICENSE](./LICENSE).
