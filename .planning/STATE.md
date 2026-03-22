# State: autoEnsmblDockMD

**Project:** autoEnsmblDockMD
**Core Value:** Human-run pipeline producing validated, reproducible scientific outputs with minimal commands. Agent autonomy is secondary/experimental.
**Created:** 2026-03-23

---

## Current Position

| Field | Value |
|-------|-------|
| **Current Phase** | 1 - Foundation |
| **Plan** | Roadmap created, awaiting phase planning |
| **Status** | Not Started |
| **Progress** | ░░░░░░░░░░░░░░░░░ 0/5 phases complete |
| **Phase 1 Blocker** | None ✓ |

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
| **Requirements Mapped** | 34/34 | 100% coverage |
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

Awaiting user approval of roadmap. After approval, proceed to `/gsd-plan-phase 1` to plan Foundation phase.

### Workflow Status

- [x] PROJECT.md created
- [x] Requirements defined
- [x] Research completed
- [x] Roadmap created
- [ ] Phase 1 planned
- [ ] Phase 1 executed
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

*State updated: 2026-03-23*
*Last phase: N/A (initialization)*