# State: autoEnsmblDockMD

**Project:** autoEnsmblDockMD
**Core Value:** Human-run pipeline producing validated, reproducible scientific outputs with minimal commands. Agent autonomy is secondary/experimental.
**Created:** 2026-03-23

---

## Current Position

| Field | Value |
|-------|-------|
| **Current Phase** | 06-automation-infrastructure |
| **Current Plan** | 06-02 complete (2/8 plans in Phase 6) |
| **Last Activity** | 2026-04-28 - Completed 06-02-PLAN.md (preflight validation) |
| **Progress** | ██████████░░ 42/51 plans complete (82%) |
| **Phase 5.1 Blocker** | None |
| **Status** | Phase 6 in progress |

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

Last session: 2026-04-28 14:14 UTC
Stopped at: Completed 06-02-PLAN.md
Resume file: None

### Next Action

Proceed with 06-03-PLAN.md (handoff inspector).

---

## Notes

- Phase 5 completed previously; urgent Phase 5.1 is active for correctness and namespace remediation.
- Agent support remains explicitly experimental across docs.

---

*State updated: 2026-04-28*
*Current phase: 06-automation-infrastructure*
*Last action: 06-02 preflight validation complete (2/8)*

### Roadmap Evolution

| Date | Change | Rationale |
|------|--------|-----------|
| 2026-04-28 | Phase 6 added: Automation Infrastructure | Implement hooks/plugins identified in quick-003 dry-run analysis (estimated 6,600-13,300 token savings/run) |
| 2026-04-28 | Phase 7 added: First Controlled Execution | Execute and validate full targeted docking workflow (Mode A) in isolated workspace using example data |
