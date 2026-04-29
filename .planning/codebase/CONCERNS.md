# Codebase Concerns

**Analysis Date:** 2026-04-29

## Tech Debt

**Configuration parsing is implemented three different ways:**
- Issue: shell stages use `scripts/infra/config_loader.sh`, agent CLI uses `scripts/infra/config.py`, and preflight uses `configparser.ExtendedInterpolation()` in `scripts/infra/plugins/preflight.py`.
- Files: `scripts/infra/config_loader.sh`, `scripts/infra/config.py`, `scripts/infra/plugins/preflight.py`, `work/test/config.ini`, `scripts/config.ini.template`
- Impact: the same `config.ini` can resolve differently across shell stages, Python helpers, and preflight checks, especially for `${section:key}` values used throughout `work/test/config.ini` and `scripts/config.ini.template`.
- Fix approach: centralize config parsing behind one interpolation-aware implementation and make shell/Python callers share the same resolved values.

**Large stage scripts still combine validation, orchestration, and job-script generation:**
- Issue: core workflow scripts build Slurm heredocs, discover inputs, validate config, and execute domain logic in single files.
- Files: `scripts/dock/2_gnina.sh`, `scripts/com/0_prep.sh`, `scripts/com/1_pr_prod.sh`, `scripts/com/2_trj4mmpbsa.sh`, `scripts/infra/executor.py`
- Impact: small changes are high-risk because command rendering, file contracts, and workflow semantics are tightly coupled.
- Fix approach: split input discovery, config validation, Slurm rendering, and stage execution into reusable units with direct tests.

**Safety rules documented in `AGENTS.md` are not enforced by runtime code:**
- Issue: repository guidance says no `rm` outside test workspaces and emphasizes controlled environment handling, but stage scripts still remove files and auto-source environment files without policy checks.
- Files: `AGENTS.md`, `scripts/rec/3_ana.sh`, `scripts/infra/common.sh`, `scripts/commands/common.sh`, `scripts/setenv.sh`
- Impact: operator expectations differ from actual runtime behavior, which makes automation behavior harder to trust.
- Fix approach: codify policy in shared helpers instead of leaving it as documentation-only guidance.

**Core pipeline coverage is missing beyond infrastructure smoke tests:**
- Issue: current tests only exercise infrastructure helpers and Phase 6 wrappers, not the receptor, docking, complex-prep, MD, or MM/PBSA stage scripts.
- Files: `tests/phase06_integration_test.sh`, `work/test/infrastructure/test_infra.py`, `scripts/rec/0_prep.sh`, `scripts/dock/2_gnina.sh`, `scripts/com/0_prep.sh`, `scripts/com/1_pr_prod.sh`
- Impact: regressions in stage contracts are likely to surface only after long-running jobs.
- Fix approach: add fixture-driven tests for stage argument handling, rendered Slurm scripts, and stage-to-stage artifact contracts.

## Known Bugs

**Agent runner drops the configured `--config` path before executing stage scripts:**
- Symptoms: slash-command wrappers can dispatch a runner handoff successfully, but the actual stage script runs with default values or an empty config path instead of the requested config file.
- Files: `scripts/commands/common.sh`, `scripts/agents/runner.py`, `scripts/agents/__main__.py`
- Trigger: run any runner-backed command such as `scripts/commands/aedmd-rec-ensemble.sh` or `scripts/commands/aedmd-dock-run.sh` with `--config`.
- Workaround: run stage scripts directly with explicit `--config`, or modify wrapper params so `config` is forwarded as a real script flag.

**`run_pipeline.sh` advances into downstream stages after async submissions without waiting for outputs:**
- Symptoms: the wrapper can submit receptor MD, complex MD, or MM/PBSA jobs and then immediately continue into analysis or dependent stages before artifacts exist.
- Files: `scripts/run_pipeline.sh`, `scripts/rec/1_pr_rec.sh`, `scripts/com/1_pr_prod.sh`, `scripts/com/2_run_mmpbsa.sh`, `scripts/com/2_sub_mmpbsa.sh`, `WORKFLOW.md`
- Trigger: run `bash scripts/run_pipeline.sh --config <file>` for the default full pipeline.
- Workaround: run asynchronous stages manually and wait for scheduler completion before invoking dependent stages.

**Handoff inspection masks failed latest handoffs as success:**
- Symptoms: `scripts/commands/aedmd-handoff-inspect.sh` can exit successfully even when the latest inspected handoff represents `failure` or `blocked`.
- Files: `scripts/infra/plugins/handoff_inspect.py`, `scripts/commands/aedmd-handoff-inspect.sh`, `scripts/commands/common.sh`
- Trigger: inspect a workspace whose newest `.handoffs/*.json` file has status `failure` or `blocked`.
- Workaround: read the generated `.handoffs/handoff_inspection.json` and the original handoff file directly instead of trusting the wrapper exit code.

