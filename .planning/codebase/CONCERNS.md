# Codebase Concerns

**Analysis Date:** 2026-04-19

## Tech Debt

**Config interpolation mismatch:**
- Issue: `scripts/config.ini.template` relies heavily on `${section:key}` interpolation, but `scripts/infra/config_loader.sh` is a literal line parser and never resolves those references.
- Files: `scripts/config.ini.template`, `scripts/infra/config_loader.sh`
- Impact: a config copied directly from the template can resolve to literal strings like `${general:workdir}/rec`, which breaks path discovery across `scripts/rec/*.sh`, `scripts/dock/*.sh`, and `scripts/com/*.sh`.
- Fix approach: add interpolation support in `scripts/infra/config_loader.sh` or replace template placeholders in `scripts/config.ini.template` with values the shell loader can actually resolve.

**Divergent topology assembly paths:**
- Issue: topology generation is implemented twice with different rules in `scripts/com/0_prep.sh` and `scripts/dock/4_dock2com_2.py`.
- Files: `scripts/com/0_prep.sh`, `scripts/dock/4_dock2com_2.py`
- Impact: AMBER/CHARMM complex assembly behavior differs by entrypoint, which makes topology bugs hard to reproduce and fix consistently.
- Fix approach: move topology assembly into one shared implementation and make both wrappers call the same code path.

**Large single-file scripts with mixed responsibilities:**
- Issue: parsing, validation, conversion, and CLI behavior are concentrated in a few large files instead of smaller modules.
- Files: `scripts/dock/0_gro_itp_to_mol2.py`, `scripts/infra/verification.py`, `scripts/infra/executor.py`, `scripts/infra/monitor.py`, `scripts/com/0_prep.sh`
- Impact: changes in one area are more likely to introduce regressions in unrelated behavior, especially around ligand conversion and workflow orchestration.
- Fix approach: split parsing, filesystem orchestration, and CLI entrypoints into separate modules with narrow testable functions.

**Tracked bytecode artifacts:**
- Issue: repository state includes committed Python bytecode caches.
- Files: `scripts/agents/__pycache__/`, `scripts/com/__pycache__/`, `scripts/dock/__pycache__/`, `scripts/rec/__pycache__/`, `scripts/infra/__pycache__/`
- Impact: stale bytecode can confuse review/debugging and adds noise to repository state without helping runtime behavior.
- Fix approach: remove tracked cache directories and ignore them in version control.

## Known Bugs

**Dock-to-complex wrapper expects a complex GRO that it does not generate:**
- Symptoms: `scripts/dock/4_dock2com.sh` and `scripts/dock/4_dock2com_ref.sh` fail on `require_file "${com_gro}"` unless a pre-existing `com.gro` or `complex.gro` already exists in the docking ligand directory.
- Files: `scripts/dock/4_dock2com.sh`, `scripts/dock/4_dock2com_ref.sh`, `scripts/dock/4_dock2com_1.py`, `scripts/dock/4_dock2com_2.py`
- Trigger: run either dock-to-complex wrapper on a fresh docking output directory that only contains pose SDF and ligand parameter files.
- Workaround: create `com.gro`/`complex.gro` externally before running the wrapper, or use a different complex-preparation path.

**Complex prep ignores the receptor topology it validates:**
- Symptoms: `scripts/com/0_prep.sh` requires `receptor_top` but `build_sys_top()` writes a new `sys.top` that includes only the force field and ligand ITP, not receptor topology includes.
- Files: `scripts/com/0_prep.sh`
- Trigger: run `scripts/com/0_prep.sh` in a workspace where receptor molecule definitions are not already duplicated into the ligand directory.
- Workaround: replace generated `sys.top` manually with a topology that includes receptor molecule definitions before `gmx grompp`.

**MM/PBSA can use the wrong receptor/ligand groups:**
- Symptoms: `scripts/com/2_trj4mmpbsa.sh` builds an index file dynamically, but `scripts/com/2_mmpbsa.sh` still defaults to fixed numeric group IDs `1` and `12`.
- Files: `scripts/com/2_trj4mmpbsa.sh`, `scripts/com/2_mmpbsa.sh`, `scripts/config.ini.template`
- Trigger: run MM/PBSA on an `index.ndx` whose receptor/ligand groups are not numbered exactly as the defaults expect.
- Workaround: set `[mmpbsa] receptor_group_id` and `[mmpbsa] ligand_group_id` explicitly for each system after inspecting the generated `index.ndx`.

**Atom-number/atom-order mismatch can generate invalid ligand restraints:**
- Symptoms: `scripts/dock/4_dock2com_2.2.1.py` writes `posre_lig.itp` directly from atom IDs in `best.gro`, but there is no validation that the SDF-derived GRO atom order matches the ligand ITP atom order.
- Files: `scripts/dock/4_dock2com_1.py`, `scripts/dock/4_dock2com_2.2.1.py`, `scripts/dock/0_gro_itp_to_mol2.py`
- Trigger: run dock-to-complex on ligands whose docked SDF atom ordering differs from the parameterized ligand topology.
- Workaround: reorder the generated ligand GRO to match the ligand ITP/template atom numbering before generating `posre_lig.itp`.

