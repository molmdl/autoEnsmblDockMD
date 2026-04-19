# Coding Conventions

**Analysis Date:** 2026-04-19

## Naming Patterns

**Files:**
- Use numeric stage prefixes plus snake_case for pipeline scripts under `scripts/rec/`, `scripts/dock/`, and `scripts/com/`: `scripts/rec/0_prep.sh`, `scripts/com/3_com_ana_trj.py`, `scripts/dock/4_dock2com_2.py`.
- Use hyphenated, namespaced wrapper names for public slash-command bridges under `scripts/commands/`: `scripts/commands/aedmd-rec-ensemble.sh`, `scripts/commands/aedmd-debugger-diagnose.sh`, `scripts/commands/aedmd-status.sh`.
- Use snake_case package/module names for reusable Python code under `scripts/agents/`, `scripts/infra/`, and `scripts/dock/`: `scripts/agents/base.py`, `scripts/infra/config.py`, `scripts/dock/dock2com_2_1.py`.
- Keep documentation and skill references aligned to the `aedmd-*` namespace used in `README.md`, `docs/EXPERIMENTAL.md`, `docs/GUIDE.md`, `AGENTS.md`, and `.opencode/docs/AGENT-WORKFLOW.md`.

**Functions:**
- Use snake_case for Python functions and methods: `scripts/rec/5_align.py:align_structures`, `scripts/agents/__main__.py:load_config`, `scripts/infra/config.py:get_execution_backend`.
- Use verb-led shell helper names for reusable operations: `scripts/infra/common.sh:require_file`, `scripts/infra/common.sh:submit_job`, `scripts/commands/common.sh:dispatch_agent`.
- Reserve `main()` as the CLI boundary in Python entrypoints such as `scripts/com/4_fp.py`, `scripts/dock/4_dock2com_2.py`, and `scripts/agents/__main__.py`.

**Variables:**
- Use `UPPER_SNAKE_CASE` for shell globals and constant-like maps: `scripts/run_pipeline.sh:STAGE_CMD`, `scripts/commands/common.sh:PROJECT_ROOT`, `scripts/com/3_ana.sh:RUN_ADVANCED`.
- Use snake_case for Python locals, parameters, and instance attributes: `scripts/agents/runner.py:command_list`, `scripts/agents/base.py:checkpoint_mgr`, `scripts/com/4_fp.py:receptor_selection`.
- Use upper-case constant maps/lists in Python for registry data: `scripts/agents/__init__.py:AGENT_REGISTRY`, `scripts/agents/utils/routing.py:STAGE_AGENT_MAP`, `scripts/agents/checker.py:DEFAULT_CHECKS`.

**Types:**
- Use PascalCase for Python classes, dataclasses, and enums: `scripts/agents/base.py:BaseAgent`, `scripts/agents/checker.py:CheckResult`, `scripts/agents/schemas/handoff.py:HandoffRecord`, `scripts/infra/verification.py:VerificationGate`.
- Use enum members in upper snake case for canonical workflow/status vocabularies: `scripts/agents/schemas/handoff.py:HandoffStatus.SUCCESS`, `scripts/agents/schemas/state.py:WorkflowStage.COM_MMPBSA`, `scripts/infra/verification.py:GateState.APPROVED`.

## Code Style

**Formatting:**
- No dedicated repo-wide formatter config is detected in the repository root; `.prettierrc*`, `.eslintrc*`, `pyproject.toml`, `ruff.toml`, `pytest.ini`, and `tox.ini` are not present under `/share/home/nglokwan/autoEnsmblDockMD`.
- Start shell scripts with a shebang and `set -euo pipefail`, following `scripts/run_pipeline.sh`, `scripts/commands/aedmd-rec-ensemble.sh`, `scripts/com/3_ana.sh`, and `scripts/dock/4_dock2com.sh`.
- Start Python modules with a module docstring, and in newer modules place `from __future__ import annotations` immediately after it, following `scripts/agents/base.py`, `scripts/agents/__main__.py`, `scripts/com/4_fp.py`, and `scripts/dock/4_dock2com_2.py`.
- Use 4-space indentation in Python and 4-space indentation inside shell functions, loops, and `case` branches, as in `scripts/infra/config.py`, `scripts/infra/verification.py`, `scripts/infra/common.sh`, and `scripts/com/3_ana.sh`.

