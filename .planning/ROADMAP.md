# Roadmap: autoEnsmblDockMD

**Created:** 2026-03-23
**Depth:** Comprehensive
**Core Value:** Human-run pipeline producing validated, reproducible scientific outputs with minimal commands. Agent autonomy is secondary/experimental.

---

## Overview

This roadmap transforms the autoEnsmblDockMD requirements into a phased delivery plan. The project is a toolkit for automated ensemble docking and molecular dynamics simulations using GROMACS and gnina, providing scripts, slash commands, and agent skills for both humans and coding agents.

The roadmap derives phases from the natural groupings of requirements, following a foundation → core features → agent infrastructure → integration → polish structure. Every v1 requirement maps to exactly one phase.

---

## Phase Structure

| Phase | Goal | Requirements | Success Criteria |
|-------|------|--------------|------------------|
| **1 - Foundation** | Provide configuration system, execution environment, and checkpoint infrastructure | EXEC-01 to EXEC-04, CHECK-01 to CHECK-03, AGENT-06, SCRIPT-11 | 5 criteria |
| **2 - Core Pipeline** | Deliver generalized scripts for all workflow stages (receptor prep, docking, MD, MMPBSA, analysis), wrapper scripts, and gap-filling scripts | SCRIPT-01, SCRIPT-03 to SCRIPT-10, SCRIPT-12, SCRIPT-13, EXEC-05 | 5 criteria |
| **3 - Agent Infrastructure** | Implement five agent types with distinct responsibilities and file-based state passing | AGENT-01 to AGENT-06 | 4 criteria |
| **4 - Integration** | Connect agents to scripts via slash commands and loadable skills | CMD-01 to CMD-03, SKILL-01 to SKILL-03, AGENT-07 | 4 criteria |
| **5 - Polish** | Finalize documentation, mark agents as experimental, validate end-to-end workflow | DOC-01 to DOC-04 | 4 criteria |

**Total Phases:** 5
**Coverage:** 37/37 requirements mapped ✓

---

## Phase Details

### Phase 1: Foundation

**Goal:** Establish configuration system, execution environment, and checkpoint infrastructure that enables all downstream work.

**Requirements:**
- EXEC-01: Local execution support for all tasks
- EXEC-02: HPC Slurm support for demanding tasks
- EXEC-03: Job monitoring via log parsing
- EXEC-04: Error detection and reporting
- CHECK-01: Stage checkpoints save intermediate states
- CHECK-02: Human verification gates between stages
- CHECK-03: Agent context dump to file for session continuity
- AGENT-06: All agents use file-based state passing to avoid context overflow
- SCRIPT-11: Infrastructure/utility scripts (config processing, checkpoint utilities, verification gates)

**Note:** EXEC-05 (parallel Slurm submission) moved to Phase 2 as it depends on workflow stages being defined.

**Deliverables:**
- Reusable infrastructure components (not workflow-specific)
- Config parsing utilities
- Checkpoint save/load utilities (format-agnostic)
- Execution backend detection + job submission utilities
- Job monitoring utilities (log parsing, status detection)
- Verification gate mechanism (pause/resume/approve/reject)

**Dependencies:** None — Phase 1 is the foundation for all subsequent phases.

**Blockers:** None — can proceed immediately.

**Plans:** 6 plans in 4 waves

Plans:
- [x] 01-01-PLAN.md — Core configuration and state management (Wave 1)
- [x] 01-02-PLAN.md — Checkpoint save/load system (Wave 2)
- [x] 01-03-PLAN.md — Execution backend detection and job submission (Wave 2)
- [x] 01-04-PLAN.md — Job monitoring via log parsing (Wave 3)
- [x] 01-05-PLAN.md — Human verification gates (Wave 3)
- [x] 01-06-PLAN.md — Integration testing (Wave 4)

**Success Criteria:**

1. **Local Execution Works**
   - User can run any script locally without modification to paths
   - All scripts detect execution environment and adapt accordingly

2. **HPC Submission Works**
   - User can submit GROMACS mdrun, MMPBSA, and heavy analysis jobs to Slurm
   - Scripts automatically select appropriate execution backend based on detected environment

