# State: autoEnsmblDockMD

**Project:** autoEnsmblDockMD
**Core Value:** Human-run pipeline producing validated, reproducible scientific outputs with minimal commands. Agent autonomy is secondary/experimental.
**Created:** 2026-03-23

---

## Current Position

| Field | Value |
|-------|-------|
| **Current Phase** | 07-first-controlled-execution (In progress) |
| **Current Plan** | 3 of 6 in current phase |
| **Last Activity** | 2026-05-03 16:55 - Production MD submitted (array job 95281) |
| **Progress** | █████████░ 59/60 plans complete (98%) |
| **Phase 7 Status** | IN PROGRESS - Stage 1 receptor production MD running (Slurm array job 95281) |
| **Next Plan** | 07-03-PLAN.md (resume after production MD completes) |
| **Checkpoint** | ⏳ Waiting for Slurm array job 95281 (4 × 60ns receptor production MD trials) |

---

## Accumulated Context

### Key Decisions (Phase 5)

| Decision | Rationale |
|----------|-----------|
| Keep AGENTS.md role-based and overview-first | Improves discoverability and reduces load-time verbosity |
| Keep SKILL.md contract strict with YAML frontmatter | Ensures deterministic parsing and runtime compatibility |
| Keep docs aligned to `scripts/config.ini.template` keys | Prevents config/documentation drift |

### Key Decisions (Phase 5.1)

| Decision | Rationale |
|----------|-----------|
| Include receptor topology body in generated `sys.top` | Prevent invalid topology assembly in complex prep |
| ~~Use configured `water_model` in `gmx solvate` with `spc216` fallback~~ **(superseded)** | Superseded by subsequent fixes introducing explicit solvent coordinate controls (`[complex] solvent_coordinates`) and updated stage-specific solvation guidance |
| Resolve MM/PBSA receptor/ligand IDs from actual `index.ndx` and propagate via `mmpbsa_groups.dat` | Prevent silent wrong-group MM/PBSA calculations when index ordering differs |
| Honor explicit non-default `[mmpbsa] receptor_group_id/ligand_group_id` overrides | Preserve escape hatch for manual system-specific recovery |
| Derive receptor GRO from docking SDF prefix and merge receptor+ligand coordinates in wrappers | Ensure wrappers generate `com.gro` before validation and maintain deterministic artifact contract |
| Treat any GRO↔ITP atom-count or atom-name/order mismatch as a hard error | Prevent silent misapplication of ligand position restraints |
| Map `com_ana` stage to `ligand` forwarding mode in `run_pipeline.sh` | Keep dispatcher/callee CLI contract consistent for per-ligand analysis targeting |
| Compute advanced RMSD with superposition before displacement measurement | Remove translational/rotational drift inflation from RMSD timeseries |
| Namespace all public skills and slash-command wrappers with `aedmd-*` | Prevent collisions with generic OpenCode command names and keep project command ownership explicit |
| Keep AGENT-WORKFLOW status vocabulary and handoff persistence docs aligned with common.sh parser/output behavior | Prevent documentation drift in orchestrator expectations and handoff status interpretation |
| Keep `aedmd-status` wrapper-local `--workdir` parsing while forwarding remaining args to `parse_flags` | Adds documented workdir targeting without regressing shared command flag behavior |

Superseded decision notes are retained for traceability and should not be treated as current implementation guarantees.

### Key Decisions (Quick Tasks)

| Decision | Rationale |
|----------|-----------|
| Enforce workspace copy pattern (`work/input` → `work/test` or `work/run_DATE`) | Preserves immutable input sources and improves reproducibility across runs |
| Prioritize targeted docking docs fix for `reference_ligand` vs `autobox_ligand` | Reduces first-run configuration ambiguity in Mode A |
| Keep `reference_ligand` and `autobox_ligand` documented as distinct targeted-mode controls in skill parameter tables | Prevents misconfiguration drift between docs, config keys, and runtime behavior |
| Prioritize preflight/workspace-init/handoff-inspector automation hooks first | Highest estimated token savings for repeated run-support workflows |
| Keep `metadata.stage` values identical to wrapper dispatch tokens | Preserves deterministic agent-stage traceability across wrappers and skills |
| Document `--config` as a CLI flag marker instead of `general.config` INI key | Prevents wrapper-arg vs config-key confusion in skill parameter tables |

