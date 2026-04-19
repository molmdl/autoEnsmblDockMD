# Codebase Concerns

**Analysis Date:** 2026-04-19

## Tech Debt

**INI template interpolation is wider than shell loader support:**
- Issue: `scripts/config.ini.template` uses `${section:key}` references throughout, but `scripts/infra/config_loader.sh` stores literal values and never resolves interpolation.
- Files: `scripts/config.ini.template`, `scripts/infra/config_loader.sh`
- Impact: configs copied directly from the template can hand shell stages unresolved paths such as `${general:workdir}/com`, which breaks stage discovery and path resolution in `scripts/rec/*.sh`, `scripts/dock/*.sh`, and `scripts/com/*.sh`.
- Fix approach: either implement `${section:key}` expansion in `scripts/infra/config_loader.sh` or flatten the template to shell-resolvable literal defaults.

**Dock2com helpers still use the wrong config namespace for direct CLI use:**
- Issue: both `scripts/dock/4_dock2com_1.py` and `scripts/dock/4_dock2com_2.py` load overrides from `DEFAULT_SECTION = "docking"` even though the documented keys live under `[dock2com]` and `[dock2com_ref]`.
- Files: `scripts/dock/4_dock2com_1.py`, `scripts/dock/4_dock2com_2.py`, `scripts/config.ini.template`, `docs/GUIDE.md`
- Impact: wrapper-driven runs work because shell wrappers pass explicit arguments, but direct Python invocations silently ignore the documented dock2com config blocks.
- Fix approach: load `[dock2com]` / `[dock2com_ref]` explicitly or add a required `--config-section` argument and document it in `docs/GUIDE.md`.

**Hand-maintained command/schema docs drift faster than runtime code:**
- Issue: public command naming is consistently namespaced with `aedmd-*`, but the surrounding workflow/schema documentation is manually duplicated and no longer matches runtime structures.
- Files: `AGENTS.md`, `.opencode/docs/AGENT-WORKFLOW.md`, `scripts/commands/aedmd-status.sh`, `scripts/commands/common.sh`, `scripts/agents/schemas/handoff.py`, `scripts/run_pipeline.sh`
- Impact: namespace collision is not detected in current code, but future maintenance risk is high because docs can describe the wrong handoff JSON shape, stage outputs, or command behavior while the names still look correct.
- Fix approach: generate command inventory and handoff-schema docs from `scripts/run_pipeline.sh`, `scripts/commands/*.sh`, and `scripts/agents/schemas/handoff.py` instead of hand-editing tables.

**Large single-file scripts mix parsing, validation, and orchestration:**
- Issue: several Python and shell entrypoints bundle CLI parsing, filesystem orchestration, domain validation, and output generation in one file.
- Files: `scripts/dock/0_gro_itp_to_mol2.py`, `scripts/com/0_prep.sh`, `scripts/com/3_com_ana_trj.py`, `scripts/com/4_fp.py`, `scripts/dock/2_gnina.sh`
- Impact: small behavior changes are hard to isolate, review, and test, especially in correctness-sensitive paths such as topology assembly and trajectory analysis.
- Fix approach: split conversion logic, topology logic, and Slurm-script rendering into reusable functions/modules with direct regression tests.

**Tracked bytecode artifacts remain in the repository:**
- Issue: committed `__pycache__` trees are present under active script directories.
- Files: `scripts/agents/__pycache__/`, `scripts/com/__pycache__/`, `scripts/dock/__pycache__/`, `scripts/rec/__pycache__/`, `scripts/infra/__pycache__/`
- Impact: stale bytecode adds review noise and can obscure whether runtime behavior comes from source changes or leftover compiled artifacts.
- Fix approach: stop tracking cache directories and ignore them in version control.

## Known Bugs

**Strict atom-name validation can reject RDKit-generated docked GRO files even when atom order is correct:**
- Symptoms: `scripts/dock/4_dock2com.sh` and `scripts/dock/4_dock2com_ref.sh` can fail during position-restraint generation with `Atom-order/name mismatch between GRO and ITP` after `scripts/dock/4_dock2com_1.py` writes synthetic atom names such as `C1`, `O2`, `N3`.
- Files: `scripts/dock/4_dock2com_1.py`, `scripts/dock/4_dock2com_2.2.1.py`, `scripts/dock/4_dock2com.sh`, `scripts/dock/4_dock2com_ref.sh`
- Trigger: run dock2com through the RDKit conversion path on a ligand whose ITP atom names do not match the symbol-plus-index names emitted by `_write_gro_from_records()`.
- Workaround: use the Open Babel path when available, or pre-generate a ligand GRO whose atom names already match the ITP before calling `scripts/dock/4_dock2com_2.2.1.py`.