3. **Job Monitoring Provides Status**
   - User can check job status via log parsing
   - Scripts report clear completion/failure states

4. **Checkpoint System Enables Resume**
   - User can stop workflow at any stage and resume from saved checkpoint
   - Checkpoint files contain all state needed to continue

5. **Human Verification Gates Pause Workflow**
   - Workflow pauses at designated checkpoints for human review
   - User can approve/reject before proceeding to next stage

---

### Phase 2: Core Pipeline

**Goal:** Deliver generalized, production-ready scripts for all computational workflow stages with consistent I/O and CLI interfaces.

**Requirements:**
- SCRIPT-01: Receptor preparation scripts (pdb2pqr, gmx pdb2gmx, ensemble MD, clustering, alignment)
- SCRIPT-03: Docking scripts (gnina execution, pose extraction, ensemble docking, autobox)
- SCRIPT-04: MD setup scripts (complex building, solvation, ions, minimization, equilibration)
- SCRIPT-05: MD production scripts (production run, trajectory handling)
- SCRIPT-06: MMPBSA scripts (trajectory processing, binding energy, decomposition, plots, averaging)
- SCRIPT-07: Standard analysis scripts (RMSD, RMSF, contacts, etc.)
- SCRIPT-08: All scripts support CLI flags for options
- SCRIPT-09: All scripts use human-friendly config format
- SCRIPT-10: Scripts consistent in I/O format, error handling, and coding style
- SCRIPT-12: Wrapper scripts for pipeline orchestration
- SCRIPT-13: Gap-filling scripts to bridge workflow stages
- EXEC-05: Independent jobs submit to Slurm in parallel

**Note:** SCRIPT-02 (Ligand preparation) is explicitly deferred to v2 per project requirements — user provides prepared ligands.

**Deliverables:**
- All computational workflow scripts (receptor prep through analysis)
- Wrapper script(s) that orchestrate the pipeline (read config, call stage scripts)
- Gap-filling scripts identified after workflow finalization
- Integration of Phase 1 infrastructure into workflow stages

**Dependencies:** Phase 1 must complete (foundation required for script execution environment)

**Blockers:** None — all resolved (WORKFLOW.md, expected scripts, reference output available)

**Plans:** 11 plans in 5 waves

Plans:
- [ ] 02-01-PLAN.md — Bash config loader and common utilities (Wave 1)
- [ ] 02-02-PLAN.md — Receptor ensemble generation scripts (Wave 2)
- [ ] 02-03-PLAN.md — Docking ligand conversion scripts (Wave 2)
- [ ] 02-04-PLAN.md — Docking execution scripts (Wave 2)
- [ ] 02-05-PLAN.md — Post-docking scoring and dock2com Python core (Wave 3)
- [ ] 02-06-PLAN.md — Dock-to-complex shell wrappers (Wave 3)
- [ ] 02-07-PLAN.md — Complex MD preparation scripts (Wave 3)
- [ ] 02-08-PLAN.md — Production MD and MM/PBSA scripts (Wave 4)
- [ ] 02-09-PLAN.md — Complex MD trajectory analysis scripts (Wave 4)
- [ ] 02-10-PLAN.md — Supporting utilities: fingerprints, archive, rerun (Wave 5)
- [ ] 02-11-PLAN.md — Pipeline wrapper, config template, validation (Wave 5)

**Success Criteria:**

1. **Receptor Preparation Scripts Work**
   - User can run receptor prep with single command: `./scripts/prep_receptor.sh -c config.conf`
   - Scripts produce clean PDB files with hydrogens, protonation states, and identified binding pockets

2. **Docking Scripts Execute gnina**
   - User can run ensemble docking with multiple receptor conformations
   - Pose extraction produces ranked PDB files with scores

3. **MD Scripts Build and Run Simulations**
   - User can build complete complex, solvate, add ions, minimize, equilibrate, and run production
   - Trajectory output in standard GROMACS formats (XTC/TRR)

4. **MMPBSA Scripts Calculate Binding Energies**
   - User can process trajectories and compute binding free energies
   - Results include decomposition and plots

