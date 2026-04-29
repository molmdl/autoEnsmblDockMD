# Coding Conventions

**Analysis Date:** 2026-04-29

## Naming Patterns

**Files:**
- Use ordered numeric prefixes plus snake_case for workflow stage scripts under `scripts/rec/`, `scripts/dock/`, and `scripts/com/`, following `scripts/rec/0_prep.sh`, `scripts/dock/4_dock2com_2.py`, and `scripts/com/3_com_ana_trj.py`.
- Use hyphenated `aedmd-*` names for user-facing wrapper commands under `scripts/commands/`, following `scripts/commands/aedmd-preflight.sh`, `scripts/commands/aedmd-workspace-init.sh`, and `scripts/commands/aedmd-handoff-inspect.sh`.
- Use snake_case module names for reusable Python code under `scripts/agents/`, `scripts/infra/`, and `scripts/infra/plugins/`, following `scripts/agents/base.py`, `scripts/infra/checkpoint.py`, and `scripts/infra/plugins/group_id_check.py`.
- Keep compatibility wrapper modules short and name them after the imported target when numeric filenames need import-safe aliases, following `scripts/dock/dock2com_2_1.py` and `scripts/dock/gro_itp_to_mol2.py`.

**Functions:**
- Use snake_case for Python functions and methods, following `scripts/agents/__main__.py:load_config`, `scripts/infra/plugins/preflight.py:check_tool_availability`, and `scripts/rec/5_align.py:align_structures`.
- Use verb-led shell helper names for shared operations, following `scripts/infra/common.sh:require_file`, `scripts/infra/common.sh:submit_job`, and `scripts/commands/common.sh:dispatch_agent`.
- Reserve `main()` as the CLI boundary in executable Python files such as `scripts/agents/__main__.py`, `scripts/com/4_fp.py`, `scripts/infra/plugins/workspace_init.py`, and `scripts/rec/5_align.py`.

**Variables:**
- Use `UPPER_SNAKE_CASE` for shell globals, command metadata, and associative maps, following `scripts/run_pipeline.sh:STAGE_CMD`, `scripts/commands/common.sh:PROJECT_ROOT`, and `tests/phase06_integration_test.sh:TEST_WORKSPACE`.
- Use snake_case for Python locals, parameters, and instance attributes, following `scripts/agents/runner.py:command_list`, `scripts/agents/base.py:checkpoint_mgr`, and `scripts/infra/config.py:config_path`.
- Use upper-case constant registries and pattern sets in Python, following `scripts/agents/__init__.py:AGENT_REGISTRY`, `scripts/agents/utils/routing.py:STAGE_AGENT_MAP`, `scripts/infra/monitor.py:DEFAULT_PATTERN_REGISTRY`, and `scripts/infra/plugins/preflight.py:REQUIRED_TOOLS`.

**Types:**
- Use PascalCase for classes, dataclasses, and enums, following `scripts/agents/base.py:BaseAgent`, `scripts/agents/checker.py:CheckResult`, `scripts/agents/schemas/handoff.py:HandoffRecord`, and `scripts/infra/verification.py:VerificationGate`.
- Use upper-case enum members for fixed vocabularies, following `scripts/agents/schemas/handoff.py:HandoffStatus.SUCCESS`, `scripts/agents/schemas/state.py:WorkflowStage.COM_MMPBSA`, and `scripts/infra/verification.py:GateState.APPROVED`.

## Code Style

**Formatting:**
- No repo-wide formatter configuration is detected; `.editorconfig`, `pyproject.toml`, `ruff.toml`, `.flake8`, `.prettierrc*`, and `.eslintrc*` are absent from `/share/home/nglokwan/autoEnsmblDockMD`.
- Start executable shell scripts with `#!/usr/bin/env bash` and `set -euo pipefail`, following `scripts/run_pipeline.sh`, `scripts/commands/aedmd-preflight.sh`, `scripts/dock/2_gnina.sh`, and `tests/phase06_integration_test.sh`.
- Start executable Python modules with a module docstring; newer modules also place `from __future__ import annotations` immediately after it, following `scripts/agents/base.py`, `scripts/agents/orchestrator.py`, `scripts/infra/plugins/preflight.py`, and `scripts/com/4_fp.py`.
- Use 4-space indentation in Python and 2-space indentation in shell wrapper bodies and `case` arms, following `scripts/infra/config.py`, `scripts/infra/verification.py`, `scripts/commands/common.sh`, and `scripts/commands/aedmd-handoff-inspect.sh`.
- Prefer small top-level helpers plus a thin CLI entrypoint instead of inline procedural code, following `scripts/rec/5_align.py`, `scripts/com/4_fp.py`, `scripts/infra/plugins/group_id_check.py`, and `scripts/agents/runner.py`.

