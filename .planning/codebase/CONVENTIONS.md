# Coding Conventions

**Analysis Date:** 2026-04-19

## Naming Patterns

**Files:**
- Use snake_case for Python modules and shell scripts, often with numeric stage prefixes for ordered pipeline steps: `scripts/rec/0_prep.sh`, `scripts/com/3_com_ana_trj.py`, `scripts/dock/4_dock2com_2.py`.
- Use hyphenated names for slash-command bridge scripts under `scripts/commands/`: `scripts/commands/rec-ensemble.sh`, `scripts/commands/debugger-diagnose.sh`.
- Use uppercase markdown names for planning/codebase reference docs: `.planning/codebase/CONVENTIONS.md`, `.planning/codebase/TESTING.md`.

**Functions:**
- Use snake_case for Python functions and methods: `scripts/rec/5_align.py:align_structures`, `scripts/agents/__main__.py:load_config`, `scripts/infra/config.py:get_execution_backend`.
- Use verb-led helper names in shell: `scripts/infra/common.sh:require_file`, `scripts/infra/common.sh:submit_job`, `scripts/commands/common.sh:parse_flags`.

**Variables:**
- Use `UPPER_SNAKE_CASE` for shell globals and constants: `scripts/run_pipeline.sh:STAGE_CMD`, `scripts/commands/common.sh:PROJECT_ROOT`.
- Use snake_case for Python locals and attributes: `scripts/agents/runner.py:command_list`, `scripts/com/3_com_ana_trj.py:contact_cutoff`.

**Types:**
- Use PascalCase for Python classes, dataclasses, and enums: `scripts/agents/base.py:BaseAgent`, `scripts/agents/checker.py:CheckResult`, `scripts/infra/verification.py:VerificationGate`, `scripts/agents/schemas/handoff.py:HandoffStatus`.

## Code Style

**Formatting:**
- Dedicated formatter config is not detected in the repository root (`.prettierrc`, `pyproject.toml`, `ruff.toml`, `black` config, and `eslint` config are not present).
- Follow the existing handwritten style in `scripts/**/*.py` and `scripts/**/*.sh`:
  - module docstring first in Python files such as `scripts/agents/base.py` and `scripts/com/4_fp.py`
  - shebang + `set -euo pipefail` first in shell files such as `scripts/run_pipeline.sh` and `scripts/com/3_ana.sh`
  - 4-space indentation in Python and 4-space indentation inside shell functions/case branches.

**Linting:**
- No repo-wide linter runner is detected.
- Use ShellCheck-compatible source annotations when sourcing dynamic paths: `scripts/run_pipeline.sh`, `scripts/infra/common.sh`, and most stage shell scripts include `# shellcheck source=/dev/null` or `# shellcheck disable=SC1090`.
- Use pragmatic type hints in Python. Examples: `scripts/com/3_com_ana_trj.py`, `scripts/dock/4_dock2com_2.py`, `scripts/agents/__main__.py`.

## Import Organization

**Order:**
1. Python standard library imports first: `argparse`, `json`, `sys`, `pathlib`, `typing` in `scripts/agents/__main__.py`.
2. Third-party imports second: `MDAnalysis`, `matplotlib`, `numpy` in `scripts/com/3_com_ana_trj.py` and `scripts/com/4_fp.py`.
3. Project imports last: `from scripts.agents ...`, `from scripts.infra ...` in `scripts/agents/*.py`.

**Path Aliases:**
- No path alias system is detected.
- Use package imports rooted at `scripts.*` for stable internal imports, as in `scripts/agents/orchestrator.py` and `scripts/agents/base.py`.
- When direct imports are brittle for standalone execution, use fallback dynamic loading instead of aliasing, as in `scripts/dock/4_dock2com_2.py`.

## Error Handling

**Patterns:**
- In Python libraries/helpers, raise specific exceptions close to the failure: `ValueError` and `FileNotFoundError` in `scripts/rec/5_align.py`, `scripts/dock/4_dock2com_2.py`, and `scripts/com/4_fp.py`.
- In Python CLIs, keep a `main()` function and terminate with `raise SystemExit(main())` or `sys.exit(main())`: `scripts/com/3_com_ana_trj.py`, `scripts/com/4_fp.py`, `scripts/agents/__main__.py`.
- In shell, fail fast with `set -euo pipefail` and explicit `log_error ...; exit 1` guards: `scripts/run_pipeline.sh`, `scripts/com/3_ana.sh`, `scripts/dock/3_dock_report.sh`.
- Validate inputs early with shared helpers such as `scripts/infra/common.sh:require_file`, `scripts/infra/common.sh:require_dir`, and `scripts/infra/common.sh:require_cmd`.

