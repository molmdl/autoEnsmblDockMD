# Skill/Documentation Conflict Audit

**Timestamp:** 2026-04-19
**Scope:** Skill naming, slash-command collisions, doc/code consistency, and citation opportunities.

## Executive Summary

- The highest-risk naming conflict is the project-local `/status` slash command and `status` skill name, because `status` is a common internal OpenCode command name and is documented as a first-class project command in `AGENTS.md:96-109`, `.opencode/docs/AGENT-WORKFLOW.md:15-26`, and `.opencode/skills/status/SKILL.md:2-3`.
- The codebase has broader terminology drift between skills, wrappers, and docs: status values, stage IDs, handoff filenames, and agent names are not using one canonical vocabulary.
- Recommendation: add a project-specific prefix to **all** public skill/slash-command names, not only `status`. The best option in this repo is **`aedmd-`**.

## 1. OpenCode Command / Skill Naming Conflicts

### 1.1 `/status` naming collision

**Assessment:** Real conflict risk; this is the strongest collision in the repository.

**Why:**
- The public skill name is `status` in `.opencode/skills/status/SKILL.md:2`.
- The public slash command is documented as `/status` in `AGENTS.md:109` and `.opencode/docs/AGENT-WORKFLOW.md:17,456`.
- The command is positioned as the entry point for stage `input_prep` in `.opencode/docs/AGENT-WORKFLOW.md:17`, even though the implementation is a lightweight workspace inspection wrapper in `scripts/commands/status.sh:1-71`.

**Conflict mechanism:**
- `status` is generic, platform-looking, and likely to overlap with built-in or future reserved OpenCode command names.
- A user typing `/status` cannot tell whether they are invoking a platform command or this repository-specific command.
- The docs currently present `/status` as if it were globally safe and unambiguous.

### 1.2 Other command names

**Lower risk individually, but still namespace debt:**
- `/rec-ensemble`, `/dock-run`, `/com-setup`, `/com-md`, `/com-mmpbsa`, `/com-analyze`, `/checker-validate`, `/debugger-diagnose`, and `/orchestrator-resume` are more specific than `/status`, but they are still repo-local commands exposed without a namespace in `AGENTS.md:96-109` and `.opencode/docs/AGENT-WORKFLOW.md:447-456`.
- Leaving one unprefixed public namespace means future collisions remain possible, especially for generic operational verbs like `status`, `resume`, `analyze`, and `validate`.

## 2. Recommendation on Prefixing

## Recommended decision

**Yes — add a prefix to all public skills and slash commands, and update related docs.**

### Recommended prefix: `aedmd-`

**Why `aedmd-` is the best fit among `aedmd` / `aed` / `admd`:**
- `aedmd` is specific to `autoEnsmblDockMD` and is unlikely to collide with platform or third-party commands.
- `aed` is too short and too generic.
- `admd` is shorter, but easier to confuse with generic MD terminology or other project abbreviations.
- `aedmd-` preserves readability while making command ownership obvious.

### Recommended public names

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

### Why prefix **all** names instead of only `/status`

- `AGENTS.md:91` says the skill `name` field is canonical and must match slash-command/agent references. A one-off rename of only `status` would leave the public namespace inconsistent.
- A full prefix establishes a stable project-local namespace once, instead of patching collisions incrementally.
- It reduces ambiguity in docs, examples, and future automation prompts.
- The repository is still in an experimental agent phase (`README.md:201-207`, `docs/EXPERIMENTAL.md:1-25`), so this is the cheapest point to normalize names.

## 3. Doc ↔ Code Consistency Issues

### 3.1 Handoff status vocabulary mismatch

**Docs say:** `pending | running | complete | failed | needs_review | blocked` in `.opencode/docs/AGENT-WORKFLOW.md:63,87,137-145`.

**Code expects:** `success | needs_review | failure | blocked` in `scripts/commands/common.sh:128-147`.

**Impact:**
- `status.sh` only treats `success` as completed in `scripts/commands/status.sh:50-57`.
- Any handoff written with documented value `complete` would not be recognized as complete by wrapper logic.

### 3.2 `/status` docs overstate actual implementation

**Docs claim:**
- Stage `input_prep` maps to `/status` and validates config sections and inputs in `.opencode/docs/AGENT-WORKFLOW.md:17,198-209`.
- `docs/GUIDE.md:390-396,424-428` presents `status.sh` as a workspace readiness check.
- `.opencode/skills/status/SKILL.md:15,38-39` says it reports workflow progress, completed stages, pending stages, and handoff status.

**Code does:**
- Read `[workflow] mode` from config in `scripts/commands/status.sh:21-30`.
- List `.handoffs/*.json` and print the last `success` stage in `scripts/commands/status.sh:34-69`.
- It does **not** validate required config sections, input paths, or stage preconditions described in `.opencode/docs/AGENT-WORKFLOW.md:204-208`.
- It does **not** compute pending stages.

### 3.3 `--workdir` documented for `status`, but not implemented

**Docs/skill say:**
- `.opencode/skills/status/SKILL.md:34` documents CLI flag `--workdir`.
- `docs/GUIDE.md:393,427` tells users to run `bash scripts/commands/status.sh --workdir work/my_project`.

**Code does:**
- Determine workspace via `find_workspace_root` before flag parsing in `scripts/commands/status.sh:8-11`.
- `parse_flags` in `scripts/commands/common.sh:57-98` accepts unknown flags generically, but `status.sh` never reads forwarded `EXTRA_PARAMS`.

**Impact:** the documented `--workdir` example is misleading.

### 3.4 Mode key mismatch for `status`

**Docs say:**
- `.opencode/docs/AGENT-WORKFLOW.md:51` says mode is set via `[docking] mode`.
- `.opencode/skills/status/SKILL.md:43` mentions workflow/docking mode settings.

