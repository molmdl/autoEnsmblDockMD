# Namespace Conflict Analysis

**Generated:** 2026-04-19 20:49:26
**Scope:** `.opencode/skills/`, `scripts/commands/`, `scripts/agents/`, `README.md`, `AGENTS.md`, `WORKFLOW.md`, `docs/EXPERIMENTAL.md`, `docs/GUIDE.md`, plus context from `.planning/scancode.md` and `.planning/STATE.md`.

## Executive Summary

Phase 5.1 successfully fixed the original public namespace problem: the active skill names, slash-command names, and wrapper filenames now use the `aedmd-*` prefix consistently across the user-facing command surface.

No remaining **public** slash-command collisions were detected in the active command set under `scripts/commands/aedmd-*.sh` or in the active skill frontmatter under `.opencode/skills/aedmd-*/SKILL.md`.

The remaining issues are **internal namespace inconsistencies**, not public command-name conflicts:

- wrapper-dispatched stage tokens do not match canonical workflow stage identifiers used by skills and `scripts/agents/schemas/state.py`
- handoff filenames implied by wrappers do not match several skill documents
- agent routing expects canonical workflow stage values, but some wrappers pass ad hoc snake_case tokens
- `RunnerAgent` expects a `script` field that the wrappers never provide

## Inputs Reviewed

- Request context: `.planning/scancode.md`
- Phase 5.1 decision record: `.planning/STATE.md`
- Skills:
  - `.opencode/skills/aedmd-status/SKILL.md`
  - `.opencode/skills/aedmd-rec-ensemble/SKILL.md`
  - `.opencode/skills/aedmd-orchestrator-resume/SKILL.md`
  - `.opencode/skills/aedmd-dock-run/SKILL.md`
  - `.opencode/skills/aedmd-debugger-diagnose/SKILL.md`
  - `.opencode/skills/aedmd-com-setup/SKILL.md`
  - `.opencode/skills/aedmd-com-mmpbsa/SKILL.md`
  - `.opencode/skills/aedmd-com-md/SKILL.md`
  - `.opencode/skills/aedmd-com-analyze/SKILL.md`
  - `.opencode/skills/aedmd-checker-validate/SKILL.md`
- Wrappers:
  - `scripts/commands/aedmd-status.sh`
  - `scripts/commands/aedmd-rec-ensemble.sh`
  - `scripts/commands/aedmd-orchestrator-resume.sh`
  - `scripts/commands/aedmd-dock-run.sh`
  - `scripts/commands/aedmd-debugger-diagnose.sh`
  - `scripts/commands/aedmd-com-setup.sh`
  - `scripts/commands/aedmd-com-mmpbsa.sh`
  - `scripts/commands/aedmd-com-md.sh`
  - `scripts/commands/aedmd-com-analyze.sh`
  - `scripts/commands/aedmd-checker-validate.sh`
- Agent routing / execution:
  - `scripts/agents/__main__.py`
  - `scripts/agents/__init__.py`
  - `scripts/agents/utils/routing.py`
  - `scripts/agents/schemas/state.py`
  - `scripts/agents/runner.py`
  - `scripts/agents/analyzer.py`
  - `scripts/agents/orchestrator.py`
  - `scripts/agents/checker.py`
  - `scripts/agents/debugger.py`
- User-facing docs:
  - `README.md`
  - `AGENTS.md`
  - `WORKFLOW.md`
  - `docs/EXPERIMENTAL.md`
  - `docs/GUIDE.md`

## 1) Current namespace status post-5.1 fixes

### Public command surface

The public namespace is now consistently namespaced:

- skills use `name: aedmd-*` in frontmatter, for example `.opencode/skills/aedmd-status/SKILL.md`
- skill directory names also use `aedmd-*`, for example `.opencode/skills/aedmd-dock-run/`
- wrapper filenames use `aedmd-*`, for example `scripts/commands/aedmd-com-setup.sh`
- docs reference prefixed slash commands, for example `README.md`, `AGENTS.md`, `docs/EXPERIMENTAL.md`, and `docs/GUIDE.md`