**Linting:**
- No repo-wide lint runner is detected.
- Keep ShellCheck-compatible source annotations on dynamic `source` statements: `scripts/run_pipeline.sh`, `scripts/dock/4_dock2com.sh`, `scripts/dock/4_dock2com_ref.sh`, and `scripts/commands/common.sh` use `# shellcheck source=/dev/null` or `# shellcheck disable=SC1090`.
- Keep Python type hints on public helpers and agent interfaces, following `scripts/agents/base.py`, `scripts/agents/checker.py`, `scripts/agents/runner.py`, `scripts/infra/config.py`, and `scripts/rec/5_align.py`.
- Preserve defensive `pragma: no cover` comments when already used on exceptional CLI boundaries, such as `scripts/agents/__main__.py` and `scripts/com/4_fp.py`.

## Import Organization

**Order:**
1. Standard-library imports first, as in `scripts/agents/__main__.py` (`argparse`, `json`, `sys`, `pathlib`) and `scripts/infra/config.py` (`argparse`, `configparser`, `os`, `sys`).
2. Third-party imports second, as in `scripts/com/4_fp.py` (`matplotlib`, `numpy`, `MDAnalysis`) and `scripts/rec/5_align.py` (`MDAnalysis`).
3. Project-local imports last, rooted at `scripts.*`, as in `scripts/agents/orchestrator.py`, `scripts/agents/base.py`, and `scripts/agents/utils/routing.py`.

**Path Aliases:**
- No path alias system is detected.
- Use package imports rooted at `scripts.*` for internal Python dependencies: `scripts.agents`, `scripts.infra`, and `scripts.dock` in `scripts/agents/__main__.py`, `scripts/agents/checker.py`, and `scripts/dock/4_dock2com_2.py`.
- When a numeric filename needs import compatibility, use a wrapper module instead of an alias system, following `scripts/dock/dock2com_2_1.py` and `scripts/dock/gro_itp_to_mol2.py`.

## Error Handling

**Patterns:**
- Raise specific Python exceptions near the failing precondition, following `scripts/rec/5_align.py` (`ValueError`, `FileNotFoundError`), `scripts/dock/4_dock2com_2.py` (`ValueError`, `FileNotFoundError`), and `scripts/com/4_fp.py` (`ValueError`).
- Use `argparse` validation for required CLI inputs and `parser.error(...)` when a combination is invalid, as in `scripts/dock/4_dock2com_2.py`.
- Return integer exit codes from Python CLI `main()` functions and terminate via `sys.exit(main())` or `raise SystemExit(main())`, following `scripts/agents/__main__.py`, `scripts/com/4_fp.py`, and `scripts/dock/4_dock2com_2.py`.
- In shell, fail fast with `set -euo pipefail` plus explicit guards such as `[[ $# -ge 2 ]] || { log_error "--config requires a file path"; exit 1; }` in `scripts/run_pipeline.sh`, `scripts/com/2_mmpbsa.sh`, and `scripts/com/3_ana.sh`.
- Reuse shared validation helpers from `scripts/infra/common.sh` and `scripts/commands/common.sh` instead of open-coding checks in new shell scripts.

## Logging

**Framework:**
- Use `log_info`, `log_warn`, and `log_error` from `scripts/infra/common.sh` for shell scripts.
- Python CLIs mostly use `print(...)` for user-facing summaries; Python `logging` is initialized at the agent base layer in `scripts/agents/base.py` and only lightly used elsewhere.

**Patterns:**
- Log stage starts, finishes, and major actions in shell entrypoints, following `scripts/run_pipeline.sh`, `scripts/com/3_ana.sh`, `scripts/dock/4_dock2com.sh`, and `scripts/dock/4_dock2com_ref.sh`.
- Print concise artifact/result paths in Python CLIs, following `scripts/com/4_fp.py`, `scripts/dock/4_dock2com_2.py`, and `scripts/rec/5_align.py`.
- Use structured JSON handoff payloads for agent-to-agent boundaries instead of prose logs, following `scripts/agents/base.py`, `scripts/agents/schemas/handoff.py`, and `scripts/commands/common.sh:dispatch_agent`.

## Comments