**Code reads:** `[workflow] mode` in `scripts/commands/status.sh:22-30`.

**Impact:** status output can report `unknown` even when the documented config key is present.

### 3.5 Analysis agent type mismatch

**Docs say:**
- `AGENTS.md:36-49` lists `com-analyze` under Runner.
- `.opencode/docs/AGENT-WORKFLOW.md:26` assigns stage `analysis` to agent type `runner`.

**Code/skill say:**
- `scripts/commands/com-analyze.sh:13` dispatches `analyzer`.
- `.opencode/skills/com-analyze/SKILL.md:9,30` also uses `analyzer`.

**Impact:** the documented agent taxonomy is not aligned with the live wrapper/skill behavior.

### 3.6 Skill expected handoff filenames do not match wrapper filenames

Examples:
- `.opencode/skills/rec-ensemble/SKILL.md:45` expects `.handoffs/receptor_cluster.json`, but `scripts/commands/rec-ensemble.sh:13-14` checks `.handoffs/rec_ensemble.json`.
- `.opencode/skills/dock-run/SKILL.md:45` expects `.handoffs/docking_run.json`, but `scripts/commands/dock-run.sh:13-14` checks `.handoffs/dock_run.json`.
- `.opencode/skills/com-analyze/SKILL.md:45` expects `.handoffs/complex_analysis.json`, but `scripts/commands/com-analyze.sh:13-14` checks `.handoffs/com_analyze.json`.
- `.opencode/skills/orchestrator-resume/SKILL.md:34` defaults to `.handoffs/latest.json`, but `scripts/commands/orchestrator-resume.sh:13-14` checks `.handoffs/orchestrator_resume.json`.

**Impact:** the skill docs are not reliable as implementation references for actual handoff filenames.

### 3.7 Checker/debugger invocation docs do not match skill parameter tables

**Docs show:**
- `.opencode/docs/AGENT-WORKFLOW.md:154,173,396,407` invoke `checker-validate.sh` and `debugger-diagnose.sh` with `--stage <stage_id>`.

**Skill tables list:**
- No `--stage` parameter in `.opencode/skills/checker-validate/SKILL.md:30-35`.
- No `--stage` parameter in `.opencode/skills/debugger-diagnose/SKILL.md:30-35`.

**Impact:** user-facing skill docs omit a flag that orchestration docs treat as normal usage.

## 4. Documentation Update Guidance

### 4.1 Files that should be updated if prefixing is adopted

- `AGENTS.md`
- `.opencode/docs/AGENT-WORKFLOW.md`
- `README.md`
- `docs/GUIDE.md`
- `docs/EXPERIMENTAL.md`
- `.opencode/skills/*/SKILL.md`

### 4.2 Minimal rename policy

If prefixing is adopted, update these together in one change set:
- skill folder names under `.opencode/skills/`
- `name:` frontmatter in each `SKILL.md`
- public slash-command names in `AGENTS.md` and `.opencode/docs/AGENT-WORKFLOW.md`
- any human-facing examples in `README.md`, `docs/GUIDE.md`, and `docs/EXPERIMENTAL.md`

This avoids mixed-name documentation where the public command name, skill file name, and skill metadata diverge.

## 5. Suggested Citations to Add to Docs

To reduce future drift, add direct source-of-truth citations in docs.

### 5.1 `AGENTS.md`

Add citations or inline “source of truth” notes pointing to:
- `scripts/commands/common.sh:57-149` for common flags and handoff status handling.
- `scripts/commands/status.sh:1-71` for the actual behavior of the status command.
- `scripts/commands/com-analyze.sh:1-14` and `.opencode/skills/com-analyze/SKILL.md:1-50` for the live `analyzer` agent mapping.

### 5.2 `.opencode/docs/AGENT-WORKFLOW.md`

Add citations beside:
- the status/state-machine section to `scripts/commands/status.sh:21-69` and `scripts/commands/common.sh:128-147`.
- the analysis stage row to `scripts/commands/com-analyze.sh:13` and `.opencode/skills/com-analyze/SKILL.md:9`.
- the config-section expectations to `scripts/config.ini.template` and `scripts/CONTEXT.md`.

### 5.3 `docs/GUIDE.md`

Add citations beside status-command examples to:
- `scripts/commands/status.sh:8-11` to show current workspace resolution behavior.
- `scripts/commands/common.sh:57-98` to show currently accepted flag parsing behavior.

Also remove or footnote the `--workdir` example until implementation exists.

### 5.4 `README.md` and `docs/EXPERIMENTAL.md`

Add citations to:
- `AGENTS.md` for role boundaries.
- `.opencode/docs/AGENT-WORKFLOW.md` for the detailed command-to-skill map.
- `scripts/commands/*.sh` as the implementation-backed wrapper layer.

## 6. Priority Fix Order

1. Rename `/status` and `status` skill into a prefixed project-local name.
2. Standardize one handoff status vocabulary across docs and `scripts/commands/common.sh`.
3. Standardize one stage/handoff naming scheme across wrappers, skills, and orchestration docs.
4. Reconcile `com-analyze` agent type (`runner` vs `analyzer`).
5. Remove or correct undocumented/unsupported `status --workdir` guidance.
6. Add direct implementation citations to the docs listed above.

## Bottom Line

The repo already has one clear public-name collision candidate: `/status`. Because the current skill/command surface also has broader vocabulary drift, the best path is **not** a one-off rename. The cleaner fix is a full project namespace such as **`aedmd-`** applied consistently across skill names, slash-command names, and related documentation, with explicit citations back to `scripts/commands/*.sh` and `scripts/commands/common.sh` as the implementation source of truth.
