# State: autoEnsmblDockMD

**Project:** autoEnsmblDockMD
**Core Value:** Human-run pipeline producing validated, reproducible scientific outputs with minimal commands. Agent autonomy is secondary/experimental.
**Created:** 2026-03-23

---

## Current Position

| Field | Value |
|-------|-------|
| **Current Phase** | 1 - Foundation |
| **Plan** | 1 of ? in current phase |
| **Status** | In progress |
| **Progress** | ░░░░░░░░░░░░░░░░░ 0/5 phases complete |
| **Phase 1 Blocker** | None ✓ |
| **Last Activity** | 2026-03-24 - Completed 01-01-PLAN.md |

---

## Phase Blockers

| Phase | Blocker | Required Action |
|-------|---------|-----------------|
| 1 | None | Ready to proceed |
| 2 | WORKFLOW.md, Scripts, Reference Output | Finalize workflow, provide manual trial artifacts |
| 3 | WORKFLOW.md, Phase 2 complete | Wait for Phase 2 |
| 4 | Phase 3 complete | Wait for Phase 3 |
| 5 | WORKFLOW.md, End-to-end test | Finalize workflow, run full pipeline |

---

## Performance Metrics

| Metric | Value | Notes |
|--------|-------|-------|
| **Requirements Mapped** | 37/37 | 100% coverage |
| **Phases Defined** | 5 | Comprehensive depth |
| **Deferred to v2** | 1 | SCRIPT-02 (ligand prep) |
| **Research Flags** | 3 | Phase 2 (docking, MMPBSA), Phase 3 (Slurm) |

---

## Accumulated Context

### Key Decisions

| Decision | Rationale | Phase Affected |
|----------|-----------|----------------|
| OpenCode-first, attempt agent-agnostic | OpenCode available and capable; general naming allows future compatibility | All |
| Human automation over agent autonomy | Agent behavior has uncertainties; validated human workflow is priority | 3, 4 |
| Defer codebase mapping | Workflow/scripts being finalized; map after stabilization | 2 |
| Ligand prep deferred to v2 | Complex chemistry, error-prone; user provides prepared ligands | 2 |
| Agent-stage mapping in WORKFLOW.md | Explicit agent responsibility mapping enables orchestrator coordination | All |
| Requirement-per-stage traceability | Links workflow stages to REQUIREMENTS.md IDs for requirement-driven development | All |
| Script categorization | Groups scripts by purpose for agent navigation and selection | 2 |
| Infrastructure vs workflow scripts split | Phase 1 delivers workflow-agnostic utilities; Phase 2 delivers workflow scripts, wrappers, gap-filling after workflow finalized | 1, 2 |
| configparser over YAML | Use Python's built-in configparser for INI parsing to avoid external dependencies | 1 |
| JSON over pickle | Chose JSON for state persistence for human readability and debugging | 1 |
| Atomic writes for state files | Temp file + rename prevents corruption during writes | 1 |
| Dot notation for nested keys | Cleaner API for accessing nested state values (e.g., 'stage.status') | 1 |

### Research Flags (Areas Needing Deeper Research)

1. **Phase 2 - Docking:** gnina CNN scoring configuration, multi-ligand parallel execution validation
2. **Phase 2 - MMPBSA:** trajectory processing requirements, topology generation edge cases
3. **Phase 3 - Agent Infrastructure:** Slurm job array compatibility verification

### Known Pitfalls (from research)

- **Force field incompatibility:** AMBER protein + CGenFF ligand causes crashes; validate FF consistency
- **Missing hydrogen atoms:** Leads to failed docking/MD/MMPBSA; require explicit hydrogen addition
- **Context window overflow:** Implement checkpoint-based session management
- **Simulation stability:** Verify RMSD <3Å before proceeding to MMPBSA
- **MMPBSA topology mismatch:** AMBER topology must match GROMACS structure

---

## Session Continuity

### Next Action

Phase 1 plan 01-01 complete. Continue with next plan in Phase 1 (01-02-PLAN.md if exists) or proceed to next phase planning if all Phase 1 plans complete.

### Quick Tasks Completed

| Task | Description | Date | Summary |
|------|-------------|------|---------|
| quick-001 | Update WORKFLOW.md template | 2026-03-23 | Added agent integration, requirement traceability, script categorization |
| 01-01 | Create config and state management | 2026-03-24 | ConfigManager for INI parsing, AgentState for JSON persistence |

### Workflow Status

- [x] PROJECT.md created
- [x] Requirements defined
- [x] Research completed
- [x] Roadmap created
- [x] Phase 1 planned
- [ ] Phase 1 executed (01-01 complete)
- [ ] Phase 2 planned
- [ ] Phase 2 executed
- [ ] Phase 3 planned
- [ ] Phase 3 executed
- [ ] Phase 4 planned
- [ ] Phase 4 executed
- [ ] Phase 5 planned
- [ ] Phase 5 executed

### Checkpoints

| Checkpoint | Trigger | Status |
|------------|---------|--------|
| Stage Complete | Each phase completes | Not Started |
| Human Verification | Between stages | Not Started |
| Agent Context Dump | Session continuity | Not Started |

---

## Notes

- WORKFLOW.md is marked "TO BE FINALIZED" — do not plan related stages until user removes banner
- Agent support marked experimental throughout
- SCRIPT-02 explicitly deferred to v2

---

*State updated: 2026-03-24*
*Last phase: 01-foundation*
*Last plan: 01-01 (config and state management)*
*Last quick task: quick-001 (2026-03-23)*