# Documentation Consistency and Citation Analysis

**Timestamp:** 2026-04-19 20:50:30

## Summary

- **Issues found:** 18
- **Critical:** 7
- **Medium:** 8
- **Low:** 3

Most gaps fall into four buckets:

1. Human-facing docs describe `scripts/run_pipeline.sh` as an end-to-end runner, but multiple stage scripts only submit Slurm jobs and return immediately.
2. Agent-facing docs and skill files do not match the current wrapper/agent contract in `scripts/commands/*.sh` and `scripts/agents/*.py`.
3. Config documentation in `docs/GUIDE.md` and `WORKFLOW.md` is missing active parameters used in code.
4. Planning artifacts in `.planning/STATE.md` and `.planning/PROJECT.md` contain outdated or unimplemented decisions.

---

## Detailed Discrepancies by Document

### `README.md`

1. **Full-pipeline execution is documented as directly runnable, but the implementation is asynchronous.**
   - Docs: `README.md`, `WORKFLOW.md`, `docs/GUIDE.md`
   - Code: `scripts/run_pipeline.sh`, `scripts/rec/0_prep.sh`, `scripts/rec/1_pr_rec.sh`, `scripts/com/0_prep.sh`, `scripts/com/1_pr_prod.sh`, `scripts/com/2_sub_mmpbsa.sh`
   - Discrepancy: `README.md` presents `bash scripts/run_pipeline.sh --config ...` as a complete pipeline run, but several stages only submit Slurm jobs with `sbatch` and do not wait for completion. Downstream stages in `scripts/run_pipeline.sh` still execute immediately.
   - Impact: fresh end-to-end runs will fail or race on missing artifacts.

2. **Environment path is inconsistently documented.**
   - Docs: `README.md`, `WORKFLOW.md`, `AGENTS.md`, `docs/EXPERIMENTAL.md`
   - Code/files: `scripts/env.yml`
   - Discrepancy: some docs say `env.yml`, while the actual file is `scripts/env.yml`.
   - Impact: setup commands copied from `AGENTS.md` are incorrect.

### `WORKFLOW.md`

3. **Stage 1 marks alignment as optional, but the default pipeline always runs it.**
   - Docs: `WORKFLOW.md`
   - Code: `scripts/run_pipeline.sh`
   - Discrepancy: `WORKFLOW.md` lists `scripts/rec/5_align.py` as optional, but `DEFAULT_PIPELINE_STAGES` always includes `rec_align`.
   - Impact: workflow expectations diverge for blind-docking users and for workspaces without `align_reference`.

4. **Stage 2 script order does not match wrapper behavior.**
   - Docs: `WORKFLOW.md`, `README.md`
   - Code: `scripts/run_pipeline.sh`, `scripts/dock/1_rec4dock.sh`, `scripts/dock/2_gnina.sh`, `scripts/dock/3_dock_report.sh`
   - Discrepancy: docs describe Stage 2 as including receptor preparation via `scripts/dock/1_rec4dock.sh`, but `scripts/run_pipeline.sh` never dispatches that script.
   - Impact: the documented stage map is not the actual wrapper stage map.

5. **Stage 5 input documentation omits an active MM/PBSA parameter.**
   - Docs: `WORKFLOW.md`, `docs/GUIDE.md`
   - Code: `scripts/com/2_trj4mmpbsa.sh`, `scripts/com/2_mmpbsa.sh`
   - Missing parameter: `[mmpbsa] group_ids_file`
   - Impact: users cannot discover or override the persisted MM/PBSA group-ID file used by the implementation.

6. **Stage 6 input documentation omits an active analysis parameter.**
   - Docs: `WORKFLOW.md`, `docs/GUIDE.md`
   - Code: `scripts/com/3_com_ana_trj.py`
   - Missing parameter: `[analysis] distance_reference`
   - Impact: the advanced distance metric is configurable in code but undocumented.

### `docs/GUIDE.md`

7. **Optional utility config sections are used in code but undocumented in the guide.**
   - Docs: `docs/GUIDE.md`
   - Code: `scripts/com/4_cal_fp.sh`, `scripts/com/5_arc_sel.sh`, `scripts/com/5_rerun_sel.sh`
   - Missing sections: `[fingerprint]`, `[archive]`, `[rerun]`
   - Impact: optional pipeline branches are effectively hidden from users.

