# State: autoEnsmblDockMD

**Project:** autoEnsmblDockMD
**Core Value:** Human-run pipeline producing validated, reproducible scientific outputs with minimal commands. Agent autonomy is secondary/experimental.
**Created:** 2026-03-23

---

## Current Position

| Field | Value |
|-------|-------|
| **Current Phase** | All phases complete |
| **Current Plan** | All 34 plans complete (Phase 5 remediation included) |
| **Last Activity** | 2026-04-19 - Completed Phase 5-Polish |
| **Progress** | ████████████████ 34/34 plans complete (100%) |
| **Phase 5 Blocker** | None - verification passed |
| **Status** | Milestone ready for audit |

---

## Phase Blockers

| Phase | Blocker | Required Action |
|-------|---------|-----------------|
| 1 | Complete | ✓ Delivered |
| 2 | Complete | ✓ Delivered |
| 3 | Complete | ✓ Delivered |
| 4 | Complete | ✓ Delivered |
| 5 | Complete | ✓ Delivered |

---

## Accumulated Context

### Key Decisions (Phase 4)

| Decision | Rationale | Phase Affected |
|----------|-----------|----------------|
| Commands target abstract agent stages (10 primary commands) | Balance agent context overhead with meaningful workflow units | 4 |
| Mode & variants controlled via config; auto-detected | Workspace is immutable; config is truth for workflow shape | 4 |
| Three-tier parameters: config + CLI flags + interactive | Consistency with Phase 2; flexible for humans and agents | 4 |
| Commands dispatch through runner agent | Reuses Phase 3 infrastructure; single dispatch logic | 4 |
| Skill format & error/feedback deferred to planning | Need ecosystem research before deciding YAML vs Markdown | 4 |
| Use shared `scripts/commands/common.sh` for bridge utilities | Keeps all slash command wrappers consistent and minimal | 4 |
| `/status` inspects workspace artifacts directly (no agent dispatch) | Status is read-only introspection and should be lightweight | 4 |
| Pipeline skill metadata uses canonical WorkflowStage values | Preserves terminology alignment with agent schemas/handoffs | 4 |
| Skill parameter docs map to `scripts/config.ini.template` keys | Keeps runtime guidance consistent with config-driven scripts | 4 |
| Integration validation remains wiring-focused (no heavy stage runs) | Confirms command→agent→skill chain correctness without unnecessary compute | 4 |
| Agent support is explicitly documented as experimental | Aligns AGENT-07 while preserving script-first stable usage guidance | 4 |

### Key Decisions (Phase 5)

| Decision | Rationale | Phase Affected |
|----------|-----------|----------------|
| Restructure AGENTS.md by agent role instead of requirement category | Improves agent discoverability and keeps AGENTS.md readable at load time | 5 |
| Keep AGENTS.md overview-only with links to skill/WORKFLOW/PROJECT docs | Avoids duplication and keeps implementation specifics in authoritative files | 5 |
| Enforce one SKILL.md metadata template across all 10 skills | Ensures deterministic parsing and consistent runtime documentation shape | 5 |
| Align skill parameter tables to `scripts/config.ini.template` keys | Keeps skill guidance synchronized with config-driven execution | 5 |
| Use implemented script inventory as WORKFLOW.md source of truth | Removes legacy command drift and keeps workflow docs aligned with runnable scripts | 5 |
| Put Mode A/Mode B differences inside each stage section | Keeps mode-specific operator guidance next to execution steps | 5 |
| Use README as fast onboarding and route deep details to WORKFLOW/GUIDE | Keeps first-run path concise while preserving complete reference docs | 5 |
| Document GUIDE config reference directly from `scripts/config.ini.template` | Prevents key drift between runtime config and human guide | 5 |
| Treat `[production]` as the explicit MD section in GUIDE | Preserves template accuracy while satisfying MD documentation intent | 5 |
| Keep script-level details in WORKFLOW.md and use GUIDE.md for operator checks/interpretation | Avoids duplication and keeps human-facing troubleshooting easy to scan | 5 |
| Restore all 10 SKILL.md files from origin/main as canonical baseline | Guarantees exact recovery of YAML frontmatter and required sections after 05-03 regression | 5 |
| Delete 05-03-SUMMARY.md after remediation | Prevents stale summary from representing reverted/invalidated changes | 5 |
| Add explicit Skill File Contract section in AGENTS.md | Locks canonical path/frontmatter schema in agent-facing documentation | 5 |
| Add YAML-frontmatter skill references in README/GUIDE with minimal edits | Aligns surviving docs to restored SKILL.md format without broad rewrites | 5 |
| Remediate missing required `Parameters` sections during structural validation | Ensures all skills satisfy enforced contract (including CLI Flag/Default columns) | 5 |
| Add `scripts/com/mmpbsa.in` as canonical default input template | Resolves config/doc runtime reference to existing in-repo artifact | 5 |

