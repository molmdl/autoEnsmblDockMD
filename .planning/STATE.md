# State: autoEnsmblDockMD

**Project:** autoEnsmblDockMD
**Core Value:** Human-run pipeline producing validated, reproducible scientific outputs with minimal commands. Agent autonomy is secondary/experimental.
**Created:** 2026-03-23

---

## Current Position

| Field | Value |
|-------|-------|
| **Current Phase** | 3 - Agent Infrastructure |
| **Plan** | 4 of 4 in current phase |
| **Status** | Complete ✓ |
| **Progress** | ████████████░░░░ 3/5 phases complete |
| **Phase 3 Blocker** | None ✓ |
| **Last Activity** | 2026-04-19 - Phase 3 verified and complete |

---

## Phase Blockers

| Phase | Blocker | Required Action |
|-------|---------|-----------------|
| 1 | Complete | ✓ Delivered |
| 2 | Complete | ✓ Delivered |
| 3 | Complete | ✓ Delivered |
| 4 | None | Ready to start |
| 5 | WORKFLOW.md, End-to-end test | Finalize workflow, run full pipeline |

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
| CheckpointManager for workflow persistence | Enables users to save/resume workflow state at any stage | 1 |
| subprocess-based execution | Use subprocess.run for local command execution with built-in timeout support | 1 |
| LogMonitor for job status tracking | Parse log files for errors, warnings, completion markers to determine job status | 1, 3 |
| VerificationGate for human checkpoints | Enables workflow pause at critical points for human review/approval | All |
| Separate lock file for synchronization | Use .gate_write.lock instead of locking data file directly | 1 |
| Atomic read-modify-write pattern | Prevents race conditions in concurrent state modifications | 1 |
| Public API exports via __init__.py | Clean import interface for infrastructure modules | All |
| Integration test suite | Validates cross-module functionality end-to-end | All |
| Pure-bash INI loader for workflow scripts | Gives shell scripts config access compatible with Python INI model while avoiding external dependencies | 2 |
| Auto-source config loader from common.sh | Ensures downstream scripts can load one shared library and get config + utility helpers consistently | 2 |
| Unified gnina mode handling in one script | Reduces drift across mode-specific scripts and keeps docking behavior config-driven | 2 |
| Per-ligand Slurm submission with ensemble inner loop | Preserves parallel throughput while keeping per-ligand outputs grouped and reproducible | 2 |
| Receptor stage scripts use common.sh wrappers and config-first control | Keeps prep/production/analysis/clustering behavior consistent across force fields | 2 |
| MDAnalysis alignment utility retained as importable CLI tool | Supports both scripted pipeline execution and library reuse for alignment tasks | 2 |
| Preserve AMBER converter core logic while generalizing interfaces | Existing GRO+ITP→MOL2 parser and mapping code encodes critical edge-case handling, so interface-focused changes reduce regression risk | 2 |
| Wrapper import path for numeric converter script | Keeps numeric workflow naming while providing stable library import `scripts.dock.gro_itp_to_mol2:convert` | 2 |
| Unified complex prep entrypoint for AMBER and CHARMM | One script with mode switch reduces force-field-specific drift and preserves config-driven control | 2 |
| Preserve angle bypass conversion logic while expanding interfaces | Existing topology conversion behavior is validated; only CLI/config/validation layers were generalized | 2 |
| Post-docking report script uses bash entrypoint + embedded Python parser | Keeps stage-level shell interface consistency while handling structured SDF parsing robustly | 2 |
| Wrapper module for numeric dotted script import interoperability | Preserves planned numeric filenames while enabling reliable Python module imports | 2 |
| Unified complex trajectory analysis orchestrator | One `3_ana.sh` entrypoint runs both GROMACS baseline and MDAnalysis advanced metrics with config toggles | 2 |
| Dynamic loading for numeric selection module | Uses importlib loading of `3_selection_defaults.py` to preserve numeric naming and reusable library behavior | 2 |
| Unified production MD job chaining | Submit equilibration and production as separate Slurm jobs linked via afterok dependencies for reliable stage ordering | 2 |
| MM/PBSA as per-ligand Slurm arrays | Parallelize chunk calculations with one array task per chunk for scalable throughput | 2 |
| Dynamic index group ID resolution for MM/PBSA | Avoids hardcoded make_ndx group numbers by deriving complex group IDs from generated index files | 2 |
| MDAnalysis-based contact fingerprints for post-analysis | Reuses existing trajectory stack and avoids new hard dependencies while providing matrix + heatmap outputs | 2 |
| Stable wrapper stage interface with --list-stages | Machine-readable stage discovery enables scriptable orchestration and future agent automation | 2, 3, 4 |
| Config template as authoritative parameter reference | Centralized INI documentation reduces misconfiguration across receptor/docking/complex stages | 2, 3 |
| Dataclass handoff schema for agent communication | Enforces consistent JSON handoff shape with explicit status enum serialization | 3 |
| BaseAgent reuses Phase 1 persistence primitives | Avoids reimplementation by wiring AgentState and CheckpointManager directly in shared agent base | 3 |
| Orchestrator gate check before transition routing | Prevents stage advancement when previous stage verification is pending/rejected | 3 |
| Runner emits subprocess-backed structured handoff payloads | Standardizes stage execution outcomes with captured outputs, metrics, and warnings | 3 |
| Analyzer stage analysis registry | Uses explicit STAGE_ANALYSIS_MAP with optional custom hook discovery for deterministic/extensible analysis execution | 3 |
| Checker default validation baseline with registry override | Applies common checks for outputs/return code/log/file sizes while permitting stage-specific check extension | 3 |
| Debugger persists handoff-shaped diagnostics under .debug_reports | Produces reproducible, version-aware JSON debug artifacts consumable by downstream orchestration | 3 |
| scripts.agents registry as single role authority | Keeps CLI and runtime instantiation aligned through one AGENT_REGISTRY/get_agent path | 3, 4 |
| JSON handoff CLI entrypoint for agents | `python -m scripts.agents` provides config-backed invocation with deterministic JSON I/O for orchestration layers | 3, 4 |

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