8. **Guide implies Stage 4/5/6 progression as if outputs are immediately ready after stage execution.**
   - Docs: `docs/GUIDE.md`
   - Code: `scripts/com/0_prep.sh`, `scripts/com/1_pr_prod.sh`, `scripts/com/2_sub_mmpbsa.sh`
   - Discrepancy: the guide reads as synchronous stage progression, but those scripts submit jobs and exit.
   - Impact: troubleshooting guidance is incomplete for the most common HPC execution pitfall.

### `AGENTS.md`

9. **Agent role description does not match the current runner implementation contract.**
   - Docs: `AGENTS.md`
   - Code: `scripts/commands/aedmd-rec-ensemble.sh`, `scripts/commands/aedmd-dock-run.sh`, `scripts/commands/aedmd-com-setup.sh`, `scripts/agents/runner.py`
   - Discrepancy: `AGENTS.md` says runner agents execute stage scripts through wrappers, but wrappers only pass `stage/config/params`; `RunnerAgent.execute()` requires `input_data["script"]` and does not derive the script from stage.
   - Impact: the documented wrapper→runner flow is not currently executable as described.

10. **Orchestrator-resume is documented as available, but the current wrapper stage token is incompatible with the orchestrator enum.**
   - Docs: `AGENTS.md`, `.opencode/skills/aedmd-orchestrator-resume/SKILL.md`
   - Code: `scripts/commands/aedmd-orchestrator-resume.sh`, `scripts/agents/orchestrator.py`, `scripts/agents/schemas/state.py`
   - Discrepancy: wrapper dispatches stage `orchestrator_resume`, but `OrchestratorAgent._parse_stage()` only accepts enum values like `init`, `receptor_prep`, `complex_analysis`, etc.
   - Impact: documented resume flow is not aligned with implementation.

11. **Checkpoint path naming is inconsistent with implementation.**
   - Docs: `.opencode/skills/aedmd-orchestrator-resume/SKILL.md`
   - Code: `scripts/agents/base.py`, `scripts/infra/checkpoint.py` usage via `.checkpoints`
   - Discrepancy: the skill says `.checkpoint/state.json`; implementation uses workspace `.checkpoints/`.
   - Impact: resume troubleshooting instructions point to the wrong location.

### `docs/EXPERIMENTAL.md`

12. **Skill format description conflicts with current agent docs.**
   - Docs: `docs/EXPERIMENTAL.md`, `AGENTS.md`, `README.md`
   - Discrepancy: `docs/EXPERIMENTAL.md` says skill docs follow `agentskills.io v1` conventions; `AGENTS.md` and `README.md` describe a repo-specific restored YAML-frontmatter contract.
   - Impact: contributor guidance is internally inconsistent.

### Skill files in `.opencode/skills/*/SKILL.md`

13. **Wrapper stage names and skill stage names diverge.**
   - Docs: `.opencode/skills/aedmd-rec-ensemble/SKILL.md`, `.opencode/skills/aedmd-dock-run/SKILL.md`, `.opencode/skills/aedmd-com-setup/SKILL.md`, `.opencode/skills/aedmd-com-md/SKILL.md`, `.opencode/skills/aedmd-com-mmpbsa/SKILL.md`, `.opencode/skills/aedmd-com-analyze/SKILL.md`, `.opencode/skills/aedmd-checker-validate/SKILL.md`, `.opencode/skills/aedmd-debugger-diagnose/SKILL.md`
   - Code: `scripts/commands/*.sh`, `scripts/agents/analyzer.py`
   - Discrepancy examples:
     - skill stage `receptor_cluster` vs wrapper stage `rec_ensemble`
     - skill stage `complex_analysis` vs wrapper stage `com_analyze`
     - skill stage `complex_prep` vs wrapper stage `com_setup`
   - Impact: handoff filenames and expected stage semantics diverge across docs and code.

