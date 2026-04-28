# State: autoEnsmblDockMD

**Project:** autoEnsmblDockMD
**Core Value:** Human-run pipeline producing validated, reproducible scientific outputs with minimal commands. Agent autonomy is secondary/experimental.
**Created:** 2026-03-23

---

## Current Position

| Field | Value |
|-------|-------|
| **Current Phase** | Quick tasks (post-phase baseline complete) |
| **Current Plan** | quick-003 (dry-run-targeted-docking-workflow-analys) complete |
| **Last Activity** | 2026-04-28 - Completed quick task 003 dry-run analysis |
| **Progress** | ███████████░ 43/46 plans complete (93%) |
| **Phase 5.1 Blocker** | None |
| **Status** | Core phases complete; quick task analysis completed |

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
| Prioritize preflight/workspace-init/handoff-inspector automation hooks first | Highest estimated token savings for repeated run-support workflows |

### Known Pitfalls

- Force-field incompatibility (AMBER protein + CGenFF ligand) can crash downstream stages.
- Missing hydrogens can break docking/MD/MM/PBSA.
- Context/session overflow risk remains; checkpoint-based resumption is required.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 003 | Dry run targeted docking workflow analysis with example data | 2026-04-28 | 4bf0d4b | [003-dry-run-targeted-docking-workflow-analys](./quick/003-dry-run-targeted-docking-workflow-analys/) |

---

## Session Continuity

Last session: 2026-04-28 11:31 UTC
Stopped at: Completed quick-003-01 dry-run targeted docking workflow analysis
Resume file: None

### Next Action

Address quick-003 documentation remediation items (targeted docking parameter clarity + metadata-stage alignment), then proceed with controlled targeted workflow execution in isolated workspace.

---

## Notes

- Phase 5 completed previously; urgent Phase 5.1 is active for correctness and namespace remediation.
- Agent support remains explicitly experimental across docs.

---

*State updated: 2026-04-28*
*Current phase: quick tasks (post-phase maintenance)*
*Last action: quick-003 dry-run analysis complete (4/4 tasks)*

### Roadmap Evolution

| Date | Change | Rationale |
|------|--------|-----------|
| 2026-04-28 | Phase 6 added: Automation Infrastructure | Implement hooks/plugins identified in quick-003 dry-run analysis (estimated 6,600-13,300 token savings/run) |
| 2026-04-28 | Phase 7 added: First Controlled Execution | Execute and validate full targeted docking workflow (Mode A) in isolated workspace using example data |

