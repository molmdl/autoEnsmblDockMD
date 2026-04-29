# Testing Patterns

**Analysis Date:** 2026-04-29

## Test Framework

**Runner:**
- No dedicated test runner such as `pytest`, `unittest` discovery, `jest`, or `vitest` is configured in `/share/home/nglokwan/autoEnsmblDockMD`; `pytest.ini`, `tox.ini`, `pyproject.toml`, `jest.config.*`, and `vitest.config.*` are not present.
- Committed automated checks use executable test scripts instead: `tests/phase06_integration_test.sh` for wrapper/plugin integration and `work/test/infrastructure/test_infra.py` for infrastructure integration.
- Config: Not detected.

**Assertion Library:**
- Shell assertions rely on exit codes, `test -f`, captured `$?`, and JSON field inspection with `jq` inside `tests/phase06_integration_test.sh`.
- Python assertions rely on built-in `assert` statements and plain exception handling inside `work/test/infrastructure/test_infra.py`.

**Run Commands:**
```bash
bash tests/phase06_integration_test.sh                                         # Run wrapper/plugin integration checks
python work/test/infrastructure/test_infra.py                                  # Run infrastructure integration checks
bash -n tests/phase06_integration_test.sh && python -m py_compile scripts/agents/*.py scripts/infra/*.py   # Syntax/smoke validation
```

## Test File Organization

**Location:**
- Shell integration tests live under `tests/`, currently `tests/phase06_integration_test.sh`.
- Python integration tests live in a disposable validation workspace under `work/test/infrastructure/`, currently `work/test/infrastructure/test_infra.py`.
- There is no co-located `test_*.py` tree under `scripts/`.

**Naming:**
- Shell integration tests use descriptive workflow names ending in `_integration_test.sh`, following `tests/phase06_integration_test.sh`.
- Python tests use `test_*.py` naming even without `pytest`, following `work/test/infrastructure/test_infra.py`.

**Structure:**
```text
tests/
└── phase06_integration_test.sh

work/test/infrastructure/
└── test_infra.py
```

## Test Structure

**Suite Organization:**
```python
def run_all_tests():
    tests = [
        test_config_to_executor_integration,
        test_checkpoint_to_verification_integration,
        test_executor_to_monitor_integration,
        test_state_persistence_across_operations,
    ]

    passed = 0
    failed = 0
    for test in tests:
        try:
            test()
            passed += 1
        except Exception as e:
            print(f"  ✗ FAILED: {e}")
            failed += 1
```
- The pattern above comes directly from `work/test/infrastructure/test_infra.py`.

**Patterns:**
- Setup pattern: shell tests create isolated temporary workspaces in `/tmp` and seed required files before invoking wrappers, following `tests/phase06_integration_test.sh`.
- Setup pattern: Python tests use `tempfile.NamedTemporaryFile(...)` and `tempfile.TemporaryDirectory()` to build disposable config, checkpoint, gate, and state fixtures in `work/test/infrastructure/test_infra.py`.
- Teardown pattern: shell tests register `trap cleanup EXIT` and delete temporary directories in `tests/phase06_integration_test.sh`; Python tests rely on `TemporaryDirectory()` context managers in `work/test/infrastructure/test_infra.py`.
- Assertion pattern: verify files, persisted state, enum outcomes, and handoff statuses instead of internal implementation details, following `tests/phase06_integration_test.sh` and `work/test/infrastructure/test_infra.py`.

## Mocking

**Framework:**
- None.

**Patterns:**
```bash
set +e
"${PROJECT_ROOT}/scripts/commands/aedmd-group-id-check.sh" --workspace "${TEST_WORKSPACE}"
GROUP_EXIT=$?
set -e

if [[ $GROUP_EXIT -ne 0 ]]; then
  echo "  ✓ Wrapper returned non-zero on missing index"
fi
```
- The dominant pattern in `tests/phase06_integration_test.sh` is to exercise real wrappers and inspect their real outputs rather than replace dependencies with mocks.

**What to Mock:**
- No formal project rule is documented.
- If new automated tests are added, mock only expensive or unavailable outer boundaries such as `sbatch`, `squeue`, `sacct`, `gmx`, `gnina`, and `gmx_MMPBSA` when a test cannot run against a real environment. Those boundaries are concentrated in `scripts/infra/common.sh`, `scripts/infra/executor.py`, and `scripts/dock/2_gnina.sh`.