14. **Expected handoff filenames in skills do not match wrapper output filenames.**
   - Docs: `.opencode/skills/aedmd-rec-ensemble/SKILL.md`, `.opencode/skills/aedmd-dock-run/SKILL.md`, `.opencode/skills/aedmd-com-setup/SKILL.md`, `.opencode/skills/aedmd-com-md/SKILL.md`, `.opencode/skills/aedmd-com-mmpbsa/SKILL.md`, `.opencode/skills/aedmd-com-analyze/SKILL.md`
   - Code: `scripts/commands/common.sh`, wrapper `check_handoff_result` calls in `scripts/commands/*.sh`
   - Discrepancy examples:
     - skill expects `.handoffs/receptor_cluster.json`, wrapper checks `.handoffs/rec_ensemble.json`
     - skill expects `.handoffs/docking_run.json`, wrapper checks `.handoffs/dock_run.json`
     - skill expects `.handoffs/complex_analysis.json`, wrapper checks `.handoffs/com_analyze.json`
   - Impact: agent operators following skills will inspect the wrong files.

15. **Several documented CLI flags do not exist in wrappers.**
   - Docs: `.opencode/skills/aedmd-orchestrator-resume/SKILL.md`, `.opencode/skills/aedmd-debugger-diagnose/SKILL.md`, `.opencode/skills/aedmd-checker-validate/SKILL.md`
   - Code: `scripts/commands/aedmd-orchestrator-resume.sh`, `scripts/commands/aedmd-debugger-diagnose.sh`, `scripts/commands/aedmd-checker-validate.sh`, `scripts/commands/common.sh`
   - Unsupported documented flags include: `--input`, `--checkpoint`, `--log-root`, `--report-output`.
   - Impact: direct command examples in skills are misleading.

16. **`aedmd-status` skill documents behavior that is not implemented.**
   - Docs: `.opencode/skills/aedmd-status/SKILL.md`
   - Code: `scripts/commands/aedmd-status.sh`
   - Discrepancy: skill claims `--verbose` enables detailed path checks and references config keys like `general.config` and `status.verbose`; wrapper only prints workspace/config/mode/handoffs and has no extra verbose branch.
   - Impact: status command capabilities are overstated.

17. **`aedmd-com-analyze` skill promises comparative artifacts not produced by the shell wrapper.**
   - Docs: `.opencode/skills/aedmd-com-analyze/SKILL.md`
   - Code: `scripts/com/3_ana.sh`, `scripts/com/3_com_ana_trj.py`
   - Discrepancy: skill mentions comparative artifacts in `com_ana/`, but the implementation writes per-ligand outputs under `<ligand>/<analysis.output_subdir>/`.
   - Impact: output navigation guidance is inaccurate.

### Planning state documents

18. **Planning artifacts contain outdated or unimplemented statements.**
   - Docs: `.planning/PROJECT.md`, `.planning/STATE.md`
   - Code: `WORKFLOW.md`, `scripts/rec/0_prep.sh`, `scripts/com/0_prep.sh`
   - Discrepancies:
     - `.planning/PROJECT.md` still says `WORKFLOW.md` is marked “TO BE FINALIZED” and describes an older five-stage model with separate ligand preparation.
     - `.planning/STATE.md` records a decision that configured `water_model` is used in `gmx solvate` with `spc216` fallback, but `scripts/rec/0_prep.sh` still hardcodes `gmx solvate -cs spc216`.
   - Impact: planning state is not a reliable implementation reference.

---

## Missing or Outdated Content by Category

### Undocumented config parameters

- `[mmpbsa] group_ids_file` used in `scripts/com/2_trj4mmpbsa.sh` and `scripts/com/2_mmpbsa.sh`
- `[analysis] distance_reference` used in `scripts/com/3_com_ana_trj.py`

### Undocumented workflow branches / utility sections

- `[fingerprint]` used by `scripts/com/4_cal_fp.sh`
- `[archive]` used by `scripts/com/5_arc_sel.sh`
- `[rerun]` used by `scripts/com/5_rerun_sel.sh`

### Outdated examples or patterns

- `env.yml` path examples should be updated to `scripts/env.yml`
- agent skill examples using `.handoffs/latest.json` are not aligned with wrapper behavior in `scripts/commands/common.sh`
- `.planning/PROJECT.md` still describes older workflow structure and outdated finalization status

### Missing troubleshooting guidance

- `scripts/run_pipeline.sh` does not wait for Slurm jobs; docs need an explicit warning and recommended usage pattern
- agent wrapper/skill stage-token mismatches are not documented anywhere user-facing
- MM/PBSA group-ID persistence via `mmpbsa_groups.dat` is undocumented, despite being part of the recovery path in `scripts/com/2_mmpbsa.sh`
- receptor-stage water model behavior should be clarified because `scripts/rec/0_prep.sh` currently hardcodes `spc216` for solvation