**Copied dock2com outputs are not self-contained topologies:**
- Symptoms: the `sys.top` copied into `${COM_DIR}/${ligand}` includes generated files like `*_rec.itp` and `*_clean.itp`, but the wrappers copy only `sys.top`, `complex.gro`, `posre_lig.itp`, `best.gro`, and the original ligand ITP.
- Files: `scripts/dock/4_dock2com_2.py`, `scripts/dock/4_dock2com.sh`, `scripts/dock/4_dock2com_ref.sh`
- Trigger: use the copied files under `${general:workdir}/com` or `${general:workdir}/com/ref` as if they were a portable complex-prep bundle.
- Workaround: run downstream prep from the original ligand docking directory, or manually copy the generated `*_rec.itp` and `*_clean.itp` files alongside `sys.top`.

**Analysis and fingerprint stages expect root-level files that the production stage does not create:**
- Symptoms: `scripts/com/3_ana.sh` and `scripts/com/4_cal_fp.sh` require `com.tpr` and `com_traj.xtc` inside each ligand directory, while `scripts/com/1_pr_prod.sh` produces `prod_*.tpr` and `prod_*.xtc`, and `scripts/com/2_trj4mmpbsa.sh` writes `com.tpr` / `com_traj.xtc` only inside `mmpbsa_*` chunk directories.
- Files: `scripts/com/1_pr_prod.sh`, `scripts/com/2_trj4mmpbsa.sh`, `scripts/com/3_ana.sh`, `scripts/com/4_cal_fp.sh`, `WORKFLOW.md`, `.opencode/docs/AGENT-WORKFLOW.md`
- Trigger: run `scripts/com/3_ana.sh` or `scripts/com/4_cal_fp.sh` directly after production MD on a fresh ligand directory.
- Workaround: manually supply or symlink `com.tpr` and `com_traj.xtc` into the ligand root, or point the fingerprint wrapper at chunk outputs explicitly.

**Direct config-driven dock2com Python usage still ignores documented section values:**
- Symptoms: `python scripts/dock/4_dock2com_1.py --config ...` and `python scripts/dock/4_dock2com_2.py --config ...` do not consume `[dock2com]` / `[dock2com_ref]` keys documented in `scripts/config.ini.template` and `docs/GUIDE.md`.
- Files: `scripts/dock/4_dock2com_1.py`, `scripts/dock/4_dock2com_2.py`, `scripts/config.ini.template`, `docs/GUIDE.md`
- Trigger: rely on config-only invocation without passing explicit `--sdf`, `--output`, `--receptor-top`, `--ligand-itp`, or `--output-top` arguments.
- Workaround: pass all required paths explicitly on the CLI instead of relying on config-based defaults.

## Security Considerations

**Slurm job scripts interpolate unsanitized ligand names and config values into shell heredocs:**
- Risk: ligand names, paths, and config-derived values are inserted directly into heredoc-generated batch scripts, which allows shell metacharacters or embedded newlines to alter submitted commands.
- Files: `scripts/dock/2_gnina.sh`, `scripts/com/0_prep.sh`, `scripts/com/1_pr_prod.sh`, `scripts/com/2_sub_mmpbsa.sh`
- Current mitigation: most direct command calls quote file paths, and the workflow assumes trusted local inputs.
- Recommendations: restrict ligand identifiers to a safe character set, escape all heredoc substitutions, and reject unsafe config values before writing batch scripts.

**Repository-local environment sourcing executes arbitrary shell on every stage startup:**
- Risk: `init_script()` and `ensure_env()` source `scripts/setenv.sh` automatically, so any edit to that file executes in every shell stage and command wrapper.
- Files: `scripts/infra/common.sh`, `scripts/commands/common.sh`, `scripts/setenv.sh`
- Current mitigation: none beyond repository trust.
- Recommendations: keep `scripts/setenv.sh` minimal, validate tool presence separately, and gate auto-sourcing behind an explicit opt-in for unattended runs.

## Performance Bottlenecks