5. **All Scripts Have Consistent Interface**
   - Every script responds to `-h` for help
   - Config files use same format across all stages
   - Error messages are uniform and actionable

---

### Phase 3: Agent Infrastructure

**Goal:** Implement five agent types (orchestrator, runner, analyzer, checker, debugger) with distinct responsibilities and file-based communication.

**Requirements:**
- AGENT-01: Orchestrator agent — manages workflow state, spawns agents, handles checkpoints
- AGENT-02: Runner agent — executes stage scripts, handles parameters
- AGENT-03: Analyzer agent — runs standard analysis, supports custom analysis
- AGENT-04: Checker agent — validates results, generates warnings/suggestions
- AGENT-05: Debugger agent — follows gsd-debugger workflow, version-aware
- AGENT-06: File-based state passing (already in Phase 1)

**Dependencies:** Phase 2 must complete (agents orchestrate scripts that must exist first)

**Blockers:**
- ⚠️ **WORKFLOW.md finalized** — Need workflow stages for agent state machine logic
- ⚠️ **Phase 2 complete** — Requires working scripts to orchestrate

**Success Criteria:**

1. **Orchestrator Manages Workflow State**
   - Orchestrator tracks current stage, maintains state machine, spawns appropriate agents
   - State persisted to JSON files for session continuity

2. **Runner Executes Stage Scripts**
   - Runner loads stage configuration, executes scripts with correct parameters
   - Captures output and returns structured results

3. **Analyzer Processes Results**
   - Analyzer runs built-in metrics (RMSD, RMSF, contacts)
   - User can inject custom analysis scripts following project conventions

4. **Checker and Debugger Validate and Diagnose**
   - Checker validates results against thresholds, generates warnings
   - Debugger follows gsd-debugger workflow, aware of GROMACS/gnina/gmx_MMPBSA versions

---

### Phase 4: Integration

**Goal:** Connect agents to scripts via slash commands and loadable agent skills. Mark agent support as experimental.

**Requirements:**
- CMD-01: Slash commands for each major workflow stage
- CMD-02: Commands map to shell scripts executed by runner agent
- CMD-03: Commands follow `/stage-action` naming convention
- SKILL-01: Skill files loadable by agents at runtime
- SKILL-02: Skills minimal but sufficient (capability metadata, usage, parameters, examples)
- SKILL-03: Skills follow consistent format (YAML or Markdown)
- AGENT-07: Agent support marked as experimental in documentation

**Dependencies:** Phase 3 must complete (agents must exist to receive commands/skills)

**Blockers:**
- ⚠️ **Phase 3 complete** — Requires working agents to receive commands

**Success Criteria:**

1. **Slash Commands Trigger Stages**
   - User can invoke `/dock-run`, `/md-setup`, `/mmpbsa-calculate` to execute stages
   - Commands follow hierarchical naming convention

2. **Skills Load at Runtime**
   - Agents can load skill files defining their capabilities
   - Skills include metadata, usage instructions, parameters, and examples

3. **Commands Map to Runner Execution**
   - Each slash command triggers runner agent to execute appropriate shell script
   - Output streamed to user with progress updates

4. **Experimental Status Documented**
   - All agent-related documentation clearly marks support as experimental
   - Limitations and known issues documented

---

### Phase 5: Polish

**Goal:** Finalize all documentation, perform end-to-end validation, and prepare for initial release.

**Requirements:**
- DOC-01: README.md — clear usage instructions for humans (must-have, not feature)
- DOC-02: Agent-optimized documentation — detailed, structured for agent loading
- DOC-03: WORKFLOW.md — workflow steps and script usage
- DOC-04: AGENTS.md — agent guidelines (exists, update as needed)

**Dependencies:** Phase 4 must complete (documentation reflects integrated system)

**Blockers:**
- ⚠️ **WORKFLOW.md finalized** — Need workflow steps to document
- ⚠️ **End-to-end test artifacts** — Need full pipeline run output for validation

**Success Criteria:**

1. **README Provides Clear Human Usage**
   - New user can understand entire workflow from README
   - Installation, configuration, and execution steps documented
   - Examples provided for common use cases