### Public collision check

Detected result:

- **No active exact-name collisions found** among the public slash commands reviewed.
- The previously risky generic name `/status` is no longer active on the public surface; it is now `/aedmd-status` in `AGENTS.md`, `README.md`, `docs/EXPERIMENTAL.md`, and `docs/GUIDE.md`.
- `WORKFLOW.md` stays script-oriented and does not introduce conflicting slash-command aliases.

### Low-risk internal generic name

- `scripts/commands/common.sh` remains generically named, but it is an internal sourced helper, not a public slash-command wrapper. This is not a current OpenCode collision risk.

## 2) Cross-reference validation

### 2.1 External naming alignment

The following naming layers are aligned for all 10 public skills/commands:

| Public skill/command id | Skill folder | Frontmatter `name:` | Wrapper script | Slash command in docs | Result |
|---|---|---|---|---|---|
| `aedmd-status` | `.opencode/skills/aedmd-status/` | `aedmd-status` | `scripts/commands/aedmd-status.sh` | `/aedmd-status` | Aligned |
| `aedmd-rec-ensemble` | `.opencode/skills/aedmd-rec-ensemble/` | `aedmd-rec-ensemble` | `scripts/commands/aedmd-rec-ensemble.sh` | `/aedmd-rec-ensemble` | Aligned |
| `aedmd-orchestrator-resume` | `.opencode/skills/aedmd-orchestrator-resume/` | `aedmd-orchestrator-resume` | `scripts/commands/aedmd-orchestrator-resume.sh` | `/aedmd-orchestrator-resume` | Aligned |
| `aedmd-dock-run` | `.opencode/skills/aedmd-dock-run/` | `aedmd-dock-run` | `scripts/commands/aedmd-dock-run.sh` | `/aedmd-dock-run` | Aligned |
| `aedmd-debugger-diagnose` | `.opencode/skills/aedmd-debugger-diagnose/` | `aedmd-debugger-diagnose` | `scripts/commands/aedmd-debugger-diagnose.sh` | `/aedmd-debugger-diagnose` | Aligned |
| `aedmd-com-setup` | `.opencode/skills/aedmd-com-setup/` | `aedmd-com-setup` | `scripts/commands/aedmd-com-setup.sh` | `/aedmd-com-setup` | Aligned |
| `aedmd-com-mmpbsa` | `.opencode/skills/aedmd-com-mmpbsa/` | `aedmd-com-mmpbsa` | `scripts/commands/aedmd-com-mmpbsa.sh` | `/aedmd-com-mmpbsa` | Aligned |
| `aedmd-com-md` | `.opencode/skills/aedmd-com-md/` | `aedmd-com-md` | `scripts/commands/aedmd-com-md.sh` | `/aedmd-com-md` | Aligned |
| `aedmd-com-analyze` | `.opencode/skills/aedmd-com-analyze/` | `aedmd-com-analyze` | `scripts/commands/aedmd-com-analyze.sh` | `/aedmd-com-analyze` | Aligned |
| `aedmd-checker-validate` | `.opencode/skills/aedmd-checker-validate/` | `aedmd-checker-validate` | `scripts/commands/aedmd-checker-validate.sh` | `/aedmd-checker-validate` | Aligned |

### 2.2 Documentation alignment

Alignment status in requested docs:

- `AGENTS.md` is fully updated to `aedmd-*` skill paths and slash commands.
- `README.md` explicitly documents the `aedmd-` namespace and cites examples such as `/aedmd-status`.
- `docs/EXPERIMENTAL.md` explicitly documents the `aedmd-` namespace.
- `docs/GUIDE.md` uses `bash scripts/commands/aedmd-status.sh --workdir ...` and references skill paths under `.opencode/skills/aedmd-{name}/SKILL.md`.
- `WORKFLOW.md` does not introduce contradictory slash command names.

