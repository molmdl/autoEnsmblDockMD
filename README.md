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
conda env create -f scripts/env.yml
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

> [!IMPORTANT]
> `scripts/run_pipeline.sh` dispatches stage scripts in sequence, but several stages are asynchronous on Slurm-backed runs.
> In particular, receptor and complex production/MM-PBSA submission stages may return after `sbatch` submission rather than waiting for job completion.
> Before proceeding to downstream dependent stages, verify completion with `squeue`/`sacct` and stage output checks.

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
  - [Miniconda](https://www.anaconda.com/docs/getting-started/miniconda/install/overview)) 
- **GROMACS ≥ 2022** (note: the Amber FF provided in the example is for gromacs < 2025, tested with 2023.5)
  - [GROMACS official website](https://www.gromacs.org/)
- **gnina** (tested with v1.1, since our hardware CUDA does not support newer version)
  - [Gnina github](https://github.com/gnina/gnina)
- **gmx_MMPBSA** (automatically installed if you create the conda environment using `scripts/env.yml`)
  - [gmx_MMPBSA Documentation](https://valdes-tresanco-ms.github.io/gmx_MMPBSA/dev/)
- Optional utilities depending on stage usage (for example Open Babel for specific conversion helpers)

### Environment setup

```bash
conda env create -f scripts/env.yml && conda activate autoEnsmblDockMD
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

Async stage note:

- `rec_prod`, `com_prod`, and `com_mmpbsa` commonly submit Slurm jobs and return immediately.
- Treat these as submission checkpoints; do not assume downstream artifacts are ready at wrapper return time.
- Use `squeue -u "$USER"` (live queue) and `sacct -j <jobid>` (historical status) before continuing.

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
Skill definitions are stored at `.opencode/skills/aedmd-{name}/SKILL.md` and use YAML frontmatter (`name`, `description`, `license`, `compatibility`, `metadata`).
Project slash commands use the `aedmd-` namespace (for example `/aedmd-status`, `/aedmd-dock-run`, and `/aedmd-com-setup`) to avoid collisions with generic command names.
See [AGENTS.md](./AGENTS.md) for role boundaries, handoff pattern, and command mapping.

## Contributing

Contributions are welcome, especially around script robustness, validation, and documentation clarity.
Please preserve configuration-driven behavior and backward-compatible script interfaces when proposing changes.

## License

This project is licensed under **GNU GPL v3.0**. See [LICENSE](./LICENSE).

## Citations

If you use `autoEnsmblDockMD` in your research, please cite the relevant tools and methods:

### GROMACS
- Abraham, M. J., Murtola, T., Schulz, R., Páll, S., Smith, J. C., Hess, B., & Lindahl, E. (2015). GROMACS: High performance molecular simulations through multi-level parallelism from laptops to supercomputers. *SoftwareX*, 1-2, 19-25. https://doi.org/10.1016/j.softx.2015.06.001
- Berendsen, H. J. C., van der Spoel, D., & van Drunen, R. (1995). GROMACS: A message-passing parallel molecular dynamics implementation. *Computer Physics Communications*, 91(1-3), 43-56. https://doi.org/10.1016/0010-4655(95)00042-E

### gnina
- McNutt, A. T., Li, Y., Meli, R., Aggarwal, R., & Koes, D. R. (2025). GNINA 1.3: the next increment in molecular docking with deep learning. *Journal of Cheminformatics*, 17, 28. https://doi.org/10.1186/s13321-025-00973-x
- McNutt, A. T., Francoeur, P., Aggarwal, R., Masuda, T., Meli, R., Ragoza, M., Sunseri, J., & Koes, D. R. (2021). GNINA 1.0: Molecular docking with deep learning. *Journal of Cheminformatics*, 13, 43. https://doi.org/10.1186/s13321-021-00522-2

### gmx_MMPBSA
- Valdés-Tresanco, M. S., Valdés-Tresanco, M. E., Valiente, P. A., & Moreno, E. (2021). gmx_MMPBSA: A new tool to perform end-state free energy calculations with GROMACS. *Journal of Chemical Theory and Computation*, 17(10), 6281-6291. https://doi.org/10.1021/acs.jctc.1c00645

### MDAnalysis
- Michaud-Agrawal, N., Denning, E. J., Woolf, T. B., & Beckstein, O. (2011). MDAnalysis: A toolkit for the analysis of molecular dynamics simulations. *Journal of Computational Chemistry*, 32(10), 2319-2327. https://doi.org/10.1002/jcc.21787
- Gowers, R. J., Linke, M., Barnoud, J., Reddy, T. J. E., Melo, M. N., Seyler, S. L., Domański, J., Dotson, D. L., Buchoux, S., Kenney, I. M., & Beckstein, O. (2016). MDAnalysis: A Python package for the rapid analysis of molecular dynamics simulations. *Proceedings of the 15th Python in Science Conference*, 98-105. https://doi.org/10.25080/Majora-629e541a-00e