**Nested frame × residue distance loops dominate contact analysis time:**
- Problem: contact code walks every trajectory frame and then every receptor residue, rebuilding a full residue-to-ligand distance array for each residue.
- Files: `scripts/com/3_com_ana_trj.py`, `scripts/com/4_fp.py`
- Cause: `compute_contact_frequency()` and `calculate_fingerprints()` use nested Python loops around `mda.lib.distances.distance_array()` instead of vectorized residue-contact workflows.
- Improvement path: precompute residue atom groups, use MDAnalysis contact utilities, or compute one receptor–ligand distance tensor per frame instead of one matrix per residue.

**Fingerprint heatmap creation scales quadratically with frame count:**
- Problem: `_pairwise_dice()` materializes an `n_frames × n_frames` dense matrix and `_write_heatmap_png()` renders the full matrix regardless of trajectory length.
- Files: `scripts/com/4_fp.py`
- Cause: full pairwise similarity is computed for every frame pair.
- Improvement path: sample frames, use a windowed/banded comparison, or make heatmap generation optional above a frame threshold.

**RMSF computation loads every frame into memory before reduction:**
- Problem: `compute_rmsf()` appends every coordinate frame into `coords` and then runs `np.stack()` on the full trajectory.
- Files: `scripts/com/3_com_ana_trj.py`
- Cause: the implementation uses batch statistics instead of streaming accumulation.
- Improvement path: replace the list-of-arrays approach with online mean/variance accumulation or chunked frame processing.

**Docking parallelism stops at one Slurm job per ligand:**
- Problem: each docking job loops serially across `seq 0 $((ENSEMBLE_SIZE - 1))` inside the job body.
- Files: `scripts/dock/2_gnina.sh`
- Cause: scheduling is ligand-level only, not receptor–ligand-pair level.
- Improvement path: move receptor conformers into a Slurm array or split each receptor–ligand pair into an independent task.

## Fragile Areas

**Topology assembly and include propagation depend on filename conventions and intermediate side files:**
- Files: `scripts/dock/4_dock2com_2.py`, `scripts/dock/4_dock2com.sh`, `scripts/dock/4_dock2com_ref.sh`, `scripts/com/0_prep.sh`
- Why fragile: `scripts/dock/4_dock2com_2.py` emits generated `*_rec.itp` and `*_clean.itp` files beside `sys.top`, wrapper copy logic looks for `rec.itp` instead, and `scripts/com/0_prep.sh` has its own topology-construction path.
- Safe modification: change topology handling only after validating both the original ligand directory workflow and the copied `${COM_DIR}` outputs for AMBER and CHARMM cases.
- Test coverage: no automated tests detected for include propagation, copied-output completeness, or cross-wrapper topology consistency.

**Production-to-analysis file contracts are internally inconsistent:**
- Files: `scripts/com/1_pr_prod.sh`, `scripts/com/2_trj4mmpbsa.sh`, `scripts/com/3_ana.sh`, `scripts/com/4_cal_fp.sh`, `WORKFLOW.md`, `.opencode/docs/AGENT-WORKFLOW.md`
- Why fragile: stage documentation describes analysis of production outputs, but analysis wrappers search for MM/PBSA-style filenames in different locations.
- Safe modification: align on one canonical analysis input contract (`prod_*` or generated `com_*`) and update both wrappers and docs together.
- Test coverage: no automated tests detected for stage-to-stage artifact naming or analysis-target discovery.

**Environment bootstrap is brittle in non-interactive shells:**
- Files: `scripts/infra/common.sh`, `scripts/commands/common.sh`, `scripts/setenv.sh`
- Why fragile: `conda activate autoEnsmblDockMD` is sourced without checking that Conda shell hooks are loaded, and every stage assumes the source succeeds.
- Safe modification: make activation idempotent, tolerate already-active environments, and detect missing Conda initialization before sourcing.
- Test coverage: no automated tests detected for shell initialization behavior.

## Scaling Limits

**Trajectory analysis runtime and memory are bounded by dense in-memory arrays:**
- Current capacity: limited by `n_frames × n_atoms × 3` storage in `scripts/com/3_com_ana_trj.py` and by `n_frames × n_residues` plus `n_frames × n_frames` matrices in `scripts/com/4_fp.py`; no hard safety threshold is enforced.
- Limit: long production trajectories can exhaust memory or make analysis impractically slow.
- Scaling path: chunk trajectories, stream per-frame statistics, and disable quadratic outputs automatically above a configured size.