### Research Flags (Areas for Planning)

1. **Phase 4 - Skills:** YAML vs Markdown vs Hybrid; how gsd-agents structure skills
2. **Phase 4 - Error/Feedback:** OpenCode convention for agent error reporting; checker/debugger patterns
3. **Phase 4 - CLI Schema:** Exact OpenCode slash command registration pattern

### Known Pitfalls (from Phase 3)

- Force field incompatibility: AMBER protein + CGenFF ligand causes crashes
- Missing hydrogen atoms: Leads to failed docking/MD/MMPBSA
- Context window overflow: Implement checkpoint-based session management
- Simulation stability: Verify RMSD <3Å before proceeding to MMPBSA
- MMPBSA topology mismatch: AMBER topology must match GROMACS structure

---

## Session Continuity

Last session: 2026-04-19 15:43 +0800
Stopped at: Completed 05-10-PLAN.md
Resume file: None

### Next Action

**Phase 5 is in progress.**

**Recommend:** Collect end-to-end test artifacts to close remaining Phase 5 blocker.

### Recent Milestones

- 2026-03-25: Phase 1 completed (01-01 through 01-06)
- 2026-04-19: Phase 2 completed (02-01 through 02-11)
- 2026-04-19: Phase 3 completed (03-01 through 03-04)
- 2026-04-19: Phase 4 context discussion completed (04-CONTEXT.md)
- 2026-04-19: Phase 4 plan 01 executed (command bridge scripts)
- 2026-04-19: Phase 4 plan 02 executed (Agent Skills files)
- 2026-04-19: Phase 4 plan 03 executed (integration smoke test + experimental docs)
- 2026-04-19: Phase 5 plan 01 executed (WORKFLOW.md definitive reference rewrite)
- 2026-04-19: Phase 5 plan 02 executed (AGENTS.md role-based restructure)
- 2026-04-19: Phase 5 plan 03 executed (SKILL.md metadata standardization)
- 2026-04-19: Phase 5 plan 04 executed (README.md comprehensive onboarding rewrite)
- 2026-04-19: Phase 5 plan 05 executed (GUIDE.md Part 1 config/input/workspace reference)
- 2026-04-19: Phase 5 plan 06 executed (GUIDE.md Part 2 stage instructions + troubleshooting)
- 2026-04-19: Phase 5 plan 08 executed (SKILL.md restoration + invalidated summary cleanup)
- 2026-04-19: Phase 5 plan 09 executed (cross-doc compatibility alignment with restored skill format)
- 2026-04-19: Phase 5 plan 10 executed (end-to-end structural validation + report)

### Planning Status

- [x] PROJECT.md, ROADMAP.md created
- [x] Phase 1 planned and executed
- [x] Phase 2 planned and executed
- [x] Phase 3 planned and executed
- [x] Phase 4 context discussed
- [x] Phase 4 planned
- [x] Phase 4 executed
- [x] Phase 5 planned
- [ ] Phase 5 executed

### Checkpoints

| Checkpoint | Trigger | Status |
|------------|---------|--------|
| Stage Complete | Each phase completes | Phase 1-4 Complete ✓ |
| Human Verification | Between stages | Active |
| Agent Context Dump | Session continuity | Active |

---

## Notes

- Agent support marked experimental throughout (Phase 4 requirement)
- SCRIPT-02 explicitly deferred to v2
- Phase 4 context captures locked decisions; planning phase will detail "how"

---

*State updated: 2026-04-19*
*Current phase: 05-polish (in progress)*
*Last action: Completed 05-10-PLAN.md and created 05-10-SUMMARY.md*
