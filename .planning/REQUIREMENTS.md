# Requirements: autoEnsmblDockMD

**Defined:** 2026-03-23
**Core Value:** Human-run pipeline producing validated, reproducible scientific outputs with minimal commands. Agent autonomy is secondary/experimental.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### I. Scripts (SCRIPT)

- [ ] **SCRIPT-01**: Receptor preparation scripts generalized (pdb2pqr, gmx pdb2gmx, ensemble MD, clustering, alignment)
- [ ] **SCRIPT-02**: Ligand preparation deferred — user provides prepared ligands (future work)
- [ ] **SCRIPT-03**: Docking scripts generalized (gnina execution, pose extraction, ensemble docking, autobox)
- [ ] **SCRIPT-04**: MD setup scripts generalized (complex building, solvation, ions, minimization, equilibration)
- [ ] **SCRIPT-05**: MD production scripts generalized (production run, trajectory handling)
- [ ] **SCRIPT-06**: MMPBSA scripts generalized (trajectory processing, binding energy, decomposition, plots, averaging)
- [ ] **SCRIPT-07**: Standard analysis scripts (RMSD, RMSF, contacts, etc.)
- [ ] **SCRIPT-08**: All scripts support CLI flags for options
- [ ] **SCRIPT-09**: All scripts use human-friendly config format (not YAML/JSON complexity)
- [ ] **SCRIPT-10**: Scripts consistent in I/O format, error handling, and coding style
- [x] **SCRIPT-11**: Infrastructure/utility scripts for config processing, checkpoint save/load, verification gates (Phase 1)
- [ ] **SCRIPT-12**: Wrapper scripts for pipeline orchestration (Phase 2)
- [ ] **SCRIPT-13**: Gap-filling scripts to bridge workflow stages (Phase 2)

### II. Agents (AGENT)

- [ ] **AGENT-01**: Orchestrator agent — manages workflow state, spawns agents, handles checkpoints
- [ ] **AGENT-02**: Runner agent — executes stage scripts, handles parameters
- [ ] **AGENT-03**: Analyzer agent — runs standard analysis, supports custom analysis
- [ ] **AGENT-04**: Checker agent — validates results, generates warnings/suggestions
- [ ] **AGENT-05**: Debugger agent — follows gsd-debugger workflow, version-aware (GROMACS 2023.5, gnina, gmx_MMPBSA)
- [x] **AGENT-06**: All agents use file-based state passing to avoid context overflow
- [ ] **AGENT-07**: Agent support marked as experimental in documentation

### III. Slash Commands (CMD)

- [ ] **CMD-01**: Slash commands for each major workflow stage
- [ ] **CMD-02**: Commands map to shell scripts executed by runner agent
- [ ] **CMD-03**: Commands follow `/stage-action` naming convention

### IV. Agent Skills (SKILL)

- [ ] **SKILL-01**: Skill files loadable by agents at runtime
- [ ] **SKILL-02**: Skills minimal but sufficient (capability metadata, usage, parameters, examples)
- [ ] **SKILL-03**: Skills follow consistent format (YAML or Markdown)

### V. Execution Environment (EXEC)

- [x] **EXEC-01**: Local execution support for all tasks
- [x] **EXEC-02**: HPC Slurm support for demanding tasks (mdrun, MMPBSA, heavy analysis)
- [x] **EXEC-03**: Job monitoring via log parsing
- [x] **EXEC-04**: Error detection and reporting
- [ ] **EXEC-05**: Independent jobs submit to Slurm in parallel

### VI. Checkpoint System (CHECK)

- [x] **CHECK-01**: Stage checkpoints save intermediate states
- [x] **CHECK-02**: Human verification gates between stages
- [x] **CHECK-03**: Agent context dump to file for session continuity

### VII. Documentation (DOC)

- [ ] **DOC-01**: README.md — clear usage instructions for humans (must-have, not feature)
- [ ] **DOC-02**: Agent-optimized documentation — detailed, structured for agent loading
- [ ] **DOC-03**: WORKFLOW.md — workflow steps and script usage (to be finalized)
- [ ] **DOC-04**: AGENTS.md — agent guidelines (exists, update as needed)

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Ligand Preparation Automation

- **LIG-01**: Automated ligand preparation (SDF/SMILES → 3D, FF parameters)
- **LIG-02**: ffnonbond.itp edits automation

### Advanced Features

- **ADV-01**: Real-time visualization
- **ADV-02**: Web interface
- **ADV-03**: Cloud execution

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Ligand prep automation | Complex chemistry, error-prone; user provides prepared ligands |
| ffnonbond.itp edits | Requires deep FF knowledge; user provides custom force field |
| Real-time visualization | Not required for MVP; post-analysis only |
| Web interface | Out of scope; CLI-focused design |
| Cloud execution | Out of scope; HPC Slurm + local only |
| GUIs | Adds maintenance burden; CLI preferred |
| Auto software installation | Environment complexity; user-managed conda |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

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
| SCRIPT-11 | Phase 1 | Complete |
| SCRIPT-12 | Phase 2 | Pending |
| SCRIPT-13 | Phase 2 | Pending |
| AGENT-01 | Phase 3 | Pending |
| AGENT-02 | Phase 3 | Pending |
| AGENT-03 | Phase 3 | Pending |
| AGENT-04 | Phase 3 | Pending |
| AGENT-05 | Phase 3 | Pending |
| AGENT-06 | Phase 1 | Complete |
| AGENT-07 | Phase 4 | Pending |
| CMD-01 | Phase 4 | Pending |
| CMD-02 | Phase 4 | Pending |
| CMD-03 | Phase 4 | Pending |
| SKILL-01 | Phase 4 | Pending |
| SKILL-02 | Phase 4 | Pending |
| SKILL-03 | Phase 4 | Pending |
| EXEC-01 | Phase 1 | Complete |
| EXEC-02 | Phase 1 | Complete |
| EXEC-03 | Phase 1 | Complete |
| EXEC-04 | Phase 1 | Complete |
| EXEC-05 | Phase 2 | Pending |
| CHECK-01 | Phase 1 | Complete |
| CHECK-02 | Phase 1 | Complete |
| CHECK-03 | Phase 1 | Complete |
| DOC-01 | Phase 5 | Pending |
| DOC-02 | Phase 4 | Pending |
| DOC-03 | Phase 5 | Pending |
| DOC-04 | Phase 5 | Pending |

**Coverage:**
- v1 requirements: 37 total
- Mapped to phases: 36 (1 deferred to v2)
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-23*
*Last updated: 2026-03-24 after Phase 1 context discussion*