Conclusion: **requested user-facing docs are aligned on the public namespace.**

## 3) Remaining inconsistencies

These are the real post-5.1 gaps.

### 3.1 Internal stage namespace drift between skills, wrappers, and agents

The public command ids are aligned, but the **workflow stage ids** are not.

| Command | Skill metadata stage | Wrapper-dispatched stage | Canonical stage in `scripts/agents/schemas/state.py` / routing | Impact |
|---|---|---|---|---|
| `aedmd-rec-ensemble` | `receptor_cluster` | `rec_ensemble` | `receptor_cluster` | Wrapper handoff name diverges from canonical workflow stage |
| `aedmd-dock-run` | `docking_run` | `dock_run` | `docking_run` | Wrapper stage token diverges from skill + enum |
| `aedmd-com-setup` | `complex_prep` | `com_setup` | `complex_prep` | Wrapper stage token diverges from skill + enum |
| `aedmd-com-md` | `complex_md` | `com_md` | `complex_md` | Wrapper stage token diverges from skill + enum |
| `aedmd-com-mmpbsa` | `complex_mmpbsa` | `com_mmpbsa` | `complex_mmpbsa` | Wrapper stage token diverges from skill + enum |
| `aedmd-com-analyze` | `complex_analysis` | `com_analyze` | `complex_analysis` | Wrapper stage token diverges from analyzer stage map |
| `aedmd-orchestrator-resume` | `workflow_resume` | `orchestrator_resume` | no matching `WorkflowStage` value | Wrapper token is not parseable by `OrchestratorAgent._parse_stage()` |
| `aedmd-checker-validate` | `quality_validation` | `checker_validate` | not represented in `WorkflowStage` | Naming drift between skill and wrapper |
| `aedmd-debugger-diagnose` | `failure_diagnosis` | `debugger_diagnose` | not represented in `WorkflowStage` | Naming drift between skill and wrapper |
| `aedmd-status` | `workspace_status` | N/A | not represented in `WorkflowStage` | Standalone status command is separate, which is acceptable |

#### Evidence

- Canonical workflow enum: `scripts/agents/schemas/state.py`
- Wrapper tokens: `scripts/commands/aedmd-*.sh`
- Skill metadata stages: `.opencode/skills/aedmd-*/SKILL.md`
- Analyzer stage map: `scripts/agents/analyzer.py`
- Orchestrator parsing: `scripts/agents/orchestrator.py`

### 3.2 Handoff filename inconsistencies

Because `scripts/commands/common.sh` writes `.handoffs/${stage}.json` using wrapper-provided stage ids, several documented handoff filenames do not match actual wrapper output names.

| Command | Skill-documented handoff | Actual wrapper-generated handoff |
|---|---|---|
| `aedmd-rec-ensemble` | `.handoffs/receptor_cluster.json` | `.handoffs/rec_ensemble.json` |
| `aedmd-dock-run` | `.handoffs/docking_run.json` | `.handoffs/dock_run.json` |
| `aedmd-com-setup` | `.handoffs/complex_prep.json` | `.handoffs/com_setup.json` |
| `aedmd-com-md` | `.handoffs/complex_md.json` | `.handoffs/com_md.json` |
| `aedmd-com-mmpbsa` | `.handoffs/complex_mmpbsa.json` | `.handoffs/com_mmpbsa.json` |
| `aedmd-com-analyze` | `.handoffs/complex_analysis.json` | `.handoffs/com_analyze.json` |
| `aedmd-orchestrator-resume` | `.handoffs/latest.json` | `.handoffs/orchestrator_resume.json` |
| `aedmd-checker-validate` | not fixed to wrapper stage filename; doc emphasizes direct handoff input | `.handoffs/checker_validate.json` |
| `aedmd-debugger-diagnose` | not fixed to wrapper stage filename; doc emphasizes direct handoff input | `.handoffs/debugger_diagnose.json` |