**Linting:**
- No centralized lint runner or config file is detected under `/share/home/nglokwan/autoEnsmblDockMD`.
- Preserve ShellCheck annotations for sourced files and dynamic source paths, following `scripts/run_pipeline.sh`, `scripts/dock/2_gnina.sh`, `scripts/infra/common.sh`, `scripts/commands/common.sh`, and `tests/phase06_integration_test.sh`.
- Keep Python type hints on public helpers, return values, and agent interfaces, following `scripts/agents/base.py`, `scripts/agents/checker.py`, `scripts/infra/monitor.py`, and `scripts/infra/plugins/workspace_init.py`.
- Preserve defensive `# pragma: no cover` comments where already used on import or exceptional boundaries, following `scripts/com/4_fp.py` and `scripts/infra/plugins/workspace_init.py`.

## Import Organization

**Order:**
1. Standard-library imports first, following `scripts/agents/__main__.py`, `scripts/infra/config.py`, and `scripts/infra/plugins/preflight.py`.
2. Third-party imports second, following `scripts/com/4_fp.py` (`matplotlib`, `numpy`, `MDAnalysis`) and `scripts/rec/5_align.py` (`MDAnalysis`).
3. Project-local imports last, rooted at `scripts.*`, following `scripts/agents/orchestrator.py`, `scripts/agents/base.py`, and `scripts/infra/plugins/group_id_check.py`.

**Path Aliases:**
- No path alias system is detected.
- Use package imports rooted at `scripts.*` for internal Python dependencies, following `scripts/agents/__main__.py`, `scripts/agents/utils/routing.py`, `scripts/infra/plugins/handoff_inspect.py`, and `work/test/infrastructure/test_infra.py`.
- Use explicit `sys.path.insert(...)` bootstrapping only in standalone entrypoints that may run outside package mode, following `scripts/infra/plugins/preflight.py`, `scripts/infra/plugins/workspace_init.py`, `scripts/infra/plugins/group_id_check.py`, and `work/test/infrastructure/test_infra.py`.

## Error Handling

**Patterns:**
- Raise specific Python exceptions at validation boundaries, following `scripts/infra/config.py` (`FileNotFoundError`), `scripts/rec/5_align.py` (`FileNotFoundError`, `ValueError`), `scripts/dock/4_dock2com_1.py` (`ValueError`, `RuntimeError`), and `scripts/com/4_fp.py` (`ValueError`).
- Return integer exit codes from CLI `main()` functions and terminate with `sys.exit(main())` or `raise SystemExit(main())`, following `scripts/agents/__main__.py`, `scripts/infra/plugins/preflight.py`, `scripts/com/4_fp.py`, and `scripts/dock/4_dock2com_2.py`.
- In shell, validate arguments eagerly and exit immediately on misuse, following `scripts/run_pipeline.sh`, `scripts/commands/common.sh:parse_flags`, `scripts/commands/aedmd-workspace-init.sh`, and `scripts/dock/2_gnina.sh`.
- Route agent outcomes through structured handoff statuses from `scripts/agents/schemas/handoff.py` and `scripts/commands/common.sh:check_handoff_result` instead of inventing ad hoc result formats.
- Reuse shared guard helpers from `scripts/infra/common.sh` and `scripts/commands/common.sh` instead of duplicating file, directory, command, or handoff checks in new shell scripts.

## Logging

**Framework:**
- Use `log_info`, `log_warn`, and `log_error` from `scripts/infra/common.sh` for shell scripts such as `scripts/run_pipeline.sh`, `scripts/dock/2_gnina.sh`, and `scripts/com/5_rerun_sel.sh`.
- Python CLI modules mostly use `print(...)` for user-facing output and JSON emission, following `scripts/agents/__main__.py`, `scripts/infra/plugins/preflight.py`, `scripts/infra/plugins/handoff_inspect.py`, and `scripts/com/4_fp.py`.
- Python `logging` is initialized in `scripts/agents/base.py`, but the dominant project pattern remains explicit CLI output plus persisted JSON records.