Last session: 2026-04-19 01:41 +0800
Stopped at: Completed 03-04-PLAN.md
Resume file: None

### Next Action

**Phase 3 COMPLETE.** All 4 plans executed and verified (7/7 must-haves passed).

**Phase 4 blockers:**
- Phase 3 complete ✓

**Recommend:** User should start Phase 4 (Integration) to connect agents to scripts via slash commands and skills.

### Recent Milestones

- 2026-03-25: Phase 1 completed (01-01 through 01-06)
- 2026-04-19: Phase 2 completed (02-01 through 02-11)
- 2026-04-19: Phase 3 execution started with 03-01 completed
- 2026-04-19: 03-02 completed (orchestrator and runner agents)
- 2026-04-19: 03-03 completed (analyzer, checker, and debugger agents)
- 2026-04-19: 03-04 completed (agent registry, CLI entrypoint, smoke validation) and Phase 3 closed

### Planning Status

- [x] PROJECT.md, ROADMAP.md, and research baselines created
- [x] Phase 1 planned and executed
- [x] Phase 2 planned and executed
- [x] Phase 3 planned
- [x] Phase 3 executed
- [ ] Phase 4 planned/executed
- [ ] Phase 5 planned/executed

### Checkpoints

| Checkpoint | Trigger | Status |
|------------|---------|--------|
| Stage Complete | Each phase completes | Phase 1 Complete ✓, Phase 2 Complete ✓, Phase 3 Complete ✓ |
| Human Verification | Between stages | Active |
| Agent Context Dump | Session continuity | Active |

---

## Notes
- Agent support marked experimental throughout
- SCRIPT-02 explicitly deferred to v2

---

*State updated: 2026-04-19*
*Last phase: 03-agent-infrastructure (COMPLETE)*
*Last plan: 03-04 (agent registry, CLI entrypoint, integration smoke test)*
*Last quick task: quick-002 (2026-04-18)*