## Logging

**Framework:**
- Shell scripts use timestamped logging helpers from `scripts/infra/common.sh`: `log_info`, `log_warn`, `log_error`.
- Python code mostly uses stdout/stderr prints for CLI output; `logging` is initialized but lightly used in `scripts/agents/base.py` and `scripts/dock/0_gro_itp_to_mol2.py`.

**Patterns:**
- For shell entrypoints, log start/end and major stage actions: `scripts/run_pipeline.sh`, `scripts/com/3_ana.sh`, `scripts/infra/common.sh:submit_job`.
- For Python CLIs, print user-facing result paths and summaries, not verbose trace logs: `scripts/com/4_fp.py`, `scripts/rec/5_align.py`, `scripts/dock/4_dock2com_2.py`.
- For agent boundaries, return structured JSON handoffs instead of human prose where possible: `scripts/agents/base.py`, `scripts/agents/schemas/handoff.py`, `scripts/agents/__main__.py`.

## Comments

**When to Comment:**
- Use module and function docstrings to explain purpose and CLI behavior, as in `scripts/infra/config.py`, `scripts/infra/verification.py`, and `scripts/com/bypass_angle_type3.py`.
- Use short inline comments for operational context, not narration, such as shellcheck notes in `scripts/run_pipeline.sh` and reset notes in `scripts/com/3_com_ana_trj.py`.
- Preserve usage/help heredocs in shell scripts for operator-facing documentation: `scripts/com/3_ana.sh`, `scripts/dock/3_dock_report.sh`, `scripts/commands/common.sh`.

**JSDoc/TSDoc:**
- Not applicable; no JS/TS source tree is detected.
- Python docstrings are the standard documentation form across `scripts/agents/`, `scripts/infra/`, `scripts/com/`, `scripts/dock/`, and `scripts/rec/`.

## Function Design

**Size:**
- Keep reusable logic in small helper functions and reserve `main()` for orchestration. Examples: `scripts/rec/5_align.py:_resolve_structures` + `align_structures`, `scripts/com/3_com_ana_trj.py:compute_rmsd` + `analyze_trajectory`, `scripts/dock/4_dock2com_2.py:_detect_ff_includes` + `build_complex_topology`.
- Large single-file utilities are acceptable when grouped into clearly named helpers, as in `scripts/dock/0_gro_itp_to_mol2.py`.

**Parameters:**
- Prefer explicit CLI flags parsed by `argparse` in Python: `scripts/agents/__main__.py`, `scripts/com/4_fp.py`, `scripts/com/3_selection_defaults.py`.
- Prefer `--config` plus optional overrides in shell wrappers: `scripts/run_pipeline.sh`, `scripts/com/3_ana.sh`, `scripts/dock/3_dock_report.sh`.
- Preserve backward-compatible flag aliases when already present, such as `--ligand-selection` / `--ligand_sel` in `scripts/com/4_fp.py` and `--out` in `scripts/dock/0_gro_itp_to_mol2.py`.

**Return Values:**
- Python CLI `main()` functions usually return an integer exit code: `scripts/agents/__main__.py`, `scripts/infra/config.py`, `scripts/dock/4_dock2com_2.py`, `scripts/com/4_fp.py`.
- Data-oriented helpers return dictionaries, tuples, or dataclasses rather than ad hoc strings: `scripts/agents/runner.py`, `scripts/agents/checker.py`, `scripts/agents/schemas/handoff.py`, `scripts/com/3_com_ana_trj.py`.

## Module Design

**Exports:**
- Use package `__init__.py` files to expose public APIs with `__all__`: `scripts/agents/__init__.py`, `scripts/agents/schemas/__init__.py`, `scripts/infra/__init__.py`, `scripts/dock/dock2com_2_1.py`.
- Keep standalone CLIs importable as library modules where practical, especially analysis and conversion utilities: `scripts/com/4_fp.py`, `scripts/com/3_selection_defaults.py`, `scripts/dock/0_gro_itp_to_mol2.py`.

**Barrel Files:**
- Barrel-style re-export modules are used sparingly but intentionally in Python packages: `scripts/agents/__init__.py`, `scripts/agents/schemas/__init__.py`, `scripts/agents/utils/__init__.py`, `scripts/infra/__init__.py`.
- Compatibility wrapper modules are also used to stabilize imports for renamed numeric files: `scripts/dock/dock2com_2_1.py`, `scripts/dock/gro_itp_to_mol2.py`.

---

*Convention analysis: 2026-04-19*