### Error messages and exit-code coverage

- No reviewed doc explains that `scripts/commands/common.sh` returns:
  - `0` for success
  - `1` for failure/blocked/unknown
  - `2` for `needs_review`
- No human-facing doc explains how to interpret handoff status values from `scripts/agents/schemas/handoff.py`

---

## Citation Suggestions

Add citations where methodology or software is described, especially in `README.md`, `WORKFLOW.md`, and `docs/GUIDE.md`.

### Core workflow / software stack

- `README.md` project overview and installation section
  - **Cite:** GROMACS paper
  - **Cite:** gnina paper
  - **Cite:** gmx_MMPBSA paper

- `WORKFLOW.md` prerequisites and stage overview
  - **Cite:** GROMACS methodology paper
  - **Cite:** ensemble docking / receptor conformational selection paper

### Docking methodology

- `README.md` Pipeline Overview Stage 2
- `WORKFLOW.md` Stage 2
- `docs/GUIDE.md` Stage 2 and output interpretation
  - **Cite:** gnina 2021 paper
  - **Cite:** AutoDock Vina / smina methodology paper

### Molecular dynamics methodology

- `README.md` Pipeline Overview Stages 1 and 4
- `WORKFLOW.md` Stages 1 and 4
- `docs/GUIDE.md` Force Field Compatibility section
  - **Cite:** GROMACS paper
  - **Cite:** AMBER ff14SB / amber19sb paper
  - **Cite:** CHARMM36m paper
  - **Cite:** CGenFF paper

### MM/PBSA theory and tooling

- `README.md` Pipeline Overview Stage 5
- `WORKFLOW.md` Stage 5
- `docs/GUIDE.md` Stage 5 and troubleshooting
  - **Cite:** MM/PBSA theory paper
  - **Cite:** gmx_MMPBSA tool paper

### Analysis libraries

- `README.md` Analysis section / Stage 6
- `WORKFLOW.md` Stage 6
- `docs/GUIDE.md` Stage 6
  - **Cite:** MDAnalysis library paper
  - **Cite:** MDAnalysis 2.x paper/update

### Receptor ensemble generation

- `WORKFLOW.md` Stage 1
- `docs/GUIDE.md` Stage 1
  - **Cite:** receptor ensemble / ensemble docking methodology paper
  - **Cite:** clustering-based representative structure selection paper

---

## Recommended Documentation Improvements

1. **Split “pipeline run” docs into synchronous vs scheduler-submission modes.**
   - Update `README.md`, `WORKFLOW.md`, and `docs/GUIDE.md` to state clearly that `scripts/run_pipeline.sh` dispatches submission scripts and does not wait for Slurm completion.

2. **Make one stage vocabulary authoritative.**
   - Standardize stage IDs across `AGENTS.md`, `.opencode/skills/*/SKILL.md`, `scripts/commands/*.sh`, and `scripts/agents/*.py`.

3. **Align wrapper docs with actual supported flags.**
   - Remove undocumented CLI flags from skill files or implement them in `scripts/commands/common.sh` and the wrapper scripts.

4. **Update config docs from code, not from templates alone.**
   - Add `[mmpbsa] group_ids_file`, `[analysis] distance_reference`, and the `[fingerprint]`, `[archive]`, `[rerun]` sections to `docs/GUIDE.md`.

5. **Repair planning artifacts used as references.**
   - Update `.planning/PROJECT.md` and `.planning/STATE.md` so they reflect the current six-stage pipeline and current receptor-water-model behavior.

6. **Document handoff semantics.**
   - Add a small status/exit-code table to `AGENTS.md` or `docs/EXPERIMENTAL.md` covering `success`, `failure`, `needs_review`, `blocked`, and wrapper exit codes from `scripts/commands/common.sh`.

7. **Add citations close to methodological claims.**
   - Add software/tool citations in `README.md` and detailed methodology citations in `WORKFLOW.md` and `docs/GUIDE.md`.

---

## Bottom Line

The largest documentation risk is not missing prose; it is **mismatch between documented orchestration behavior and the current code contracts** in `scripts/run_pipeline.sh`, `scripts/commands/*.sh`, and `scripts/agents/*.py`. The second-largest gap is **config drift**, especially for MM/PBSA recovery and analysis parameters. Scientific citation coverage is also currently minimal and should be added in the three primary human-facing docs.