### Key Decisions (Phase 6)

| Decision | Rationale |
|----------|-----------|
| Keep workspace-init as a standalone Python plugin emitting HandoffRecord JSON | Reuses established handoff schema and enables deterministic machine-readable plugin outputs |
| Delegate wrapper exit semantics to `check_handoff_result` after persisting handoff JSON | Keeps status handling consistent with existing command wrappers for success/blocked/failure paths |
| Use `ConfigParser` with `ExtendedInterpolation` in preflight validation | Preserves compatibility with `${section:key}` interpolation in template configs while validating mode and section requirements |
| Keep missing-tool and input-readiness checks as WARNING severity | Surfaces actionable setup gaps without hard-blocking valid partially initialized environments |
| Treat `index.ndx` header order as canonical group-ID source for MM/PBSA validation | Keeps receptor/ligand ID checks deterministic across generated index files |
| Keep conversion cache isolated per-workspace under `.cache/` with mtime staleness detection | Prevents cross-workspace contamination while skipping redundant deterministic conversions |
| Normalize inspected handoff stage status into uppercase summary labels (`SUCCESS/FAILED/NEEDS_REVIEW/BLOCKED`) | Gives orchestrator-facing status summaries without changing canonical handoff enum values |
| Select latest handoff by file `st_mtime` and generate status-specific `next_action` guidance | Minimizes repeated JSON parsing and provides immediate operator direction |
| Use `definePlugin` JS wrappers as OpenCode-native layer over Python plugins | Completes dual-format architecture while keeping Python as source of core logic |
| Normalize JS plugin outputs to `{ success, data, warnings, errors }` | Gives orchestrator and hooks a stable machine-readable contract |
| Bridge conversion cache via Python inline driver loading `conversion_cache.py` module path | Supports class-based get/put/clear operations without requiring a standalone Python CLI entrypoint |
| Keep one Markdown SKILL.md per Phase 6 automation hook with YAML frontmatter parity | Ensures universal agent-readable fallback for all native OpenCode plugin hooks |
| Document conversion-cache as plugin/library integration rather than a standalone wrapper command | Avoids contract drift by reflecting actual implementation boundaries |
| Use frontmatter descriptions for discovery triggers/symptoms only (avoid workflow summaries) | Improves skill selection reliability and forces full-skill reads for execution logic |
| Standardize phase-6 skills on Overview/When to Use/Quick Reference/Implementation/Common Mistakes | Improves scan speed, consistency, and CSO discoverability across automation hooks |
| Keep dry-run audit script read-only with artifact/syntax/metadata checks and explicit summary counters | Enables safe repeatable validation in any workspace without mutating user data |
| Use `/tmp`-isolated integration harness with trap-based cleanup for Phase 6 wrapper/plugin validation | Prevents contamination of real workspaces while testing end-to-end wrapper behavior |

### Key Decisions (Phase 6.1)

| Decision | Rationale |
|----------|-----------|
| Use `fcntl.flock(LOCK_EX)` for checkpoint writes and `os.fsync()` before `os.replace` | Prevents concurrent writer corruption and improves durability under process interruption |
| Use `fcntl.flock(LOCK_SH)` for checkpoint reads | Blocks reads during writes to prevent partial JSON load and resume-state corruption |
| Warn on non-sequential residue IDs in RMSF using `np.diff(residue_ids)` while preserving dictionary-key aggregation | Adds visibility for residue numbering gaps without changing already-correct residue-to-RMSF mapping |
| Use quoted heredoc templates plus escaped sed substitution in SBATCH generation | Prevents shell metacharacter interpolation from ligand/path values in generated job scripts |
| Return `UNKNOWN_AFTER_RETRIES` after bounded UNKNOWN-state retries with default 7-day timeout | Mitigates Slurm squeue/sacct TOCTOU windows and avoids infinite wait loops |
| Apply GRO box-line bounds checks in `scripts/com/0_prep.sh` `write_combined_gro()` with expected-index/line-count errors | Hardens the active merged-GRO path against truncated inputs and uncaught index crashes |
| Use ceiling-based frame stride with `max_frames` cap and streamed subprocess output files | Keeps trajectory analysis bounded/predictable and prevents output-buffer OOM in long-running jobs |
| Enforce workspace-init `--force` deletions to resolved paths within `work/` only | Prevents accidental/destructive deletion outside workspace boundary even with user-controlled target paths |
| Prohibit deletion of `work/` root and require subdirectory targets | Adds defense-in-depth against catastrophic workspace root removal |
| Consolidate phase verification into a single evidence report with per-issue PASS traces | Simplifies human approval and provides auditable closure for security/performance remediations |