**Group-ID checker looks in the wrong place for normal MM/PBSA outputs:**
- Symptoms: `scripts/commands/aedmd-group-id-check.sh` validates only one workspace directory root, while MM/PBSA preparation writes `index.ndx` and `mmpbsa_groups.dat` inside ligand directories.
- Files: `scripts/infra/plugins/group_id_check.py`, `scripts/commands/aedmd-group-id-check.sh`, `scripts/com/2_trj4mmpbsa.sh`
- Trigger: run the checker against a standard workspace root such as `work/test` instead of a specific ligand directory.
- Workaround: point the checker at an individual ligand directory that actually contains `index.ndx` and `mmpbsa_groups.dat`.

**Preflight input validation hardcodes `work/input` and can warn on valid workspaces:**
- Symptoms: preflight reports missing inputs even when a workspace is configured correctly but does not mirror the fixed `work/input` layout.
- Files: `scripts/infra/plugins/preflight.py`, `work/test/config.ini`, `WORKFLOW.md`
- Trigger: run `scripts/commands/aedmd-preflight.sh` from a workspace that stores inputs according to config paths rather than under `work/input`.
- Workaround: treat preflight input warnings as advisory and verify actual configured paths manually.

**Workspace initialization is still project-specific despite being presented as generic:**
- Symptoms: workspace init warns about missing `rec.pdb`, `ref.pdb`, `dzp`, and `ibp` even though the broader workflow is config-driven and uses receptor/ligand paths from `config.ini`.
- Files: `scripts/infra/plugins/workspace_init.py`, `scripts/config.ini.template`, `WORKFLOW.md`
- Trigger: initialize a valid template that lacks those hardcoded filenames.
- Workaround: ignore those warnings when the template is otherwise complete, or rename assets to match the plugin's assumptions.

## Security Considerations

**Repository-local shell sourcing is an implicit code-execution boundary:**
- Risk: every shell stage and command wrapper sources `scripts/setenv.sh`, so any edit to that file executes automatically in operator shells and batch-launch contexts.
- Files: `scripts/infra/common.sh`, `scripts/commands/common.sh`, `scripts/setenv.sh`
- Current mitigation: none beyond repository trust.
- Recommendations: make environment sourcing opt-in or validate expected commands without sourcing arbitrary repository shell code.

**Generated Slurm scripts still depend on trusted filesystem and config inputs:**
- Risk: stage scripts embed config-derived values into heredoc-generated batch files; several values are validated, but path-like fields and some free-form strings still flow into job scripts.
- Files: `scripts/dock/2_gnina.sh`, `scripts/com/0_prep.sh`, `scripts/com/1_pr_prod.sh`, `scripts/com/2_sub_mmpbsa.sh`
- Current mitigation: some identifiers are restricted with `require_safe_id`, integer checks, and partition validation.
- Recommendations: validate all interpolated path/string fields before heredoc generation and prefer passing values as arguments or environment files instead of inline shell fragments.

## Performance Bottlenecks

**Docking scheduling scales only at ligand-job granularity:**
- Problem: each ligand is submitted as one Slurm job, and receptor conformers are processed inside that job with bounded background parallelism.
- Files: `scripts/dock/2_gnina.sh`
- Cause: the script submits per-ligand jobs and loops over receptor indices inside the batch script.
- Improvement path: submit receptor–ligand pairs as array tasks and merge outputs afterward.

**Log monitoring utilities read entire files repeatedly:**
- Problem: monitoring methods load whole logs into memory for status checks, summary generation, and even `tail()`.
- Files: `scripts/infra/monitor.py`
- Cause: `_read_lines()` reads full files and higher-level methods call it repeatedly.
- Improvement path: stream incremental reads, cache parsed state, and implement real seek-based tailing for large HPC logs.

**Executor and stage wrappers offer little batching around scheduler polling:**
- Problem: common Slurm helpers rely on repeated `squeue`/`sacct` polling and many stages submit one job per ligand/trial independently.
- Files: `scripts/infra/common.sh`, `scripts/infra/executor.py`, `scripts/com/1_pr_prod.sh`, `scripts/com/2_sub_mmpbsa.sh`
- Cause: orchestration is mostly per-job rather than array- or stage-batch-oriented.
- Improvement path: consolidate polling, use richer array jobs, and record job dependency graphs instead of launching many small independent submissions.

## Fragile Areas

**Stage contracts between runner/analyzer/wrappers are easy to break:**
- Files: `scripts/commands/common.sh`, `scripts/agents/runner.py`, `scripts/agents/analyzer.py`, `scripts/agents/schemas/state.py`, `scripts/agents/utils/routing.py`
- Why fragile: wrappers, stage enums, explicit script mapping, and agent command builders are maintained separately; one mismatch silently changes what script actually runs.
- Safe modification: update stage enums, command mappings, and wrapper dispatch behavior together, then validate generated handoffs end to end.
- Test coverage: only infrastructure-level smoke coverage exists in `tests/phase06_integration_test.sh` and `work/test/infrastructure/test_infra.py`.