**Direct config-driven use of topology builder reads the wrong section:**
- Symptoms: `scripts/dock/4_dock2com_2.py` loads overrides from `[docking]` instead of `[dock2com]`/`[dock2com_ref]`, so direct `--config` usage ignores the section that the wrappers document.
- Files: `scripts/dock/4_dock2com_2.py`, `scripts/config.ini.template`
- Trigger: run `python scripts/dock/4_dock2com_2.py --config ...` without explicit `--receptor-top`, `--ligand-itp`, and `--output-top` arguments.
- Workaround: pass all paths explicitly on the CLI instead of relying on config-based defaults.

## Security Considerations

**Slurm script generation trusts unsanitized names and config values:**
- Risk: ligand names, paths, and config values are interpolated directly into heredoc-generated job scripts, which makes command injection possible if those inputs contain shell metacharacters or embedded newlines.
- Files: `scripts/com/0_prep.sh`, `scripts/com/1_pr_prod.sh`, `scripts/com/2_sub_mmpbsa.sh`, `scripts/dock/2_gnina.sh`
- Current mitigation: most direct command invocations quote file paths, and the repository assumes trusted local inputs.
- Recommendations: sanitize ligand identifiers, reject unsafe characters early, and render job scripts with escaped arguments instead of raw heredoc interpolation.

**Automatic environment sourcing executes repository-local shell code on every stage:**
- Risk: every shell entrypoint sources `scripts/setenv.sh` through `scripts/infra/common.sh`, so any modification to that file runs arbitrary shell commands in every workflow stage.
- Files: `scripts/infra/common.sh`, `scripts/setenv.sh`
- Current mitigation: none beyond repository trust.
- Recommendations: keep `scripts/setenv.sh` minimal, validate required commands instead of unconditional activation, and gate sourcing behind an opt-in flag for non-interactive runs.

## Performance Bottlenecks

**Nested frame × residue contact loops:**
- Problem: contact analysis iterates over every trajectory frame and then over every receptor residue, calling `distance_array()` for each residue separately.
- Files: `scripts/com/3_com_ana_trj.py`, `scripts/com/4_fp.py`
- Cause: the current implementation uses nested Python loops around per-residue distance calculations instead of a more vectorized residue-contact method.
- Improvement path: replace per-residue loops with MDAnalysis contact utilities or precomputed residue masks so each frame does fewer distance-matrix builds.

**Quadratic fingerprint similarity matrix:**
- Problem: `_pairwise_dice()` materializes a full `n_frames × n_frames` similarity matrix, and the heatmap writes the whole matrix even for long trajectories.
- Files: `scripts/com/4_fp.py`
- Cause: dense all-vs-all frame comparison scales poorly in both runtime and memory.
- Improvement path: downsample frames, compute a banded or sampled similarity matrix, or make heatmap generation optional for long trajectories.

**Analysis keeps whole trajectories in memory:**
- Problem: RMSF analysis stacks every frame into one `xyz` array before computing fluctuations.
- Files: `scripts/com/3_com_ana_trj.py`
- Cause: `coords.append(atoms.positions.copy())` followed by `np.stack()` scales linearly with total frames and atom count.
- Improvement path: use streaming statistics or chunked trajectory processing instead of building one full in-memory tensor.

**Docking jobs serialize receptor ensemble work inside each ligand job:**
- Problem: each ligand submission loops over `seq 0 $((ENSEMBLE_SIZE - 1))` inside one Slurm job instead of distributing receptor-ligand pairs independently.
- Files: `scripts/dock/2_gnina.sh`
- Cause: the scheduling model parallelizes by ligand only, not by receptor-ligand pair.
- Improvement path: switch to a Slurm array or two-dimensional scheduling scheme keyed by ligand and receptor index.

## Fragile Areas

**Topology extraction depends on file layout heuristics:**
- Files: `scripts/dock/4_dock2com_2.py`, `scripts/com/0_prep.sh`
- Why fragile: `_extract_receptor_moleculetype()` and `_detect_ff_includes()` assume a specific topology include order, while `build_sys_top()` in `scripts/com/0_prep.sh` bypasses receptor topology parsing entirely.
- Safe modification: change topology handling only after validating against both AMBER and CHARMM receptor topologies with different include layouts.
- Test coverage: no automated tests detected for receptor/ligand topology assembly in `scripts/dock/4_dock2com_2.py` or `scripts/com/0_prep.sh`.

