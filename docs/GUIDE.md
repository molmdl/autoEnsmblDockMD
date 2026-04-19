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
    - [[fingerprint]](#fingerprint)
    - [[archive]](#archive)
    - [[rerun]](#rerun)
    - [[monitor_patterns]](#monitor_patterns)
  - [Input File Preparation](#input-file-preparation)
  - [Workspace Setup](#workspace-setup)
- [Part 2: Stage-by-Stage Operating Guide](#part-2-stage-by-stage-operating-guide)
  - [How to use this section with `WORKFLOW.md`](#how-to-use-this-section-with-workflowmd)
  - [Stage 0: Input Preparation and Preflight](#stage-0-input-preparation-and-preflight)
  - [Stage 1: Receptor Ensemble Generation](#stage-1-receptor-ensemble-generation)
  - [Stage 2: Docking](#stage-2-docking)
  - [Stage 3: Complex Setup](#stage-3-complex-setup)
  - [Stage 4: MD Simulation](#stage-4-md-simulation)
  - [Stage 5: MM/PBSA](#stage-5-mmpbsa)
  - [Stage 6: Analysis](#stage-6-analysis)
  - [Output Interpretation Quick Guide](#output-interpretation-quick-guide)
  - [Troubleshooting](#troubleshooting)
  - [Force Field Compatibility](#force-field-compatibility)

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
| `ensemble_parallelism` | int | `1` | Stage 2 gnina | Max receptor-conformer jobs run in parallel per ligand. |
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
| `solvent_coordinates` | string/path | `spc216.gro` | Stage 3 | Coordinate source passed to `gmx solvate -cs` (file/path, not water-model label). |
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
| `group_ids_file` | string | `mmpbsa_groups.dat` | Stage 5 | Persisted receptor/ligand/complex group ID mapping per ligand directory. |
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
| `distance_reference` | enum | `protein_backbone` | Stage 6 advanced | Reference selection key used in advanced distance calculations. |
| `selections` | list/string | *(empty)* | Stage 6 | Optional explicit atom selections. |
| `gmx_rmsd_ref_group` | int | `4` | Stage 6 | Group ID for RMSD reference. |
| `gmx_rmsd_mobile_group` | int | `4` | Stage 6 | Group ID for RMSD mobile group. |
| `gmx_rmsf_group` | int | `4` | Stage 6 | Group ID for RMSF. |
| `gmx_hbond_group_a` | int | `1` | Stage 6 | H-bond group A ID. |
| `gmx_hbond_group_b` | int | `13` | Stage 6 | H-bond group B ID. |
| `ligand_list` | list | *(empty)* | Stage 6 | Optional explicit ligand subset for analysis. |

#### [fingerprint]

| Key | Type | Default | Used by stage(s) | Description / mode notes |
| --- | --- | --- | --- | --- |
| `workdir` | path | `${complex:workdir}` | Optional utility | Workspace root for fingerprint discovery. |
| `ligand_dir` | path | `${fingerprint:workdir}` | Optional utility | Ligand directory scanned by fingerprint stage. |
| `ligand_pattern` | pattern | `${complex:ligand_pattern}` | Optional utility | Ligand directory discovery pattern. |
| `ligand_list` | list | *(empty)* | Optional utility | Explicit ligand list override. |
| `trajectory` | string | `com_traj.xtc` | Optional utility | Trajectory filename used for per-ligand fingerprint analysis. |
| `topology` | string | `com.tpr` | Optional utility | Topology filename used for per-ligand fingerprint analysis. |
| `output_dir` | string | `fp` | Optional utility | Per-ligand output subdirectory. |
| `output_prefix` | string | `fingerprint` | Optional utility | Prefix for generated fingerprint artifacts. |
| `ligand_selection` | string | `resname MOL and not name H*` | Optional utility | MDAnalysis atom selection for ligand atoms. |
| `receptor_selection` | string | `protein and not name H*` | Optional utility | MDAnalysis atom selection for receptor atoms. |
| `cutoff` | float | `4.5` | Optional utility | Contact distance cutoff (Å). |
| `summary_csv` | path | `${fingerprint:workdir}/fingerprint_summary.csv` | Optional utility | Aggregated fingerprint summary CSV path. |
| `fp_script` | path | `scripts/com/4_fp.py` | Optional utility | Fingerprint analysis Python entrypoint override. |

#### [archive]

| Key | Type | Default | Used by stage(s) | Description / mode notes |
| --- | --- | --- | --- | --- |
| `workdir` | path | `${complex:workdir}` | Optional utility | Workspace root for archive selection. |
| `ligand_dir` | path | `${archive:workdir}` | Optional utility | Ligand directory scanned for archival. |
| `ligand_pattern` | pattern | `${complex:ligand_pattern}` | Optional utility | Ligand discovery pattern. |
| `ligand_list` | list | *(empty)* | Optional utility | Explicit ligand list override. |
| `archive_dir` | path | `${archive:workdir}/archive` | Optional utility | Output directory for per-ligand archive tarballs. |
| `include_patterns` | list/pattern | `*.gro,*.xtc,*.xvg,mmpbsa_*/FINAL_RESULTS_MMPBSA.dat,mmpbsa_*/FINAL_RESULTS_MMPBSA.csv` | Optional utility | Comma-separated glob patterns included in each archive. |
| `dry_run` | bool | `false` | Optional utility | Preview archive membership without writing tarballs. |
| `compress_level` | int | `6` | Optional utility | Gzip compression level passed to `tar`. |

#### [rerun]

| Key | Type | Default | Used by stage(s) | Description / mode notes |
| --- | --- | --- | --- | --- |
| `workdir` | path | `${complex:workdir}` | Optional utility | Workspace root for rerun selection. |
| `ligand_dir` | path | `${rerun:workdir}` | Optional utility | Ligand directory scanned for completeness checks. |
| `ligand_pattern` | pattern | `${complex:ligand_pattern}` | Optional utility | Ligand discovery pattern. |
| `ligand_list` | list | *(empty)* | Optional utility | Explicit ligand list override. |
| `stage` | enum | `prod` | Optional utility | Stage to validate/rerun (`prep|prod|mmpbsa`). |
| `expected_prep` | list/pattern | `pr_pos.gro,sys.top,index.ndx` | Optional utility | Required files/patterns indicating prep completion. |
| `expected_prod` | list/pattern | `prod_0.xtc,prod_0.tpr` | Optional utility | Required files/patterns indicating production completion. |
| `expected_mmpbsa` | list/pattern | `mmpbsa_0/FINAL_RESULTS_MMPBSA.dat` | Optional utility | Required files/patterns indicating MM/PBSA completion. |
| `prep_script` | path | `scripts/com/0_prep.sh` | Optional utility | Script invoked when rerunning prep stage. |
| `prod_script` | path | `scripts/com/1_pr_prod.sh` | Optional utility | Script invoked when rerunning production stage. |
| `mmpbsa_script` | path | `scripts/com/2_sub_mmpbsa.sh` | Optional utility | Script invoked when rerunning MM/PBSA stage. |
| `partition` | string | `${slurm:partition}` | Optional utility | Slurm partition used for rerun submissions. |
| `cpus_per_task` | int | `4` | Optional utility | CPU count used for rerun submissions. |

#### [monitor_patterns]

| Key | Type | Default | Used by stage(s) | Description / mode notes |
| --- | --- | --- | --- | --- |
| `error_patterns` | list/regex | built-in defaults | Monitoring/validation | Custom error regex patterns, separated by `||`; overrides default error registry when set. |
| `warning_patterns` | list/regex | built-in defaults | Monitoring/validation | Custom warning regex patterns, separated by `||`; overrides default warning registry when set. |
| `completion_markers` | list/regex | built-in defaults | Monitoring/validation | Custom completion regex markers, separated by `||`; overrides default completion registry when set. |
| `max_matched_lines` | int | `0` | Monitoring/validation | Max matched lines returned per class (`0` = no limit). |

## Input File Preparation

Prepare all required inputs before running `scripts/run_pipeline.sh`.

### 1) Receptor PDB (`[receptor] input_pdb`)

- File format: standard `.pdb` with valid ATOM/HETATM records and coordinates.
- Chain naming: keep chain IDs consistent and non-empty for stable downstream selections.
- Hydrogen handling: avoid double-protonating manually if you use scripted protonation (`pdb2pqr`/`pdb2gmx`) in Stage 1.
- Clean structure: remove irrelevant crystallization artifacts unless intentionally required.
- Ensure residue naming matches chosen force field family (AMBER or CHARMM conventions).

### 2) Reference ligand (Mode A targeted/test docking)

Purpose: defines the pocket/autobox region for targeted docking.

- Coordinates: provide a reference ligand coordinate file (`.pdb` and/or `.gro`) placed under workspace dock/ref paths.
- Topology: provide matching ligand topology (`.itp`; plus related params if used by your FF workflow).
- Consistency rule: coordinate atom names/order must align with topology definitions.
- Configure in `config.ini` via `[docking] reference_ligand` and related dock2com settings.

### 3) Test/new ligands for docking and complex setup

For each ligand (commonly named with `lig*` pattern):

- Coordinate file: `.gro` (or converted `.mol2`/`.sdf` intermediates as required by stage scripts).
- Topology file: ligand `.itp` (and any associated includes required by your force field toolchain).
- Naming convention: keep base names synchronized across files (for example `lig1.gro`, `lig1.itp`, `lig1.mol2`).
- Pattern compatibility: defaults use `lig*`; if you use different names, set `ligand_pattern` or `ligand_list` explicitly.

### 4) Force field files and compatibility

You must provide/resolve FF assets referenced by receptor and complex setup:

- Protein FF: chosen in `[receptor] ff` and `[complex] ff`.
- Include path: `[complex] ff_include` must point to the correct `forcefield.itp` include.
- Ligand parameters: ensure ligand topology was generated for the same FF family as the protein setup branch.

FF family guidance:

- **AMBER branch (Mode A often used):** use AMBER-compatible protein + ligand topology stack.
- **CHARMM36m/CGenFF branch (Mode B common):** use CHARMM-compatible protein + CGenFF-style ligand topology stack.

> Known pitfall: mixing AMBER protein setup with CGenFF ligand parameters commonly causes topology/runtime crashes. Keep FF families matched end-to-end.

### 5) MDP files (`[receptor] mdp_dir`, `[complex] mdp_dir`)

Required baseline files:

- `em.mdp` — energy minimization
- `nvt.mdp` — constant volume equilibration (if your protocol uses explicit NVT stage)
- `npt.mdp` — constant pressure equilibration (if your protocol uses explicit NPT stage)
- `md.mdp` — production MD

Also commonly referenced in this codebase:

- `pr0.mdp`, `pr.mdp` / `pr_pos.mdp` for staged equilibration naming used by scripts.

Template/source locations:

- Receptor-side MDPs under your receptor MDP folder (default `./mdp/rec`).
- Complex-side MDPs under your complex MDP folder (default `./mdp/com`).
- Start from project templates/examples already used by your team and adjust timestep, thermostat, barostat, and output intervals consistently.

## Workspace Setup

Create a dedicated run workspace and place inputs in predictable locations.

### 1) Recommended directory layout

```text
work/{project}/
├── config.ini
├── rec/                  # receptor-stage outputs
├── dock/                 # docking inputs/outputs
├── com/                  # complex prep + MD + MMPBSA per ligand
├── ref/                  # reference ligand assets (Mode A)
└── mdp/
    ├── rec/              # receptor-stage mdp files
    └── com/              # complex/prod mdp files
```

### 2) Create workspace skeleton

```bash
mkdir -p work/my_project/{rec,dock,com,ref,mdp/rec,mdp/com}
cp scripts/config.ini.template work/my_project/config.ini
```

### 3) Copy inputs into expected locations

- Receptor PDB → path referenced by `[receptor] input_pdb` (often inside workspace root).
- Docking ligands + ligand topologies → `[dock] ligand_dir` / `[docking] ligands_dir`.
- Reference ligand assets (if Mode A) → workspace `ref/` and path in `[docking] reference_ligand`.
- MDP files → `[receptor] mdp_dir` and `[complex] mdp_dir` targets.

### 4) Configure `config.ini` from template

At minimum, verify and edit these fields:

- `[general] workdir`
- `[receptor] input_pdb`, `ff`, `mdp_dir`
- `[docking] mode`, `ligands_dir`, `receptor_dir`, `reference_ligand` (Mode A)
- `[complex] mode`, `ff`, `ff_include`, `mdp_dir`
- `[production] n_trials`, `production_mdp`
- `[mmpbsa] n_chunks`, topology keys (`amber_topology_file` / `charmm_topology_file`)

### 5) Verify setup before launching heavy stages

Quick checks:

```bash
source ./scripts/setenv.sh
bash scripts/run_pipeline.sh --config work/my_project/config.ini --list-stages
```

Then inspect workspace status via the project status command wrapper:

```bash
bash scripts/commands/aedmd-status.sh --workdir work/my_project
```

If `status` or `--list-stages` reports missing config keys/paths, fix those first to avoid expensive failed jobs.

## Part 2: Stage-by-Stage Operating Guide

Use this section while running stages from `scripts/run_pipeline.sh`.
For script paths, stage aliases, and full command inventory, always cross-check `WORKFLOW.md`.

### Agent skill reference format (for slash-command users)

If you use agent/slash-command workflows, skill references point to `.opencode/skills/aedmd-{name}/SKILL.md`.
These skill files use YAML frontmatter with `name`, `description`, `license`, `compatibility`, and `metadata`, followed by operational sections such as **When to use this skill**, **Prerequisites**, **Usage**, **Parameters**, and troubleshooting guidance.

### How to use this section with `WORKFLOW.md`

- This guide tells you **what to do and what to inspect** before moving to the next stage.
- `WORKFLOW.md` tells you **exact script sequence and script locations** (`scripts/rec`, `scripts/dock`, `scripts/com`, `scripts/infra`).
- Recommended execution pattern:
  1. Run one stage.
  2. Perform the verification checklist below.
  3. Confirm expected outputs are present and sensible.
  4. Proceed only when pass criteria are met.

### Stage 0: Input Preparation and Preflight

**What this stage does**
- Validates `config.ini`, input file paths, and stage prerequisites before expensive compute jobs.
- Ensures your workspace is consistent with what downstream scripts expect.

**Key commands to run**
- `source ./scripts/setenv.sh`
- `bash scripts/run_pipeline.sh --config work/my_project/config.ini --list-stages`
- Optional workspace readiness check: `bash scripts/commands/aedmd-status.sh --workdir work/my_project`
- See `WORKFLOW.md` Stage 0 for infra-level script references.

**Check before proceeding**
- Config sections are present (`[general]`, `[receptor]`, `[docking]`, `[complex]`, `[production]`, `[mmpbsa]`, `[analysis]`).
- Paths resolve correctly (receptor PDB, MDP directories, ligand directories).
- Mode-specific inputs are ready (Mode A reference ligand, Mode B blind docking assets).

**Expected outputs and what they mean**
- No missing-key/path errors in stage listing output.
- Stage discovery output confirms pipeline entry points are reachable.
- A clean preflight means failures in later stages are more likely scientific/runtime issues, not setup mistakes.

**Common issues (stage-specific)**
- Wrong `workdir` or stale relative paths in copied config.
- Missing MDP files (`em.mdp`, `pr0.mdp`, `md.mdp`) causing early grompp failures.
- Running without `source ./scripts/setenv.sh` and then hitting missing tool/module errors.

### Stage 1: Receptor Ensemble Generation

**What this stage does**
- Prepares receptor system, samples receptor dynamics, then clusters representative conformations.
- Optionally aligns representative structures to a reference frame for stable pocket comparison.

**Key commands to run**
- Run Stage 1 via pipeline stage selection or full pipeline execution.
- Use stage-level status checks to confirm receptor trials completed.
- Script sequence and exact paths are documented in `WORKFLOW.md` Stage 1.

**Check before proceeding**
- Receptor trajectories exist for each configured trial.
- Clustering completed and produced representative `rec*` structures.
- If alignment enabled, aligned outputs exist under configured alignment output directory.

**Expected outputs and what they mean**
- Receptor topology/coordinate artifacts indicate prep succeeded.
- Cluster outputs represent conformational diversity used by docking.
- Balanced cluster populations suggest reasonable ensemble quality; one giant cluster may indicate low diversity.

**Common issues (stage-specific)**
- Protonation/hydrogen assignment issues from incomplete receptor input.
- Overly strict clustering cutoff producing too many tiny/noisy clusters.
- Alignment reference mismatch causing unexpected orientation shifts.

### Stage 2: Docking

**What this stage does**
- Converts/normalizes ligand and receptor docking inputs, runs gnina across receptor ensemble, and ranks/selects poses.
- Produces scored poses used to seed complex setup.

**Key commands to run**
- Execute docking stage from the pipeline with your selected mode (`targeted/test` or `blind`).
- Review generated docking report after gnina completes.
- For script-level sequence (`0_gro2mol2`, `2_gnina`, `3_dock_report`, etc.), see `WORKFLOW.md` Stage 2.

**Check before proceeding**
- gnina completed for expected ligand/receptor combinations.
- Docking report exists and contains ranked entries.
- Selected output poses were exported for next-stage conversion.

**Expected outputs and what they mean**
- SDF outputs and logs contain pose-level scoring details.
- Better (more favorable) CNN-based rankings generally indicate stronger candidate poses.
- Pose geometry should be chemically plausible inside the target region (for targeted mode).

**Common issues (stage-specific)**
- Incorrect autobox reference/size causing unrealistic or empty docking region.
- Input ligand format/atom typing inconsistencies reducing valid pose generation.
- Blind docking search space too broad with insufficient exhaustiveness.

### Stage 3: Complex Setup

**What this stage does**
- Converts selected docked poses into receptor-ligand complex systems ready for MD.
- Builds topology, solvates, ions, and runs minimization/early restraint steps.

**Key commands to run**
- Run Stage 3 through pipeline stage orchestration after docking selection is complete.
- Inspect generated per-ligand complex directories.
- For branch-specific script chain (`dock2com*`, `scripts/com/0_prep.sh`, bypass helper), refer to `WORKFLOW.md` Stage 3.

**Check before proceeding**
- Each intended ligand has a complete complex folder with `com.gro`, `sys.top`, and index files.
- Minimization/equilibration setup commands finished without fatal topology errors.
- Force-field branch (`amber` vs `charmm`) is consistent with ligand parameter family.

**Expected outputs and what they mean**
- `sys.top` and related include files show topology assembly succeeded.
- Minimized structures with reduced potential energy indicate physically saner starting coordinates.
- Position-restraint artifacts indicate readiness for Stage 4 equilibration/production.

**Scheduler note**
- `scripts/com/0_prep.sh` may submit jobs and return before all ligand folders are fully ready.
- Confirm completion (`squeue`/`sacct`) and expected files (`pr_pos.gro`, `sys.top`, `index.ndx`) before Stage 4.

**Common issues (stage-specific)**
- Topology include ordering problems or missing ligand include files.
- Force-field mismatch between protein and ligand assets.
- Atom type/angle definitions needing bypass helper in AMBER-oriented branch.

### Stage 4: MD Simulation

**What this stage does**
- Runs the complex equilibration chain and production trajectories for each ligand/trial.
- Generates the dynamic trajectories used for MM/PBSA and structural analyses.

**Key commands to run**
- Execute production stage after verifying Stage 3 minimized/equilibration-ready artifacts.
- Monitor per-ligand trial outputs and scheduler logs during runtime.
- See `WORKFLOW.md` Stage 4 for production script path and required config keys.

**Check before proceeding**
- Expected number of trial trajectories (`prod_*.xtc`, `prod_*.tpr`) exists.
- Jobs complete without LINCS/blow-up/fatal pressure/temperature instability errors.
- Stability metrics (especially RMSD trend) are acceptable before using trajectories downstream.

**Expected outputs and what they mean**
- Stable RMSD trajectories (commonly targeting <3 Å plateau for core protein frame) suggest equilibration sufficiency.
- Consistent temperature/pressure behavior indicates healthy integration settings.
- Major monotonic drift or repeated spikes suggests unstable setup requiring correction.

**Scheduler note**
- `scripts/com/1_pr_prod.sh` is typically a submission stage in Slurm environments.
- Treat command return as job submission success, not production completion.
- Wait for `COMPLETED` job state and verify `prod_*.xtc`/`prod_*.tpr` before Stage 5.

**Common issues (stage-specific)**
- RMSD stays >3 Å with unstable trend (often needs longer equilibration or box/ion review).
- Inadequate restraints or problematic starting poses causing early structural distortions.
- Resource/request mismatch in Slurm leading to repeated failed runs.

### Stage 5: MM/PBSA

**What this stage does**
- Preprocesses MD trajectories and computes chunked binding free-energy estimates.
- Produces total and component energy terms to compare ligand binding behavior.

**Key commands to run**
- Run MM/PBSA orchestration scripts after confirming Stage 4 trajectories are complete.
- Check chunk directories and summarized outputs per ligand.
- Exact script order (`2_run_mmpbsa`, `2_trj4mmpbsa`, `2_sub_mmpbsa`, `2_mmpbsa`) is in `WORKFLOW.md` Stage 5.

**Check before proceeding**
- Processed trajectories and expected chunk folders were created.
- Topology used by `gmx_MMPBSA` matches the force-field branch and generated structures.
- Result files include total binding estimates and decomposition terms.

**Expected outputs and what they mean**
- More favorable (more negative) total binding energy generally indicates stronger predicted binding.
- Per-residue or per-component decomposition helps identify interaction drivers.
- Very noisy or inconsistent chunk-level estimates suggest insufficient sampling or input mismatch.

**Scheduler note**
- `scripts/com/2_sub_mmpbsa.sh` submits chunk jobs asynchronously.
- Track job IDs in scheduler output and verify all chunks complete before interpreting results.

**Common issues (stage-specific)**
- Topology mismatch (`amber_topology_file`/`charmm_topology_file` wrong for actual system).
- Group/index selection mismatch for receptor-ligand complex definitions.
- Chunk jobs failing due to CPU/MPI resource settings incompatible with queue limits.

### Stage 6: Analysis

**What this stage does**
- Generates interpretable trajectory metrics (RMSD, RMSF, contacts, hydrogen bonds, optional fingerprints).
- Converts raw MD results into comparative evidence across ligands.

**Key commands to run**
- Run analysis stage after Stage 4 and (optionally) Stage 5 results are available.
- Inspect per-ligand analysis output directories and generated figures/tables.
- Full script list for standard + optional analysis tools is in `WORKFLOW.md` Stage 6.

**Check before proceeding**
- Required metrics enabled in `[analysis]` were actually produced.
- Plot files and summary tables are present and non-empty.
- Selection/group settings used in analysis are consistent across ligands for fair comparison.

**Expected outputs and what they mean**
- RMSD: global stability of structure over time.
- RMSF: residue-level flexibility hotspots and rigid regions.
- Contacts/H-bonds: persistence of receptor-ligand interactions.
- Fingerprints/advanced metrics: comparative interaction patterns across candidates.

**Common issues (stage-specific)**
- Incorrect group IDs producing empty/invalid RMSD or H-bond outputs.
- Selection definitions not matching topology atom naming.
- Mixed analysis settings across ligands leading to non-comparable plots.

### Output Interpretation Quick Guide

Use this as a fast triage rubric before selecting lead compounds:

| Output | Good sign | Warning sign | Action |
| --- | --- | --- | --- |
| Receptor clustering | Multiple representative clusters with interpretable populations | Single dominant cluster with poor diversity or highly fragmented noisy clusters | Revisit clustering cutoff and receptor sampling length |
| Docking (gnina) | Favorable CNN rankings with plausible pocket poses | No valid poses or high-scoring but unrealistic orientations | Re-check docking mode, box definition, ligand preparation |
| Complex minimization | Potential energy decreases and converges | Persistent minimization failures or topology errors | Fix topology/includes and retry setup |
| Production MD | RMSD stabilizes (commonly near <3 Å for core frame) | Continuous drift/spikes suggesting instability | Extend equilibration, inspect restraints and box setup |
| MM/PBSA | Consistent negative trend across chunks/trials | Highly inconsistent chunks or extreme outliers | Verify topology/group mapping, increase sampling |
| Contacts/H-bonds | Persistent interaction network for top ligands | Transient/noisy contacts with no stable interaction pattern | Re-evaluate pose quality and replicate length |

## Troubleshooting

For scheduler-focused troubleshooting and async stage completion checks, see [docs/TROUBLESHOOTING.md](./TROUBLESHOOTING.md).

Use the table below for common failure patterns and first-response fixes.

| Symptom | Likely cause | How to diagnose quickly | Recommended fix |
| --- | --- | --- | --- |
| Topology build crashes after docking-to-complex conversion | Force-field family mismatch (e.g., AMBER protein + CGenFF ligand) | Inspect `[complex] ff`, `[dock2com] ff`, and ligand parameter source | Use matched FF families end-to-end (AMBER+GAFF2 or CHARMM36m+CGenFF) |
| Docking or MD prep fails with atom/protonation errors | Missing/incorrect hydrogen atoms | Check receptor preprocessing logs and protonation outputs | Rebuild receptor protonation via `pdb2pqr` or `gmx pdb2gmx` |
| `gmx_MMPBSA` errors on topology/structure consistency | MM/PBSA topology file does not match generated complex | Compare selected topology key and actual files in ligand folder | Set correct AMBER/CHARMM topology file and rerun trajectory preprocessing |
| Production run unstable (RMSD persistently >3 Å, repeated spikes) | Inadequate equilibration, poor starting pose, or box settings | Review RMSD plot and runtime warnings (LINCS/pressure) | Extend equilibration, validate pose quality, and check box size |
| Docking returns no valid poses | Wrong box center/size or unsuitable docking mode | Check gnina logs, autobox settings, and docking mode | Correct box center/size or retry in blind mode |
| Slurm job fails silently or exits unexpectedly | Scheduler/module/runtime environment issue | Inspect `slurm*.err` and job stdout/stderr for missing modules | Verify module loading, partition/resources, and conda/tool initialization |

## Force Field Compatibility

Keep protein and ligand parameter families aligned.

| Workflow mode | Protein force field | Ligand force field | Compatibility status | Notes |
| --- | --- | --- | --- | --- |
| Mode A (reference pocket, AMBER-oriented) | AMBER ff14SB (or compatible AMBER protein FF) | GAFF2 (or compatible AMBER ligand parameters) | ✅ Compatible | Typical targeted/test docking with AMBER-style downstream topology |
| Mode B (blind docking, CHARMM-oriented) | CHARMM36m | CGenFF | ✅ Compatible | Typical blind docking with CHARMM/CGenFF topology branch |
| Any mode (invalid mix) | AMBER protein force field | CGenFF ligand parameters | ❌ Do not mix | Common cause of topology/runtime crashes |

**Rule of thumb:** choose one force-field family at Stage 1/3 and keep it consistent through Stage 5.

## Citations

If you use `autoEnsmblDockMD` for your research, please cite the underlying computational tools. Full citation details are available in [README.md](../README.md#citations).

**Key tools:**
- **GROMACS** (Abraham et al. 2015; Berendsen et al. 1995) — molecular dynamics engine
- **gnina** (McNutt et al. 2025, 2021) — deep learning-enhanced molecular docking
- **gmx_MMPBSA** (Valdés-Tresanco et al. 2021) — binding free energy calculation
- **MDAnalysis** (Michaud-Agrawal et al. 2011; Gowers et al. 2016) — trajectory analysis toolkit