2. **Agent Documentation Structured for Loading**
   - Agents can parse documentation to understand capabilities
   - Structured format enables runtime skill loading

3. **WORKFLOW.md Documents Steps**
   - Step-by-step workflow documented with script execution order
   - Expected inputs/outputs for each stage

4. **End-to-End Test Passes**
   - Full pipeline executes from receptor prep through MMPBSA
   - Results match expected outputs from manual workflow

---

## Coverage Map

| Requirement | Phase | Status |
|-------------|-------|--------|
| SCRIPT-01 | Phase 2 | Pending |
| SCRIPT-02 | N/A (deferred to v2) | Deferred |
| SCRIPT-03 | Phase 2 | Pending |
| SCRIPT-04 | Phase 2 | Pending |
| SCRIPT-05 | Phase 2 | Pending |
| SCRIPT-06 | Phase 2 | Pending |
| SCRIPT-07 | Phase 2 | Pending |
| SCRIPT-08 | Phase 2 | Pending |
| SCRIPT-09 | Phase 2 | Pending |
| SCRIPT-10 | Phase 2 | Pending |
| SCRIPT-11 | Phase 1 | Pending |
| SCRIPT-12 | Phase 2 | Pending |
| SCRIPT-13 | Phase 2 | Pending |
| AGENT-01 | Phase 3 | Pending |
| AGENT-02 | Phase 3 | Pending |
| AGENT-03 | Phase 3 | Pending |
| AGENT-04 | Phase 3 | Pending |
| AGENT-05 | Phase 3 | Pending |
| AGENT-06 | Phase 1 | Pending |
| AGENT-07 | Phase 4 | Pending |
| CMD-01 | Phase 4 | Pending |
| CMD-02 | Phase 4 | Pending |
| CMD-03 | Phase 4 | Pending |
| SKILL-01 | Phase 4 | Pending |
| SKILL-02 | Phase 4 | Pending |
| SKILL-03 | Phase 4 | Pending |
| EXEC-01 | Phase 1 | Pending |
| EXEC-02 | Phase 1 | Pending |
| EXEC-03 | Phase 1 | Pending |
| EXEC-04 | Phase 1 | Pending |
| EXEC-05 | Phase 2 | Pending |
| CHECK-01 | Phase 1 | Pending |
| CHECK-02 | Phase 1 | Pending |
| CHECK-03 | Phase 1 | Pending |
| DOC-01 | Phase 5 | Pending |
| DOC-02 | Phase 4 | Pending |
| DOC-03 | Phase 5 | Pending |
| DOC-04 | Phase 5 | Pending |

---

## Progress Table

| Phase | Name | Status | Requirements | Blockers |
|-------|------|--------|--------------|----------|
| 1 | Foundation | Complete ✓ | 10 | None |
| 2 | Core Pipeline | Planning Complete | 12 | None (resolved) |
| 3 | Agent Infrastructure | Not Started | 6 | WORKFLOW.md, Phase 2 |
| 4 | Integration | Not Started | 7 | Phase 3 |
| 5 | Polish | Not Started | 4 | WORKFLOW.md, End-to-end Test |

---

## Notes

- **Depth Calibration:** With 37 v1 requirements and comprehensive depth setting, 5 phases provides balanced grouping. Each phase delivers a coherent, verifiable capability.
- **Deferred Work:** SCRIPT-02 (ligand preparation) explicitly deferred to v2 per PROJECT.md — user provides prepared ligands.
- **Research Alignment:** Phase structure aligns with research/SUMMARY.md recommendations with minor adjustment: DOC-02 (agent-optimized docs) moved to Phase 4 to align with skills integration.
- **Anti-Patterns Avoided:** No horizontal layers, no arbitrary structure, every requirement maps to exactly one phase.
- **Phase 1 Ready:** Can proceed immediately — no blockers. Phases 2-5 blocked pending WORKFLOW.md finalization and script/output provision.
- **Script Split:** Phase 1 delivers infrastructure/utility scripts (workflow-agnostic). Phase 2 delivers workflow scripts, wrapper(s), and gap-filling scripts (workflow-dependent).

---

*Roadmap created: 2026-03-23*
*Ready for planning: Yes*