This is a **namespace consistency problem** because different layers are using different identifiers for the same concept.

### 3.3 Wrapper-to-agent contract inconsistencies

These are not prefix conflicts, but they are namespace/contract mismatches that will matter if the slash-command layer is used.

#### Runner wrappers do not provide the field the runner requires

- `scripts/commands/common.sh` sends JSON with `stage`, `config`, and `params`.
- `scripts/agents/runner.py` immediately reads `input_data["script"]`.
- No runner wrapper injects `script`.

Result: `aedmd-rec-ensemble`, `aedmd-dock-run`, `aedmd-com-setup`, `aedmd-com-md`, and `aedmd-com-mmpbsa` are namespaced correctly but still rely on an inconsistent internal contract.

#### Analyzer wrapper stage does not match analyzer routing keys

- `scripts/commands/aedmd-com-analyze.sh` dispatches stage `com_analyze`.
- `scripts/agents/analyzer.py` only maps `complex_analysis` and `receptor_cluster`.

Result: the public name is consistent, but the internal stage namespace is not.

#### Orchestrator wrapper stage is not a valid `WorkflowStage`

- `scripts/commands/aedmd-orchestrator-resume.sh` dispatches `orchestrator_resume`.
- `scripts/agents/orchestrator.py` normalizes stage via `WorkflowStage(stage_value)`.
- `scripts/agents/schemas/state.py` has no `orchestrator_resume` value.

Result: the wrapper name is fine, but the stage id namespace does not align with the orchestrator’s canonical stage vocabulary.

## 4) Remaining conflicts with standard OpenCode commands or common shell utilities

### Active public names

No exact conflicts detected in the active public names:

- `/aedmd-status`
- `/aedmd-rec-ensemble`
- `/aedmd-dock-run`
- `/aedmd-com-setup`
- `/aedmd-com-md`
- `/aedmd-com-mmpbsa`
- `/aedmd-com-analyze`
- `/aedmd-checker-validate`
- `/aedmd-debugger-diagnose`
- `/aedmd-orchestrator-resume`

Why this is materially better than the previous scheme:

- exact collision with a generic built-in such as `/status` is avoided
- project-owned commands now cluster under a single predictable prefix
- shell utility ambiguity is reduced because the visible command token is no longer a common English verb/noun by itself

### Non-public names

- `scripts/commands/common.sh` is generic, but it is internal and not a slash-command endpoint.
- Internal stage tokens such as `dock_run`, `com_md`, and `checker_validate` are also not direct OpenCode slash commands, so they are not command-collision risks by themselves.

## 5) Namespace prefix evaluation

### Comparison table

| Prefix | Collision avoidance | Discoverability / autocomplete | Typing efficiency | Consistency with project name | Assessment |
|---|---|---|---|---|---|
| `aedmd-` | High | High: all project commands group together under one prefix | Good | High: recognizable contraction of autoEnsmblDockMD | **Best current choice** |
| `aed-` | Medium | Medium: shorter, but acronym is vague | Excellent | Medium-low: drops `md`, less tied to project identity | Too ambiguous |
| `admd-` | Medium-high | Medium | Good | Medium: resembles project but less faithful | Acceptable but weaker than `aedmd-` |
| `autoensemble-` | High | Medium-high | Poor | Medium: captures ensemble, drops DockMD | Too long and incomplete |
| `autoensmbldockmd-` | Very high | Medium | Very poor | Very high | Too long, typo-prone, low ergonomics |

### Detailed reasoning

#### `aedmd-*` strengths

1. **Collision avoidance**
   - It is specific enough that exact-name collisions with standard OpenCode built-ins are unlikely.
   - It removes the original `/status` ambiguity without requiring per-command exceptions.

2. **Discoverability and autocomplete**
   - A shared prefix makes project commands easy to scan and easy to autocomplete as a group.
   - Users can type `/aedmd-` and discover the full project command family.