### Key Decisions (Phase 7)

| Decision | Rationale |
|----------|-----------|
| Generate markdown dryrun report before expensive execution | Provides comprehensive readiness validation with clear manual approval gate |
| Parse stage registry from run_pipeline.sh instead of hardcoding | Ensures flowchart accuracy and maintainability as stages evolve |
| Use three-state status system (READY, NEEDS_REVIEW, BLOCKED) | Gives clear action guidance for different validation outcomes |
| Use workspace_init.py plugin for isolated workspace creation | Ensures security boundary enforcement and reproducible initialization |
| Accept needs_review status from preflight validation | Non-blocking warnings don't prevent execution when files are correctly located |

### Known Pitfalls

- Force-field incompatibility (AMBER protein + CGenFF ligand) can crash downstream stages.
- Missing hydrogens can break docking/MD/MM/PBSA.
- Context/session overflow risk remains; checkpoint-based resumption is required.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 003 | Dry run targeted docking workflow analysis with example data | 2026-04-28 | 4bf0d4b | [003-dry-run-targeted-docking-workflow-analys](./quick/003-dry-run-targeted-docking-workflow-analys/) |
| 004 | Fix targeted docking parameter documentation (reference_ligand and autobox_ligand) | 2026-04-28 | 68a9599 | [004-fix-targeted-docking-parameter-documenta](./quick/004-fix-targeted-docking-parameter-documenta/) |
| 005 | Documentation cleanup: 2bxo.pdb purpose, metadata-stage naming, and config drift fixes | 2026-04-28 | 8a5770c | [005-documentation-cleanup-2bxo-pdb-purpose-m](./quick/005-documentation-cleanup-2bxo-pdb-purpose-m/) |

---

## Session Continuity

Last session: 2026-05-03 16:55 UTC
Stopped at: Checkpoint - awaiting Slurm array job 95281 completion (production MD)
Resume file: `.continue-here.md`

### Next Action

**AWAITING:** Slurm array job 95281 (4 production MD trials) must complete before continuing.
Monitor job status: `squeue -j 95281` or `sacct -j 95281`
Resume after completion: `/gsd-execute-phase 7`

---

## Notes

- Phase 5 and 5.1 completed previously; Phase 6.1 is active for critical security/performance remediation.
- Agent support remains explicitly experimental across docs.

---

*State updated: 2026-05-03*
*Current phase: 07-first-controlled-execution*
*Last action: 07-03 production MD submitted (4 × 60ns trials, job 95281)*

### Roadmap Evolution

| Date | Change | Rationale |
|------|--------|-----------|
| 2026-04-28 | Phase 6 added: Automation Infrastructure | Implement hooks/plugins identified in quick-003 dry-run analysis (estimated 6,600-13,300 token savings/run) |
| 2026-04-28 | Phase 7 added: First Controlled Execution | Execute and validate full targeted docking workflow (Mode A) in isolated workspace using example data |
| 2026-04-29 | Phase 6.1 inserted after Phase 6: Critical Security, Performance, and Plugin Fixes | Address 4 critical security issues, 8 high-severity performance bottlenecks, and 2 plugin hardening fixes from scancode analysis (URGENT)