**When to Comment:**
- Use module docstrings to define scope and behavior, following `scripts/agents/base.py`, `scripts/infra/config.py`, `scripts/infra/verification.py`, `scripts/com/4_fp.py`, and `scripts/dock/4_dock2com_2.py`.
- Use short inline comments for compatibility, validation, and operator context, not narrative commentary, following `scripts/commands/common.sh`, `scripts/run_pipeline.sh`, `scripts/dock/4_dock2com.sh`, and `scripts/com/3_com_ana_trj.py`.
- Keep usage/help heredocs in shell entrypoints for operator-facing documentation, following `scripts/commands/common.sh`, `scripts/com/3_ana.sh`, and `scripts/dock/3_dock_report.sh`.
- Keep docs synchronized with code paths and namespaced command names; examples in `README.md`, `docs/EXPERIMENTAL.md`, `docs/GUIDE.md`, `AGENTS.md`, and `.opencode/docs/AGENT-WORKFLOW.md` all point to `scripts/commands/aedmd-*.sh` and `.opencode/skills/aedmd-*/SKILL.md`.

**JSDoc/TSDoc:**
- Not applicable; no JS/TS source tree is detected in the project code.
- Use Python docstrings as the standard in `scripts/agents/`, `scripts/infra/`, `scripts/com/`, `scripts/dock/`, and `scripts/rec/`.

## Function Design

**Size:**
- Keep reusable logic in named helpers and reserve `main()` for orchestration, following `scripts/rec/5_align.py` (`_resolve_structures`, `align_structures`, `main`), `scripts/com/4_fp.py` (`calculate_fingerprints`, `run_fingerprint_analysis`, `main`), and `scripts/dock/4_dock2com_2.py` (`_detect_ff_includes`, `build_complex_topology`, `main`).
- Larger single-file utilities are acceptable when broken into focused helper functions, following `scripts/infra/verification.py`, `scripts/com/3_com_ana_trj.py`, and `scripts/dock/0_gro_itp_to_mol2.py`.

**Parameters:**
- Prefer explicit long-form CLI flags in Python via `argparse`, following `scripts/agents/__main__.py`, `scripts/com/4_fp.py`, `scripts/rec/5_align.py`, and `scripts/dock/4_dock2com_2.py`.
- Prefer `--config` plus small targeted overrides in shell, following `scripts/run_pipeline.sh`, `scripts/com/3_ana.sh`, `scripts/com/2_mmpbsa.sh`, and the command wrappers in `scripts/commands/`.
- Preserve backward-compatible aliases when already established, such as `--ligand-selection` / `--ligand_sel` and `--receptor-selection` / `--receptor_sel` in `scripts/com/4_fp.py`.
- For slash-command wrappers, keep public command names namespaced as `aedmd-*` and forward extra flags through `scripts/commands/common.sh:parse_flags`.

**Return Values:**
- Return integer status codes from CLI `main()` functions in `scripts/agents/__main__.py`, `scripts/com/4_fp.py`, and `scripts/dock/4_dock2com_2.py`.
- Return dictionaries, tuples, enums, or dataclasses from reusable Python helpers rather than formatted strings, following `scripts/agents/runner.py`, `scripts/agents/checker.py`, `scripts/agents/schemas/handoff.py`, `scripts/infra/verification.py`, and `scripts/rec/5_align.py`.
- In shell, communicate pass/fail through exit status and concise stdout/stderr, following `scripts/commands/common.sh:check_handoff_result` and `scripts/infra/common.sh:submit_job`.

## Module Design

**Exports:**
- Use package `__init__.py` files with explicit `__all__` to define public APIs, following `scripts/agents/__init__.py`, `scripts/agents/schemas/__init__.py`, and `scripts/infra/__init__.py`.
- Keep standalone CLI modules importable where practical so wrappers and future tests can reuse their functions, following `scripts/com/4_fp.py`, `scripts/rec/5_align.py`, and `scripts/dock/4_dock2com_2.py`.

**Barrel Files:**
- Barrel-style re-export modules are used intentionally in `scripts/agents/__init__.py`, `scripts/agents/schemas/__init__.py`, and `scripts/infra/__init__.py`.
- Compatibility wrapper modules are also part of the public module design for numeric filenames, following `scripts/dock/dock2com_2_1.py` and `scripts/dock/gro_itp_to_mol2.py`.

---

*Convention analysis: 2026-04-19*