**Environment bootstrap is brittle in non-interactive shells:**
- Files: `scripts/setenv.sh`, `scripts/infra/common.sh`, `scripts/commands/common.sh`
- Why fragile: `scripts/setenv.sh` runs `conda activate autoEnsmblDockMD` without initializing Conda shell hooks or checking whether activation succeeded.
- Safe modification: make activation idempotent, detect missing Conda initialization explicitly, and fail with a clear message when the environment cannot be activated.
- Test coverage: no automated coverage detected for shell startup behavior.

**MM/PBSA helper plugins assume workspace layouts that differ from stage outputs:**
- Files: `scripts/infra/plugins/group_id_check.py`, `scripts/infra/plugins/preflight.py`, `scripts/com/2_trj4mmpbsa.sh`, `work/test/config.ini`
- Why fragile: plugins inspect fixed locations while the pipeline writes many outputs per ligand and relies heavily on config-driven paths.
- Safe modification: derive plugin paths from resolved config and ligand targets instead of hardcoded workspace conventions.
- Test coverage: wrapper tests cover missing-file behavior, not successful validation against real per-ligand outputs.

## Scaling Limits

**Job count grows with ligands × trials × MM/PBSA chunks:**
- Current capacity: `scripts/com/1_pr_prod.sh` submits one equilibration job and one dependent production job per ligand/trial, and `scripts/com/2_sub_mmpbsa.sh` submits one array per ligand.
- Limit: large ligand sets create many scheduler objects and long orchestration times before computation even starts.
- Scaling path: consolidate jobs with larger arrays and make job metadata machine-readable for resumable monitoring.

**Single-node analysis assumptions limit large-trajectory handling:**
- Current capacity: analysis and monitoring helpers assume local file access and in-memory processing on one node.
- Limit: large log files and large trajectory-derived outputs become slow or memory-heavy to inspect and summarize.
- Scaling path: stream outputs, checkpoint partial analysis, and separate metadata collection from heavy numeric processing.

## Dependencies at Risk

**Workflow correctness depends on external HPC tools with only runtime availability checks:**
- Risk: many stages require `gmx`, `gnina`, `gmx_MMPBSA`, `sbatch`, `squeue`, and `sacct`, but compatibility and feature assumptions are validated only when stages start.
- Impact: failures appear late after workspace setup and partial job submission.
- Migration plan: extend preflight to verify tool versions and scheduler capabilities against the expectations documented in `WORKFLOW.md` and `scripts/env.yml`.

## Missing Critical Features

**No end-to-end regression test for the full config-to-wrapper-to-stage path:**
- Problem: there is no automated proof that a wrapper command passes config, workspace, and params correctly into the underlying stage script.
- Blocks: safe refactoring of `scripts/commands/common.sh`, `scripts/agents/__main__.py`, and `scripts/agents/runner.py`.

**No workflow-level wait/resume contract inside `run_pipeline.sh`:**
- Problem: the top-level wrapper does not pause on async stages or persist scheduler state needed for deterministic resume.
- Blocks: reliable unattended full-pipeline runs from `scripts/run_pipeline.sh` alone.

## Test Coverage Gaps

**Agent wrapper execution path is under-tested:**
- What's not tested: whether wrapper `--config` arguments propagate into executed stage scripts, whether analyzer/runner mappings stay correct, and whether failed handoffs return the right exit code.
- Files: `scripts/commands/common.sh`, `scripts/agents/__main__.py`, `scripts/agents/runner.py`, `scripts/infra/plugins/handoff_inspect.py`
- Risk: orchestration can appear healthy while running with the wrong config or masking failures.
- Priority: High

**Async stage sequencing is untested:**
- What's not tested: that `scripts/run_pipeline.sh` respects Slurm completion boundaries between `rec_prod`, `com_prod`, `com_mmpbsa`, and downstream stages.
- Files: `scripts/run_pipeline.sh`, `scripts/rec/1_pr_rec.sh`, `scripts/com/1_pr_prod.sh`, `scripts/com/2_run_mmpbsa.sh`, `scripts/com/2_sub_mmpbsa.sh`
- Risk: full pipeline runs can fail late because dependent stages start before required artifacts exist.
- Priority: High

**Plugin assumptions versus real workspace layouts are untested:**
- What's not tested: successful plugin behavior against real ligand directories, config-resolved paths, and non-template workspaces.
- Files: `scripts/infra/plugins/preflight.py`, `scripts/infra/plugins/group_id_check.py`, `scripts/infra/plugins/workspace_init.py`, `scripts/com/2_trj4mmpbsa.sh`
- Risk: support tooling can produce false warnings or validate the wrong directory structure.
- Priority: High

---

*Concerns audit: 2026-04-29*