**Environment bootstrap is brittle in non-interactive shells:**
- Files: `scripts/infra/common.sh`, `scripts/setenv.sh`, `scripts/commands/common.sh`
- Why fragile: `conda activate autoEnsmblDockMD` is sourced from non-interactive shells without checking that Conda shell hooks are loaded.
- Safe modification: make activation idempotent, detect missing Conda initialization, and allow scripts to proceed when the environment is already active.
- Test coverage: no automated tests detected for shell initialization behavior.

**Exact file-count assumptions in receptor ensemble handling:**
- Files: `scripts/rec/4_cluster.sh`, `scripts/dock/1_rec4dock.sh`, `scripts/config.ini.template`
- Why fragile: clustering and docking prep assume exact `rec0..recN-1` output sets and fail if clustering yields fewer conformers than `[receptor] ensemble_size`.
- Safe modification: derive actual cluster count from generated files before validating or copying the ensemble.
- Test coverage: no automated tests detected for low-cluster or missing-file scenarios.

## Scaling Limits

**Trajectory analysis memory footprint:**
- Current capacity: bounded by in-memory arrays sized to `n_frames × n_atoms × 3` in `scripts/com/3_com_ana_trj.py` and `n_frames × n_residues` plus `n_frames × n_frames` in `scripts/com/4_fp.py`; no hard cap is enforced.
- Limit: long production trajectories can exhaust memory or produce impractically slow analysis, especially when `scripts/com/4_fp.py` also builds the full similarity heatmap.
- Scaling path: stream metrics per chunk, persist intermediate summaries, and make quadratic outputs optional.

**Docking throughput per ligand:**
- Current capacity: one Slurm job per ligand, with each job iterating through all receptor conformers in `scripts/dock/2_gnina.sh`.
- Limit: runtime grows linearly with `ligand_count × ensemble_size`, and a single slow receptor keeps the whole ligand job occupied.
- Scaling path: submit receptor-ligand pairs as separate tasks and aggregate outputs after completion.

## Dependencies at Risk

**RDKit / Open Babel dual conversion path:**
- Risk: `scripts/dock/4_dock2com_1.py` can convert SDF to GRO through either RDKit or `obabel`, and the code does not verify that both backends preserve identical atom ordering.
- Impact: ligand atom numbering can diverge from the ligand ITP, which then propagates into `scripts/dock/4_dock2com_2.2.1.py` position restraints and downstream complex prep.
- Migration plan: standardize on one conversion backend and add an atom-order validation step against the ligand topology/template before writing `best.gro`.

## Missing Critical Features

**No automated atom-order and unit-consistency validation:**
- Problem: there is no runtime check that `best.gro`, ligand ITP atom numbering, and template ligand files stay aligned, and there is no explicit assertion around nm↔Å assumptions across `scripts/dock/4_dock2com_1.py`, `scripts/dock/0_gro_itp_to_mol2.py`, `scripts/com/3_com_ana_trj.py`, and `scripts/com/4_fp.py`.
- Blocks: safe automated dock-to-complex conversion and confident extension to new ligand sources or alternate conversion backends.

**No automated test suite for pipeline scripts:**
- Problem: no `*.test.*` or `*.spec.*` files are present for the workflow scripts, despite heavy branching in shell and Python entrypoints.
- Blocks: safe refactoring of `scripts/com/*.sh`, `scripts/dock/*.py`, and `scripts/infra/*.py` without manual end-to-end reruns.

## Test Coverage Gaps

**Topology assembly and restraint generation are untested:**
- What's not tested: complex topology assembly, receptor include handling, and ligand restraint generation for atom-order mismatches.
- Files: `scripts/com/0_prep.sh`, `scripts/dock/4_dock2com.sh`, `scripts/dock/4_dock2com_ref.sh`, `scripts/dock/4_dock2com_2.py`, `scripts/dock/4_dock2com_2.2.1.py`
- Risk: broken `sys.top` or misnumbered `posre_lig.itp` can survive until expensive MD setup fails.
- Priority: High

**Config loading behavior is untested:**
- What's not tested: `${section:key}` placeholder handling, environment overrides, and section-name mismatches between wrappers and Python helpers.
- Files: `scripts/infra/config_loader.sh`, `scripts/config.ini.template`, `scripts/dock/4_dock2com_2.py`
- Risk: copied template configs can fail late with misleading missing-file errors.
- Priority: High

**Trajectory-analysis correctness and scaling are untested:**
- What's not tested: contact metrics on long trajectories, memory-heavy RMSF execution, and large-frame fingerprint heatmap generation.
- Files: `scripts/com/3_com_ana_trj.py`, `scripts/com/4_fp.py`, `scripts/com/3_ana.sh`, `scripts/com/4_cal_fp.sh`
- Risk: correctness and runtime regressions can go unnoticed until a full production dataset is analyzed.
- Priority: Medium

---

*Concerns audit: 2026-04-19*