**What NOT to Mock:**
- Do not mock the JSON handoff contract from `scripts/agents/schemas/handoff.py`; use real `HandoffRecord`-shaped payloads and on-disk `.handoffs/*.json` files.
- Do not mock file-backed state and gate behavior when validating orchestration flow; use the real implementations in `scripts/infra/state.py`, `scripts/infra/checkpoint.py`, and `scripts/infra/verification.py`.
- Do not bypass wrapper CLI parsing in `scripts/commands/common.sh`; invoke the real wrapper scripts under `scripts/commands/`.

## Fixtures and Factories

**Test Data:**
```python
with tempfile.NamedTemporaryFile(mode='w', suffix='.ini', delete=False) as f:
    f.write("""
[execution]
backend = auto

[slurm]
account = test_account
time_limit = 01:00:00
""")
```
- The pattern above comes from `work/test/infrastructure/test_infra.py` and is the main Python fixture style.
- Shell tests build fixture directories and copy the template config before execution, following `tests/phase06_integration_test.sh` with `${TEST_TEMPLATE}/config.ini` sourced from `scripts/config.ini.template`.

**Location:**
- Shell test fixtures are created dynamically under `/tmp` by `tests/phase06_integration_test.sh`.
- Python test fixtures are created dynamically by `tempfile` inside `work/test/infrastructure/test_infra.py`.
- Reusable static template input comes from `scripts/config.ini.template` and runtime wrapper code under `scripts/commands/`.

## Coverage

**Requirements:**
- No line-coverage or branch-coverage tool is configured.
- No `coverage.py`, `pytest-cov`, `nyc`, or equivalent config is detected in `/share/home/nglokwan/autoEnsmblDockMD`.
- Current automated coverage is behavior-based: `tests/phase06_integration_test.sh` exercises `scripts/commands/aedmd-workspace-init.sh`, `scripts/commands/aedmd-preflight.sh`, `scripts/commands/aedmd-handoff-inspect.sh`, `scripts/commands/aedmd-group-id-check.sh`, and `scripts/infra/plugins/conversion_cache.py`; `work/test/infrastructure/test_infra.py` exercises `scripts/infra/config.py`, `scripts/infra/checkpoint.py`, `scripts/infra/verification.py`, `scripts/infra/executor.py`, `scripts/infra/monitor.py`, and `scripts/infra/state.py` through public APIs.

**View Coverage:**
```bash
# Not applicable: no coverage report command is configured in this repository.
```

## Test Types

**Unit Tests:**
- No dedicated unit-test suite is detected.
- The closest unit-style coverage is function-level validation inside `work/test/infrastructure/test_infra.py`, where individual helper interactions are tested directly against `scripts.infra` exports from `scripts/infra/__init__.py`.

**Integration Tests:**
- `work/test/infrastructure/test_infra.py` is an integration-oriented Python harness that validates cross-module behavior among `ConfigManager`, `CheckpointManager`, `VerificationGate`, `LocalExecutor`, `LogMonitor`, and `AgentState`.
- `tests/phase06_integration_test.sh` is a shell integration harness that validates wrapper execution, handoff creation, failure handling, and plugin import behavior across `scripts/commands/` and `scripts/infra/plugins/`.

**E2E Tests:**
- `tests/phase06_integration_test.sh` is the current closest E2E check because it creates a workspace, runs multiple wrappers in sequence, inspects generated `.handoffs/*.json` files, and verifies a controlled failure path.
- No browser, UI, or full scientific-production E2E framework is configured.

## Common Patterns

**Async Testing:**
```python
gate = VerificationGate('docking', os.path.join(tmpdir, 'gates'))
gate.create_gate('Review docking results', output_paths=[str(ckpt_path)], metrics={'best_score': -8.5})
gate.approve(notes='Docking results acceptable')
assert gate.can_proceed()
```
- The pattern above comes from `work/test/infrastructure/test_infra.py` and represents stateful workflow progression testing rather than true async concurrency.

**Error Testing:**
```bash
if jq -r '.status' ".handoffs/group_id_check.json" | grep -q "failure"; then
  echo "  ✓ Handled missing index"
else
  echo "  ✗ Wrong status"
  exit 1
fi
```
- The pattern above comes from `tests/phase06_integration_test.sh` and shows the preferred style: trigger a real failure mode, then assert the wrapper exit code and persisted handoff status.

---

*Testing analysis: 2026-04-29*