**Docking throughput grows linearly with ligand count times ensemble size:**
- Current capacity: one submitted job per ligand, with each job looping over all receptor conformers in `scripts/dock/2_gnina.sh`.
- Limit: a single slow receptor blocks completion of the whole ligand job, and large ensembles waste available cluster parallelism.
- Scaling path: submit receptor–ligand pairs independently and merge results after all pair jobs complete.

## Dependencies at Risk

**Dual RDKit / Open Babel conversion backends do not share a validated atom-naming contract:**
- Risk: `scripts/dock/4_dock2com_1.py` can generate `best.gro` through either RDKit or `obabel`, but the later hard validation in `scripts/dock/4_dock2com_2.2.1.py` assumes the backend preserves ITP-compatible atom names and ordering.
- Impact: identical inputs can behave differently depending on which backend is installed, causing backend-specific dock2com failures.
- Migration plan: standardize on one supported backend or add an explicit normalization step that maps converted GRO atoms to the ligand ITP before validation.

## Missing Critical Features

**No regression checks for nm↔Å conversion and atom-order preservation across the ligand-conversion chain:**
- Problem: current code scales coordinates in `scripts/dock/4_dock2com_1.py` and `scripts/dock/0_gro_itp_to_mol2.py`, and analysis scripts report angstrom-based metrics in `scripts/com/3_com_ana_trj.py` and `scripts/com/4_fp.py`, but there is no automated guard that proves unit labels and atom ordering stay correct end to end.
- Blocks: safe extension to new ligand sources, conversion backends, or refactors in the dock-to-complex path.

**No automated check that workflow docs match actual handoff JSON and stage artifact contracts:**
- Problem: `.opencode/docs/AGENT-WORKFLOW.md` documents an `inputs` / `outputs` / `next_action` handoff schema, while `scripts/agents/schemas/handoff.py` serializes `from_agent`, `to_agent`, `data`, `warnings`, `errors`, `recommendations`, and `metadata`.
- Blocks: reliable agent orchestration based on documentation alone, and safe doc edits during future namespace or workflow updates.

**No automated script-level test suite for core pipeline stages:**
- Problem: no `*.test.*` or `*.spec.*` files are present for the shell/Python workflow scripts despite heavy branching across `scripts/dock/*.py`, `scripts/com/*.sh`, and `scripts/infra/*.sh`.
- Blocks: low-risk refactoring of correctness-sensitive pipeline logic without manual end-to-end reruns.

## Test Coverage Gaps

**Dock2com backend behavior and restraint validation are untested:**
- What's not tested: RDKit-vs-Open-Babel conversion parity, GRO atom naming normalization, generated `*_clean.itp` / `*_rec.itp` propagation, and strict GRO↔ITP validation behavior.
- Files: `scripts/dock/4_dock2com_1.py`, `scripts/dock/4_dock2com_2.py`, `scripts/dock/4_dock2com_2.2.1.py`, `scripts/dock/4_dock2com.sh`, `scripts/dock/4_dock2com_ref.sh`
- Risk: correctness fixes around atom-name/order mismatches can still break one backend or one wrapper path silently.
- Priority: High

**Production-to-analysis artifact discovery is untested:**
- What's not tested: whether `scripts/com/1_pr_prod.sh` outputs can be consumed directly by `scripts/com/3_ana.sh` and `scripts/com/4_cal_fp.sh`, or whether MM/PBSA chunk outputs are the real expected inputs.
- Files: `scripts/com/1_pr_prod.sh`, `scripts/com/2_trj4mmpbsa.sh`, `scripts/com/3_ana.sh`, `scripts/com/4_cal_fp.sh`
- Risk: analysis stages can fail late or be run against unintended files after long production jobs complete.
- Priority: High

**Config loading and documentation contracts are untested:**
- What's not tested: `${section:key}` interpolation behavior, direct Python helper section selection, `aedmd-*` command documentation drift, and handoff-schema agreement between docs and runtime JSON.
- Files: `scripts/infra/config_loader.sh`, `scripts/config.ini.template`, `scripts/dock/4_dock2com_1.py`, `scripts/dock/4_dock2com_2.py`, `AGENTS.md`, `.opencode/docs/AGENT-WORKFLOW.md`, `scripts/agents/schemas/handoff.py`
- Risk: users can follow current docs and still hit setup or orchestration failures without any failing unit test to catch the mismatch.
- Priority: High

---

*Concerns audit: 2026-04-19*
