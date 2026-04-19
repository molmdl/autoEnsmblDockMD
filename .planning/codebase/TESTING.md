# Testing Patterns

**Analysis Date:** 2026-04-19

## Test Framework

**Runner:**
- No dedicated automated unit-test runner is detected in the project root or under `scripts/`; `pytest.ini`, `tox.ini`, `jest.config.*`, `vitest.config.*`, and `tests/` are not present under `/share/home/nglokwan/autoEnsmblDockMD`.
- Current verification is script-level and document-driven, centered on `.planning/phases/02-core-pipeline/02-VERIFICATION.md`, `.planning/phases/04-integration/04-VERIFICATION.md`, and `.planning/phases/05-polish/05-12-e2e-test-report.md`.
- Config: Not detected.

**Assertion Library:**
- Not applicable as a formal test framework.
- Current assertions rely on shell exit codes, Python syntax compilation, artifact existence, JSON handoff status values, and verification report checklists in `.planning/phases/02-core-pipeline/02-VERIFICATION.md`, `.planning/phases/04-integration/04-VERIFICATION.md`, and `.planning/phases/05-polish/05-12-e2e-test-report.md`.

**Run Commands:**
```bash
for cmd in scripts/commands/aedmd-*.sh; do bash -n "$cmd"; done   # Syntax-check command wrappers
python -m py_compile scripts/agents/*.py scripts/infra/*.py         # Syntax-check Python modules
source ./scripts/setenv.sh && bash scripts/commands/aedmd-status.sh --workdir work/my_project   # Wrapper smoke check after env init
```

## Test File Organization

**Location:**
- No co-located test tree is detected under `scripts/`, `tests/`, or `src/`.
- Validation evidence is stored as planning artifacts under `.planning/phases/**`, especially `.planning/phases/02-core-pipeline/02-VERIFICATION.md`, `.planning/phases/04-integration/04-VERIFICATION.md`, and `.planning/phases/05-polish/05-12-e2e-test-report.md`.

**Naming:**
- Verification documents use `*-VERIFICATION.md`, `*-SUMMARY.md`, and `*-e2e-test-report.md` naming under `.planning/phases/**`.
- No `test_*.py`, `*.spec.py`, `*.test.sh`, or `*.test.ts` files are present in the project code.

**Structure:**
```text
.planning/phases/<phase>/<plan>-VERIFICATION.md
.planning/phases/<phase>/<plan>-SUMMARY.md
.planning/phases/<phase>/<plan>-e2e-test-report.md
```

## Test Structure

**Suite Organization:**
```bash
for cmd in scripts/commands/aedmd-{rec-ensemble,dock-run,com-setup,com-md,com-mmpbsa,com-analyze,checker-validate,debugger-diagnose,orchestrator-resume,status}.sh; do
  bash -n "$cmd"
done
```

**Patterns:**
- Setup pattern: initialize the environment with `source ./scripts/setenv.sh` before running wrapper smoke checks, as documented in `README.md`, `AGENTS.md`, and `docs/GUIDE.md`.
- Setup pattern: create a disposable workspace from `scripts/config.ini.template`, following the workspace guidance in `README.md` and `AGENTS.md`.
- Teardown pattern: no centralized teardown harness is detected; current checks are mostly syntax/help/report validation and read-only inspection.
- Assertion pattern: treat a zero exit code, valid syntax, expected artifact presence, and correct handoff status strings (`success`, `needs_review`, `failure`, `blocked`) from `scripts/commands/common.sh` and `scripts/agents/schemas/handoff.py` as the primary pass/fail signals.
- Regression pattern after the namespace fixes: verify documentation and wrappers use the `aedmd-*` command names shown in `README.md`, `docs/EXPERIMENTAL.md`, `docs/GUIDE.md`, `AGENTS.md`, and `.opencode/docs/AGENT-WORKFLOW.md`.

## Mocking

**Framework:**
- None detected.

**Patterns:**
```python
def check_return_code(data: Dict[str, Any]) -> CheckResult:
    returncode = data.get("returncode")
    if returncode is None:
        return CheckResult(level="warning", message="returncode not provided for validation.")
    if int(returncode) != 0:
        return CheckResult(level="error", message=f"Stage returned non-zero exit code: {returncode}")
    return CheckResult(level="info", message="Return code indicates success.")
```
- The dominant pattern is to validate concrete execution results, logs, files, and handoff payloads rather than replacing dependencies with mocks. The example above comes from `scripts/agents/checker.py`.

