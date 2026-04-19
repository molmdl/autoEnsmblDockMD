# Testing Patterns

**Analysis Date:** 2026-04-19

## Test Framework

**Runner:**
- No dedicated automated test runner is detected. No `pytest.ini`, `tox.ini`, `noxfile.py`, `jest.config.*`, `vitest.config.*`, or `*.test.*` / `*.spec.*` files are present under `/share/home/nglokwan/autoEnsmblDockMD`.
- Validation is currently script-level and document-driven, centered on `.planning/phases/02-core-pipeline/02-VERIFICATION.md` and `.planning/phases/05-polish/05-12-e2e-test-report.md`.
- Config: Not detected.

**Assertion Library:**
- Not applicable as a formal framework.
- Verification relies on shell exit codes, syntax checks, help output, YAML/frontmatter validation, and checklist/report evidence in `.planning/phases/02-core-pipeline/02-VERIFICATION.md`, `.planning/phases/04-integration/04-VERIFICATION.md`, and `.planning/phases/05-polish/05-12-e2e-test-report.md`.

**Run Commands:**
```bash
for cmd in scripts/commands/*.sh; do bash -n "$cmd"; done     # Shell syntax checks
python -m py_compile scripts/com/3_com_ana_trj.py              # Python syntax check example
bash scripts/commands/status.sh --help                         # Command help smoke test (env required)
```

## Test File Organization

**Location:**
- No co-located unit/integration test tree is detected in `scripts/`, `tests/`, or `src/`.
- Validation artifacts live in planning docs such as `.planning/phases/02-core-pipeline/02-VERIFICATION.md`, `.planning/phases/04-integration/04-VERIFICATION.md`, and `.planning/phases/05-polish/05-12-e2e-test-report.md`.

**Naming:**
- Verification documents use `*-VERIFICATION.md`, `*-SUMMARY.md`, and `*-e2e-test-report.md` naming under `.planning/phases/**`.
- There are no `test_*.py`, `*.spec.py`, `*.test.sh`, or similar executable test module names.

**Structure:**
```text
.planning/phases/<phase>/<plan>-VERIFICATION.md
.planning/phases/<phase>/<plan>-e2e-test-report.md
```

## Test Structure

**Suite Organization:**
```bash
for cmd in scripts/commands/{rec-ensemble,dock-run,com-setup,com-md,com-mmpbsa,com-analyze,checker-validate,debugger-diagnose,orchestrator-resume,status}.sh; do
  bash -n "$cmd"
  bash "$cmd" --help
done
```

**Patterns:**
- Setup pattern: activate environment and source `scripts/setenv.sh` before command smoke tests, as documented in `README.md`, `AGENTS.md`, and `.planning/phases/05-polish/05-12-e2e-test-report.md`.
- Teardown pattern: no explicit teardown harness is detected; tests are mostly read-only syntax/help checks.
- Assertion pattern: treat zero exit status, parseable output, and expected artifact presence as success. Examples are summarized in `.planning/phases/02-core-pipeline/02-VERIFICATION.md` and `.planning/phases/05-polish/05-12-e2e-test-report.md`.

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
```
- The repository favors validating real outputs and handoff payloads over mocked dependencies. The example above is from `scripts/agents/checker.py` and shows the dominant style: inspect concrete execution results rather than simulated behavior.

**What to Mock:**
- Not documented in the codebase.
- Current practice suggests avoiding mocks and validating real files, logs, and CLI results from `scripts/run_pipeline.sh`, `scripts/commands/*.sh`, and `scripts/agents/*.py`.

**What NOT to Mock:**
- Do not replace handoff JSON, config parsing, or filesystem artifact checks when following existing patterns in `scripts/agents/schemas/handoff.py`, `scripts/infra/config.py`, and `scripts/agents/checker.py`.

## Fixtures and Factories

**Test Data:**
```bash
mkdir -p work/test
cp scripts/config.ini.template work/test/config.ini
```
- The canonical temporary workspace pattern comes from `README.md` and `AGENTS.md`.
- Reference artifacts also exist under `expected/` and `.reference/` for comparison-oriented work, as described in `AGENTS.md`.

**Location:**
- Working test workspace: `work/test/`
- User-provided inputs: `work/input/`
- Reference outputs/examples: `expected/` and `.reference/`

## Coverage

**Requirements:**
- No line or branch coverage tooling is enforced.
- The closest thing to coverage is scenario/checklist coverage recorded in `.planning/phases/02-core-pipeline/02-VERIFICATION.md` and `.planning/phases/05-polish/05-12-e2e-test-report.md`.

**View Coverage:**
```bash
grep -n "Quality Metrics" .planning/phases/02-core-pipeline/02-VERIFICATION.md
grep -n "Overall Results" .planning/phases/05-polish/05-12-e2e-test-report.md
```

## Test Types

**Unit Tests:**
- Not used as standalone files.
- Small helper functions are written in a unit-test-friendly style (`scripts/com/3_com_ana_trj.py`, `scripts/dock/4_dock2com_2.py`, `scripts/infra/config.py`), but automated unit suites are not present.

**Integration Tests:**
- Current integration testing is command and script verification:
  - `bash -n` for shell syntax
  - `python -m py_compile` for Python syntax
  - `--help` smoke tests for CLIs
  - command→skill cross-reference checks in `.planning/phases/05-polish/05-12-e2e-test-report.md`

**E2E Tests:**
- Documented, manual/semiautomated E2E validation is used.
- Primary reference: `.planning/phases/05-polish/05-12-e2e-test-report.md`.
- Supporting references: `.planning/phases/04-integration/04-VERIFICATION.md` and `.planning/phases/02-core-pipeline/02-VERIFICATION.md`.

## Common Patterns

**Async Testing:**
```python
gate = VerificationGate('docking', '.gates')
gate.create_gate('Review docking results', metadata={'ligand_count': 5})
gate.approve(notes='Looks good')
assert gate.can_proceed()
```
- The repository does not contain async test suites, but stateful workflow checks are illustrated with doctest-style examples in `scripts/infra/verification.py`.
- For job-like behavior, polling logic lives in `scripts/infra/common.sh:wait_job` rather than in automated async tests.

**Error Testing:**
```python
def check_log_errors(data: Dict[str, Any]) -> CheckResult:
    log_file = Path(data.get("log_file"))
    content = log_file.read_text(encoding="utf-8", errors="ignore")
    if "error" in content.lower() or "fatal" in content.lower():
        return CheckResult(level="error", message=f"Detected ERROR/FATAL patterns in log file: {log_file}")
```
- Error-focused validation inspects real logs and return codes instead of mock exceptions. See `scripts/agents/checker.py`, `scripts/agents/debugger.py`, and `scripts/infra/monitor.py`.

---

*Testing analysis: 2026-04-19*
