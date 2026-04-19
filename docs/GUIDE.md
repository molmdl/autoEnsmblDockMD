# Detailed Usage Guide

This guide is the human-facing deep reference for configuring and preparing `autoEnsmblDockMD` before running pipeline stages.

## Table of Contents

- [Part 1: Before Running the Pipeline](#part-1-before-running-the-pipeline)
  - [Configuration Reference (`config.ini`)](#configuration-reference-configini)
    - [[general]](#general)
    - [[slurm]](#slurm)
    - [[receptor]](#receptor)
    - [[dock]](#dock)
    - [[docking]](#docking)
    - [[dock2com]](#dock2com)
    - [[dock2com_ref]](#dock2com_ref)
    - [[complex]](#complex)
    - [[production] (MD)](#production-md)
    - [[mmpbsa]](#mmpbsa)
    - [[analysis]](#analysis)
  - [Input File Preparation](#input-file-preparation)
  - [Workspace Setup](#workspace-setup)
- [Part 2: Per-Stage Instructions (placeholder)](#part-2-per-stage-instructions-placeholder)

## Part 1: Before Running the Pipeline

### Configuration Reference (`config.ini`)

Create your runtime config from the template:

```bash
cp scripts/config.ini.template config.ini
```

Type conventions used below: `path`, `string`, `int`, `float`, `bool`, `enum`, `pattern`, `list`.

#### [general]

| Key | Type | Default | Used by stage(s) | Description / mode notes |
| --- | --- | --- | --- | --- |
| `workdir` | path | `./work/test` | All stages | Root workspace for rec/dock/com outputs (Mode A + Mode B). |

#### [slurm]

| Key | Type | Default | Used by stage(s) | Description / mode notes |
| --- | --- | --- | --- | --- |
| `partition` | string | `rtx4090-short` | Receptor + batch jobs | Default Slurm partition for GPU jobs. |
| `ntomp` | int | `8` | Receptor/MD GROMACS runs | OpenMP threads per task. |
| `gpus` | int | `1` | Receptor/MD runs | GPUs requested per job. |
| `cpus_per_task` | int | `8` | CPU-bound scripts | CPU count for scripts using this key. |

#### [receptor]

| Key | Type | Default | Used by stage(s) | Description / mode notes |
| --- | --- | --- | --- | --- |
| `workdir` | path | `${general:workdir}/rec` | Stage 1 | Receptor stage output directory. |
| `input_pdb` | path | `receptor.pdb` | Stage 1 prep | Input receptor structure. |
| `ff` | string | `charmm36` | Stage 1 prep | Force field for `pdb2gmx` (AMBER/CHARMM accepted). |
| `water_model` | string | `tip3p` | Stage 1 prep | Water model for receptor system. |
| `box_distance` | float | `1.0` | Stage 1 prep | Solvation box margin (nm). |
| `ion_conc` | float | `0.15` | Stage 1 prep | Ion concentration (M). |
| `mdp_dir` | path | `./mdp/rec` | Stage 1 prep/MD | Receptor MDP directory. |
| `em_mdp` | string | `em.mdp` | Stage 1 prep | Energy minimization MDP filename. |
| `pr_pos_mdp` | string | `pr_pos.mdp` | Stage 1 prep | Position-restrained equilibration MDP. |
| `pr0_mdp` | string | `pr0.mdp` | Stage 1 production | Initial receptor production/equilibration MDP. |
| `n_trials` | int | `4` | Stage 1 production | Number of receptor MD trials (Slurm array size). |
| `ensemble_size` | int | `10` | Stage 1 clustering | Target number of representative conformers. |
| `ensemble_prefix` | string | `rec` | Stage 1 + Stage 2 | Prefix for exported receptor conformers. |
| `receptor_ext` | string | *(empty)* | Stage 2 prep | Optional extension override for copied ensemble files. |
| `receptor_prefix` | string | `rec` | Stage 2 docking | Prefix used when discovering receptor files for docking. |
| `ensemble_dir` | path | `${receptor:workdir}` | Stage 2 prep | Optional explicit receptor ensemble source directory. |
| `analysis_start_ps` | int | `10000` | Stage 1 analysis | Start time for receptor trajectory analysis (ps). |
| `pbc_center_group` | int | `1` | Stage 1 analysis | Group ID for trajectory centering. |
| `fit_group` | int | `4` | Stage 1 analysis | Group ID for trajectory fitting. |
| `rms_group` | int | `4` | Stage 1 analysis | Group ID for RMSD. |
| `rmsf_group_bb` | int | `4` | Stage 1 analysis | Group ID for backbone RMSF. |
| `rmsf_group_noh` | int | `2` | Stage 1 analysis | Group ID for heavy-atom/no-H RMSF. |
| `merged_fit_group` | int | `1` | Stage 1 analysis | Group ID used for merged fit outputs. |
| `merged_out` | string | `apo_50ns_merged.xtc` | Stage 1 analysis | Merged receptor trajectory filename. |
| `merged_fit_out` | string | `apo_50ns_merged_fit.xtc` | Stage 1 analysis | Fitted merged receptor trajectory filename. |
| `cluster_method` | enum | `gromos` | Stage 1 clustering | Clustering algorithm. |
| `cluster_xtc` | string | `apo_50ns_merged_fit.xtc` | Stage 1 clustering | Trajectory used for clustering. |
| `cluster_tpr` | string | `pr_0.tpr` | Stage 1 clustering | Topology/run input for clustering. |
| `cluster_cutoff` | float | `0.2` | Stage 1 clustering | RMSD cutoff for clustering. |
| `cluster_rmsmin` | float | `0.1` | Stage 1 clustering | Minimum RMS criterion. |
| `cluster_group` | int | `1` | Stage 1 clustering | Group ID for clustering operation. |
| `cluster_output` | string | `clusters.xtc` | Stage 1 clustering | Cluster trajectory output file. |
| `write_pdb` | bool | `true` | Stage 1 clustering | Export representative clusters as PDB. |
| `align_structures` | list/pattern | `${receptor:workdir}/rec*.pdb` | Stage 1 align | Files/patterns for MDAnalysis alignment. |
| `align_reference` | path | `${general:workdir}/dock/ref.pdb` | Stage 1 align | Reference structure for alignment (Mode A common). |
| `align_output_dir` | path | `${receptor:workdir}/aligned` | Stage 1 align | Output directory for aligned receptor structures. |
| `align_selection` | string | `backbone` | Stage 1 align | Atom selection expression for alignment. |
| `align_output_prefix` | string | `aln_` | Stage 1 align | Prefix for aligned receptor files. |
| `pdb2pqr_ff` | string | `AMBER` | Stage 1 prep | Force-field family used in protonation step. |
| `ph` | float | `7.4` | Stage 1 prep | Protonation pH target. |

#### [dock]

| Key | Type | Default | Used by stage(s) | Description / mode notes |
| --- | --- | --- | --- | --- |
| `ligand_dir` | path | `${general:workdir}/dock` | Stage 2 conversion | Input directory for ligand conversions. |
| `output_dir` | path | `${general:workdir}/dock` | Stage 2 conversion | Output directory for converted ligand files. |
| `gro_pattern` | pattern | `*.gro` | Stage 2 conversion | GRO discovery pattern. |
| `itp_suffix` | string | `_gmx.top` | Stage 2 conversion | Topology suffix paired with each GRO ligand. |
| `converter_script` | path | `scripts/dock/0_gro_itp_to_mol2.py` | Stage 2 conversion | GRO/ITP → MOL2 converter entrypoint. |
| `sdf_input_dir` | path | `${general:workdir}/dock` | Stage 2 utility | SDF source directory for optional conversion. |
| `sdf_pattern` | pattern | `**/*.sdf` | Stage 2 utility | Recursive SDF discovery pattern. |
| `recurse` | bool | `true` | Stage 2 utility | Enables recursive SDF search. |

#### [docking]

| Key | Type | Default | Used by stage(s) | Description / mode notes |
| --- | --- | --- | --- | --- |
| `dock_dir` | path | `${general:workdir}/dock` | Stage 2 | Docking workspace root. |
| `ligands_dir` | path | `${docking:dock_dir}` | Stage 2 | Ligand source directory for gnina runs. |
| `ligand_pattern` | pattern | `lig*` | Stage 2 | Ligand discovery pattern. |
| `ligand_list` | list | *(empty)* | Stage 2 | Optional explicit ligand list override. |
| `mode` | enum | `blind` | Stage 2 | Docking mode: `blind` (Mode B), `targeted`/`test` (Mode A). |
| `receptor_dir` | path | `${docking:dock_dir}` | Stage 2 | Directory containing receptor conformers. |
| `receptor_source_dir` | path | `${receptor:workdir}` | Stage 2 prep | Optional receptor source before copy/symlink. |
| `receptor_prefix` | string | `rec` | Stage 2 | Prefix used to locate receptor conformers. |
| `link_receptors` | bool | `false` | Stage 2 prep | Symlink receptors instead of copying into dock dir. |
| `reference_ligand` | path | `${docking:dock_dir}/ref.pdb` | Stage 2 | Autobox reference ligand (Mode A targeted/test). |
| `test_receptor` | path | `${docking:receptor_dir}/${docking:receptor_prefix}0.pdb` | Stage 2 test | Receptor for quick test mode runs. |
| `exhaustiveness` | int | `100` | Stage 2 gnina | gnina search exhaustiveness. |
| `num_modes` | int | `32` | Stage 2 gnina | Maximum generated poses per ligand. |
| `autobox_add` | float/int | `4` | Stage 2 gnina | Autobox padding around reference region. |
| `autobox_ligand` | enum/path | `receptor` | Stage 2 gnina | `receptor` or explicit ligand path for autobox definition. |
| `scoring` | enum | `cnn` | Stage 2 gnina | Scoring type (`cnn` or `ad4_scoring`). |
| `addH` | enum | `off` | Stage 2 gnina | Hydrogen add behavior for docking input. |
| `stripH` | enum | `off` | Stage 2 gnina | Hydrogen stripping behavior. |
| `cpu` | int | `8` | Stage 2 gnina | CPU threads for gnina. |
| `min_rmsd_filter` | float/int | `3` | Stage 2 post-process | Pose redundancy filter threshold. |
| `report_output` | path | `${docking:dock_dir}/dock_report.csv` | Stage 2 report | Docking ranking report path. |
| `report_format` | enum | `csv` | Stage 2 report | Docking report output format. |
| `report_top_n` | int | `0` | Stage 2 report | Keep top N rows (0 = keep all). |

#### [dock2com]

| Key | Type | Default | Used by stage(s) | Description / mode notes |
| --- | --- | --- | --- | --- |
| `com_dir` | path | `${general:workdir}/com` | Stage 3 | Output directory for new-ligand complex setup. |
| `ff` | enum | `amber` | Stage 3 | Topology assembly branch (`amber` or `charmm`). |
| `pose_index` | int/string | *(empty)* | Stage 3 | Optional explicit selected pose index. |
| `force_constant` | float/int | `1000` | Stage 3 | Position restraint constant (kJ mol^-1 nm^-2). |
| `rec_top` | path | `${general:workdir}/rec/#topol.top.1#` | Stage 3 | Receptor topology source. |
| `ligand_itp_pattern` | pattern | `{ligand}.itp` | Stage 3 | Pattern for ligand ITP files. |
| `ligand_template_pattern` | pattern | `{ligand}.mol2` | Stage 3 | Pattern for ligand template files. |
| `sdf_pattern` | pattern | `rec*-{ligand}.sdf` | Stage 3 | Pattern for selected docked pose files. |
| `copy_rec_itp` | bool | `true` | Stage 3 | Copy `rec.itp` into each ligand folder when present. |

#### [dock2com_ref]

| Key | Type | Default | Used by stage(s) | Description / mode notes |
| --- | --- | --- | --- | --- |
| `ref_dir` | path | `${general:workdir}/ref` | Stage 3 ref | Reference ligand parameter directory. |
| `ligand_list` | list | *(empty)* | Stage 3 ref | Optional explicit reference ligand list. |
| `ligand_pattern` | pattern | `*` | Stage 3 ref | Pattern for reference ligands. |
| `com_dir` | path | `${general:workdir}/com/ref` | Stage 3 ref | Output directory for reference-ligand complexes. |
| `ff` | enum | `amber` | Stage 3 ref | Topology assembly branch (`amber` or `charmm`). |
| `pose_index` | int/string | *(empty)* | Stage 3 ref | Optional explicit selected pose index. |
| `force_constant` | float/int | `1000` | Stage 3 ref | Position restraint constant. |
| `rec_top` | path | `${general:workdir}/rec/#topol.top.1#` | Stage 3 ref | Receptor topology source. |
| `ligand_itp_pattern` | pattern | `{ligand}.itp` | Stage 3 ref | Pattern for reference ligand ITP files. |
| `ligand_template_pattern` | pattern | `{ligand}.mol2` | Stage 3 ref | Pattern for reference ligand template files. |
| `sdf_pattern` | pattern | `rec*-{ligand}.sdf` | Stage 3 ref | Pattern for selected reference pose SDFs. |
| `copy_rec_itp` | bool | `true` | Stage 3 ref | Copy `rec.itp` into each reference ligand folder. |

#### [complex]

| Key | Type | Default | Used by stage(s) | Description / mode notes |
| --- | --- | --- | --- | --- |
| `workdir` | path | `${general:workdir}/com` | Stage 3/4 | Complex preparation working directory. |
| `mode` | enum | `charmm` | Stage 3 | Complex prep branch (`amber` or `charmm`). |
| `ligand_dir` | path | `${general:workdir}/dock` | Stage 3 | Ligand source for complex assembly. |
| `ligand_pattern` | pattern | `lig*` | Stage 3 | Ligand discovery pattern. |
| `ligand_list` | list | *(empty)* | Stage 3 | Optional explicit ligand list. |
| `receptor_gro` | path | `${general:workdir}/rec/prot.gro` | Stage 3 | Receptor coordinates for assembly. |
| `receptor_top` | path | `${general:workdir}/rec/topol.top` | Stage 3 | Receptor topology for assembly. |
| `ff` | string | `charmm36` | Stage 3/5 | FF tag used for script defaults and MMPBSA topology choice. |
| `ff_include` | path | `charmm36.ff/forcefield.itp` | Stage 3 | `#include` line written into `sys.top`. |
| `water_model` | string | `tip3p` | Stage 3 | Water model for complex setup. |
| `box_distance` | float | `1.0` | Stage 3 | Solvation box margin (nm). |
| `ion_conc` | float | `0.15` | Stage 3 | Ion concentration (M). |
| `mdp_dir` | path | `./mdp/com` | Stage 3/4 | MDP directory for complex prep and production. |
| `em_mdp` | string | `em.mdp` | Stage 3 | Complex minimization MDP. |
| `pr_pos_mdp` | string | `pr.mdp` | Stage 3 | Position-restrained equilibration MDP for complex. |
| `ligand_itp` | string/path | *(empty)* | Stage 3 | Optional explicit ligand ITP filename override. |
| `ligand_gro` | string/path | *(empty)* | Stage 3 | Optional explicit ligand GRO filename override. |
| `bypass_script` | path | `scripts/com/bypass_angle_type3.py` | Stage 3 | AMBER-specific topology bypass helper. |

#### [production] (MD)

| Key | Type | Default | Used by stage(s) | Description / mode notes |
| --- | --- | --- | --- | --- |
| `workdir` | path | `${complex:workdir}` | Stage 4 | Production stage workdir (per ligand). |
| `ligand_dir` | path | `${production:workdir}` | Stage 4 | Ligand directory for production jobs. |
| `ligand_pattern` | pattern | `${complex:ligand_pattern}` | Stage 4 | Ligand discovery pattern. |
| `ligand_list` | list | `${complex:ligand_list}` | Stage 4 | Optional explicit ligand list. |
| `n_trials` | int | `4` | Stage 4 | Number of production trajectories per ligand. |
| `n_equilibration_stages` | int | `1` | Stage 4 | Additional equilibration stages after `pr0`. |
| `equil_input_gro` | string | `pr_pos.gro` | Stage 4 | Initial GRO used for equilibration grompp. |
| `index_file` | string | `index.ndx` | Stage 4/5 | Index filename expected inside ligand folder. |
| `mdp_dir` | path | `./mdp/com` | Stage 4 | Directory containing production/equilibration MDPs. |
| `pr0_mdp` | string | `pr0.mdp` | Stage 4 | First equilibration MDP. |
| `pr_mdp_prefix` | string | `pr` | Stage 4 | Prefix for additional equilibration MDP files. |
| `production_mdp` | string | `md.mdp` | Stage 4 | Production MDP filename. |
| `md_time` | string | `100ns` | Stage 4 | Label for job naming/metadata. |
| `ntomp` | int | `8` | Stage 4 | OpenMP threads override for production jobs. |
| `partition` | string | `rtx4090` | Stage 4 | Slurm partition override for production jobs. |
| `gpus` | int | `1` | Stage 4 | GPU count override for production jobs. |

#### [mmpbsa]

| Key | Type | Default | Used by stage(s) | Description / mode notes |
| --- | --- | --- | --- | --- |
| `workdir` | path | `${complex:workdir}` | Stage 5 | MM/PBSA stage workspace. |
| `ligand_dir` | path | `${mmpbsa:workdir}` | Stage 5 | Ligand directory for MM/PBSA discovery. |
| `ligand_pattern` | pattern | `${complex:ligand_pattern}` | Stage 5 | Ligand discovery pattern. |
| `ligand_list` | list | `${complex:ligand_list}` | Stage 5 | Optional explicit ligand list. |
| `n_chunks` | int | `4` | Stage 5 | Number of chunks per trajectory. |
| `chunk_dir_prefix` | string | `mmpbsa_` | Stage 5 | Prefix for chunk output directories. |
| `receptor_group` | string | `Protein` | Stage 5 | Receptor group name for index handling. |
| `ligand_group` | string | `Other` | Stage 5 | Ligand group name for index handling. |
| `complex_group_name` | string | `Protein_Other` | Stage 5 | Combined group expected for MM/PBSA. |
| `index_file` | string | `index.ndx` | Stage 5 | Index filename used during prep. |
| `source_xtc_pattern` | pattern | `prod_%d.xtc` | Stage 5 | Trial trajectory filename pattern. |
| `source_tpr_pattern` | pattern | `prod_%d.tpr` | Stage 5 | Trial topology filename pattern. |
| `mmpbsa_input` | path | `scripts/com/mmpbsa.in` | Stage 5 | Input config for `gmx_MMPBSA`. |
| `trj_script` | path | `scripts/com/2_trj4mmpbsa.sh` | Stage 5 | Trajectory preprocessing script path. |
| `submit_script` | path | `scripts/com/2_sub_mmpbsa.sh` | Stage 5 | Slurm submit wrapper script path. |
| `mmpbsa_script` | path | `scripts/com/2_mmpbsa.sh` | Stage 5 | Chunk-level MM/PBSA script path. |
| `partition` | string | `cpu` | Stage 5 | CPU partition for MM/PBSA jobs. |
| `cpus_per_task` | int | `16` | Stage 5 | CPUs per MM/PBSA task. |
| `array_parallelism` | int/string | *(empty)* | Stage 5 | Optional Slurm array parallelism cap. |
| `mpi_ranks` | int | `16` | Stage 5 | MPI ranks per MM/PBSA chunk job. |
| `receptor_group_id` | int | `1` | Stage 5 | Optional fixed receptor group ID. |
| `ligand_group_id` | int | `12` | Stage 5 | Optional fixed ligand group ID. |
| `ff` | string | `${complex:ff}` | Stage 5 | FF selector for topology choice (AMBER vs CHARMM). |
| `topology_file` | path | *(empty)* | Stage 5 | Optional explicit topology override. |
| `amber_topology_file` | string | `bypass_sys.top` | Stage 5 | Topology filename for AMBER branch (Mode A typical). |
| `charmm_topology_file` | string | `sys.top` | Stage 5 | Topology filename for CHARMM branch (Mode B typical). |

#### [analysis]

| Key | Type | Default | Used by stage(s) | Description / mode notes |
| --- | --- | --- | --- | --- |
| `output_subdir` | string | `analysis` | Stage 6 | Per-ligand analysis output subdirectory. |
| `run_rmsd` | bool | `true` | Stage 6 | Enable RMSD block. |
| `run_rmsf` | bool | `true` | Stage 6 | Enable RMSF block. |
| `run_hbond` | bool | `true` | Stage 6 | Enable H-bond block. |
| `run_advanced` | bool | `true` | Stage 6 | Enable advanced MDAnalysis contacts/metrics. |
| `plot_format` | string | `png` | Stage 6 | Plot file format. |
| `plot_dpi` | int | `300` | Stage 6 | Plot DPI. |
| `contact_cutoff` | float | `4.5` | Stage 6 | Contact cutoff (angstrom). |
| `selections` | list/string | *(empty)* | Stage 6 | Optional explicit atom selections. |
| `gmx_rmsd_ref_group` | int | `4` | Stage 6 | Group ID for RMSD reference. |
| `gmx_rmsd_mobile_group` | int | `4` | Stage 6 | Group ID for RMSD mobile group. |
| `gmx_rmsf_group` | int | `4` | Stage 6 | Group ID for RMSF. |
| `gmx_hbond_group_a` | int | `1` | Stage 6 | H-bond group A ID. |
| `gmx_hbond_group_b` | int | `13` | Stage 6 | H-bond group B ID. |
| `ligand_list` | list | *(empty)* | Stage 6 | Optional explicit ligand subset for analysis. |

## Input File Preparation

_To be completed in Task 2._

## Workspace Setup

_To be completed in Task 2._

## Part 2: Per-Stage Instructions (placeholder)

Detailed per-stage operating instructions, verification checkpoints, and troubleshooting will be added in Part 2.