**What to Mock:**
- Not documented as a project convention.
- If extra tests are added, mock only thin outer boundaries that are expensive or unavailable in CI, such as external executables (`gmx`, `gnina`, `gmx_MMPBSA`) invoked through `scripts/infra/common.sh` or `scripts/agents/debugger.py`.

**What NOT to Mock:**
- Do not mock the JSON handoff shape defined in `scripts/agents/schemas/handoff.py`; tests should use real `HandoffRecord` payloads.
- Do not mock gate state files when validating workflow gating; use the real file-backed behavior in `scripts/infra/verification.py`.
- Do not replace wrapper flag handling with synthetic shortcuts; exercise `scripts/commands/common.sh:parse_flags` and the namespaced wrappers in `scripts/commands/aedmd-*.sh` directly.

## Fixtures and Factories

**Test Data:**
```bash
mkdir -p work/test
cp scripts/config.ini.template work/test/config.ini
```
- Use `work/test/` as the disposable validation workspace, consistent with `AGENTS.md`.
- Use `work/input/` for user-provided inputs and compare against example/reference outputs in `expected/` and `.reference/`, as documented in `AGENTS.md`.

**Location:**
- Working validation workspace: `work/test/`
- User inputs: `work/input/`
- Reference outputs and examples: `expected/` and `.reference/`

## Coverage

**Requirements:**
- No line-coverage or branch-coverage tooling is enforced.
- Current “coverage” is scenario coverage captured in `.planning/phases/02-core-pipeline/02-VERIFICATION.md`, `.planning/phases/04-integration/04-VERIFICATION.md`, and `.planning/phases/05-polish/05-12-e2e-test-report.md`.
- The most explicit command-wrapper regression coverage currently checks syntax, help-path behavior, YAML frontmatter, and command→skill cross-reference chains in `.planning/phases/05-polish/05-12-e2e-test-report.md`.

**View Coverage:**
```bash
rg -n "L1 Syntax|L2 Help|L3 YAML|L4 Cross-ref|Overall Results" .planning/phases/05-polish/05-12-e2e-test-report.md
```

## Test Types

**Unit Tests:**
- Not used as standalone files.
- Python helpers are still written in a unit-testable style in `scripts/agents/checker.py`, `scripts/agents/runner.py`, `scripts/infra/config.py`, `scripts/infra/verification.py`, `scripts/com/4_fp.py`, and `scripts/dock/4_dock2com_2.py`.

**Integration Tests:**
- Current integration testing is command and module verification:
  - `bash -n` for `scripts/commands/aedmd-*.sh` and `scripts/commands/common.sh`
  - `python -m py_compile` for Python modules under `scripts/agents/` and `scripts/infra/`
  - `--help` smoke checks for namespaced wrappers after environment initialization
  - command→skill→docs cross-reference checks in `.planning/phases/05-polish/05-12-e2e-test-report.md`

**E2E Tests:**
- Manual or semi-automated workflow validation is the current E2E strategy.
- Primary reference: `.planning/phases/05-polish/05-12-e2e-test-report.md`.
- Supporting references: `.planning/phases/02-core-pipeline/02-VERIFICATION.md` and `.planning/phases/04-integration/04-VERIFICATION.md`.
- Environment-sensitive checks currently acknowledge the `ensure_env` → `scripts/setenv.sh` path in `scripts/commands/common.sh` and `scripts/setenv.sh`; this is why wrapper `--help` checks are recorded as `ENV_GATE` in `.planning/phases/05-polish/05-12-e2e-test-report.md` when Conda is not initialized.

## Common Patterns

**Async Testing:**
```python
gate = VerificationGate("docking", ".gates")
gate.create_gate("Review docking results", metadata={"ligand_count": 5})
gate.approve(notes="Looks good")
assert gate.can_proceed()
```
- There is no async test runner, but stateful workflow behavior is illustrated with doctest-style examples in `scripts/infra/verification.py`.
- For job-like waiting behavior, runtime polling lives in `scripts/infra/common.sh:wait_job`; this behavior is not covered by an automated async test suite.

**Error Testing:**
```python
def check_log_errors(data: Dict[str, Any]) -> CheckResult:
    log_file = Path(data.get("log_file"))
    content = log_file.read_text(encoding="utf-8", errors="ignore")
    if "error" in content.lower() or "fatal" in content.lower():
        return CheckResult(level="error", message=f"Detected ERROR/FATAL patterns in log file: {log_file}")
```
- Error-oriented validation is built around real logs, return codes, and persisted artifacts in `scripts/agents/checker.py`, `scripts/agents/debugger.py`, `scripts/infra/monitor.py`, and `scripts/commands/common.sh`.

---

*Testing analysis: 2026-04-19*
