# State: autoEnsmblDockMD

**Project:** autoEnsmblDockMD
**Core Value:** Human-run pipeline producing validated, reproducible scientific outputs with minimal commands. Agent autonomy is secondary/experimental.
**Created:** 2026-03-23

---

## Current Position

| Field | Value |
|-------|-------|
| **Current Phase** | 6 of 6 (5.1-critical-correctness-and-namespace-fixes) |
| **Current Plan** | 5 of 6 in current phase |
| **Last Activity** | 2026-04-19 - Completed 5.1-05-PLAN.md |
| **Progress** | █████████░░ 37/42 plans complete (88%) |
| **Phase 5.1 Blocker** | None |
| **Status** | In progress — 5.1-06 remaining |

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
| Use configured `water_model` in `gmx solvate` with `spc216` fallback | Maintain config-driven behavior with compatibility |
| Resolve MM/PBSA receptor/ligand IDs from actual `index.ndx` and propagate via `mmpbsa_groups.dat` | Prevent silent wrong-group MM/PBSA calculations when index ordering differs |
| Honor explicit non-default `[mmpbsa] receptor_group_id/ligand_group_id` overrides | Preserve escape hatch for manual system-specific recovery |
| Derive receptor GRO from docking SDF prefix and merge receptor+ligand coordinates in wrappers | Ensure wrappers generate `com.gro` before validation and maintain deterministic artifact contract |
| Treat any GRO↔ITP atom-count or atom-name/order mismatch as a hard error | Prevent silent misapplication of ligand position restraints |
| Map `com_ana` stage to `ligand` forwarding mode in `run_pipeline.sh` | Keep dispatcher/callee CLI contract consistent for per-ligand analysis targeting |
| Compute advanced RMSD with superposition before displacement measurement | Remove translational/rotational drift inflation from RMSD timeseries |
| Namespace all public skills and slash-command wrappers with `aedmd-*` | Prevent collisions with generic OpenCode command names and keep project command ownership explicit |

### Known Pitfalls

- Force-field incompatibility (AMBER protein + CGenFF ligand) can crash downstream stages.
- Missing hydrogens can break docking/MD/MM/PBSA.
- Context/session overflow risk remains; checkpoint-based resumption is required.

---

## Session Continuity

Last session: 2026-04-19 11:32 UTC
Stopped at: Completed 5.1-05-PLAN.md
Resume file: None

### Next Action

Execute `5.1-06-PLAN.md` (docs namespace and consistency updates).

---

## Notes

- Phase 5 completed previously; urgent Phase 5.1 is active for correctness and namespace remediation.
- Agent support remains explicitly experimental across docs.

---

*State updated: 2026-04-19*
*Current phase: 5.1-critical-correctness-and-namespace-fixes (in progress)*
*Last action: Completed 5.1-05-PLAN.md and created 5.1-05-SUMMARY.md*