**Patterns:**
- Log stage starts, ends, and major actions in shell entrypoints, following `scripts/run_pipeline.sh`, `scripts/dock/2_gnina.sh`, `scripts/com/4_cal_fp.sh`, and `scripts/com/5_arc_sel.sh`.
- Print concrete artifact paths or summaries from Python CLIs, following `scripts/com/4_fp.py`, `scripts/rec/5_align.py`, and `scripts/dock/4_dock2com_1.py`.
- Emit machine-readable JSON for plugin and agent boundaries, following `scripts/infra/plugins/preflight.py`, `scripts/infra/plugins/workspace_init.py`, `scripts/infra/plugins/group_id_check.py`, and `scripts/agents/schemas/handoff.py`.

## Comments

**When to Comment:**
- Use module docstrings to explain scope and behavior, following `scripts/agents/base.py`, `scripts/infra/config.py`, `scripts/infra/verification.py`, `scripts/infra/plugins/handoff_inspect.py`, and `scripts/com/4_fp.py`.
- Use short inline comments for compatibility, environment, and operator context rather than narrative commentary, following `scripts/run_pipeline.sh`, `scripts/commands/common.sh`, `tests/phase06_integration_test.sh`, and `scripts/infra/common.sh`.
- Keep operator-facing help text in heredoc `usage()` functions for shell entrypoints, following `scripts/run_pipeline.sh`, `scripts/commands/common.sh`, `scripts/commands/aedmd-preflight.sh`, and `scripts/dock/2_gnina.sh`.

**JSDoc/TSDoc:**
- Not applicable; no JS/TS source tree is part of the project implementation.
- Use Python docstrings as the documentation standard in `scripts/agents/`, `scripts/infra/`, `scripts/infra/plugins/`, `scripts/com/`, `scripts/dock/`, and `scripts/rec/`.

## Function Design

**Size:**
- Keep reusable logic in named helpers and reserve `main()` for orchestration, following `scripts/rec/5_align.py`, `scripts/com/4_fp.py`, `scripts/infra/plugins/group_id_check.py`, and `scripts/agents/runner.py`.
- Larger single-file utilities are acceptable when split into focused helpers, following `scripts/infra/verification.py`, `scripts/infra/monitor.py`, and `scripts/infra/executor.py`.

**Parameters:**
- Prefer explicit long-form CLI flags with `argparse` in Python, following `scripts/agents/__main__.py`, `scripts/infra/config.py`, `scripts/infra/plugins/preflight.py`, and `scripts/com/4_fp.py`.
- Prefer `--config` plus targeted overrides in shell entrypoints, following `scripts/run_pipeline.sh`, `scripts/dock/2_gnina.sh`, `scripts/com/5_arc_sel.sh`, and the wrappers under `scripts/commands/`.
- Preserve existing backward-compatible aliases when they already exist, following `scripts/com/4_fp.py` (`--ligand-selection` / `--ligand_sel`, `--receptor-selection` / `--receptor_sel`).

**Return Values:**
- Return structured dictionaries, dataclasses, enums, or tuples from reusable Python helpers instead of formatted strings, following `scripts/agents/runner.py`, `scripts/agents/checker.py`, `scripts/agents/schemas/handoff.py`, `scripts/infra/verification.py`, and `scripts/rec/5_align.py`.
- Return integer status codes from CLI `main()` functions, following `scripts/agents/__main__.py`, `scripts/infra/plugins/workspace_init.py`, `scripts/infra/plugins/group_id_check.py`, and `scripts/com/4_fp.py`.
- In shell, communicate success or failure through exit status plus concise stdout/stderr, following `scripts/commands/common.sh:check_handoff_result` and `scripts/infra/common.sh:submit_job`.

## Module Design

**Exports:**
- Use package `__init__.py` files with explicit `__all__` exports for public APIs, following `scripts/infra/__init__.py`, `scripts/agents/__init__.py`, and `scripts/agents/schemas/__init__.py`.
- Keep CLI modules importable where practical so wrappers and tests can reuse their functions, following `scripts/com/4_fp.py`, `scripts/rec/5_align.py`, `scripts/infra/plugins/workspace_init.py`, and `scripts/infra/plugins/group_id_check.py`.

**Barrel Files:**
- Barrel-style re-export modules are used in `scripts/infra/__init__.py`, `scripts/agents/__init__.py`, and `scripts/agents/schemas/__init__.py`.
- Compatibility wrapper modules are part of the module design for numeric filenames, following `scripts/dock/dock2com_2_1.py` and `scripts/dock/gro_itp_to_mol2.py`.

---

*Convention analysis: 2026-04-29*