3. **Typing efficiency vs explicitness**
   - It is longer than `aed-`, but still short enough for practical repeated use.
   - It keeps `md`, which matters in this repo because the workflow is not just ensemble docking; it includes MD and MM/PBSA.

4. **Consistency with project naming**
   - The repo name is `autoEnsmblDockMD`.
   - `aedmd` is the closest compact prefix to that existing project identity without becoming unwieldy.

5. **Industry practice**
   - Prefixing repo-local tools with a project/vendor namespace is common best practice when commands live inside a broader host platform.
   - The current scheme follows the “project-prefix + verb-noun action” pattern cleanly.

#### Why not switch to `aed-*`

- It is shorter, but it loses too much project specificity.
- `aed` is a common acronym outside this project, so collision and ambiguity risk increase.
- It weakens semantic connection to the MD-heavy workflow.

#### Why not switch to `admd-*`

- It is workable, but less clearly derived from `autoEnsmblDockMD`.
- It is easier to misread as a different acronym family.
- It provides no strong enough benefit to justify another rename wave.

#### Why not switch to `autoensemble-*` or longer forms

- These improve explicitness, but they are slower to type and more error-prone.
- Very long prefixes reduce ergonomics and make slash-command usage less pleasant.
- They do not buy enough additional safety over `aedmd-*`.

## 6) Recommendations

### Recommendation 1 — Keep `aedmd-*` as the public namespace

**Recommendation:** approve the Phase 5.1 prefix choice and do not rename again.

Reason:

- the public collision problem is already solved
- `aedmd-*` is the best balance of uniqueness, discoverability, ergonomics, and fidelity to `autoEnsmblDockMD`
- switching to `aed-*`, `admd-*`, or longer alternatives would create churn without materially improving safety

### Recommendation 2 — Standardize internal stage ids separately from public command ids

Do **not** reuse public command ids as workflow stage ids implicitly.

Use two explicit namespaces:

- **public command id:** `aedmd-com-analyze`
- **canonical workflow stage id:** `complex_analysis`

Apply this consistently in:

- `.opencode/skills/aedmd-*/SKILL.md` metadata `stage:`
- `scripts/commands/aedmd-*.sh`
- `scripts/commands/common.sh`
- `scripts/agents/schemas/state.py`
- `scripts/agents/utils/routing.py`
- `scripts/agents/analyzer.py`, `scripts/agents/orchestrator.py`, `scripts/agents/runner.py`

### Recommendation 3 — Align handoff filenames with canonical stage ids

Pick one canonical handoff filename basis and use it everywhere.

Preferred choice:

- `.handoffs/receptor_cluster.json`
- `.handoffs/docking_run.json`
- `.handoffs/complex_prep.json`
- `.handoffs/complex_md.json`
- `.handoffs/complex_mmpbsa.json`
- `.handoffs/complex_analysis.json`

This matches `scripts/agents/schemas/state.py` and current skill metadata better than the wrapper-local short forms.

### Recommendation 4 — Fix the wrapper-to-agent execution contract

If the slash-command bridge is meant to execute real stages, then `scripts/commands/common.sh` and `scripts/agents/runner.py` need a shared contract for at least:

- canonical stage id
- script path or script resolver key
- config path
- forwarded params

Without that, the namespace is cosmetically clean but operationally inconsistent.

## Final Assessment

**Public namespace:** sound after Phase 5.1.

**Prefix choice:** `aedmd-*` is the best option among the evaluated alternatives and should remain the stable public namespace.

**Remaining work:** internal identifier cleanup, not another public rename.

In short:

- **Approve** the `aedmd-*` public namespace.
- **Do not** rename to `aed-*`, `admd-*`, or longer alternatives.
- **Do** standardize internal stage ids and handoff naming so wrappers, skills, docs, and agents share one canonical workflow vocabulary.
