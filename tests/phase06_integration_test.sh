#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Activate expected conda/project environment for wrappers/plugins.
# shellcheck disable=SC1091
source "${PROJECT_ROOT}/scripts/setenv.sh"

TEST_WORKSPACE="/tmp/phase06_test_$$"
TEST_TEMPLATE="/tmp/phase06_template_$$"

cleanup() {
  echo "Cleanup"
  rm -rf "${TEST_WORKSPACE}" "${TEST_TEMPLATE}"
}
trap cleanup EXIT

echo "=== Phase 6 Integration Test ==="

echo "Test 1: Workspace init"
mkdir -p "${TEST_TEMPLATE}/mdp/rec" "${TEST_TEMPLATE}/mdp/com"
cp "${PROJECT_ROOT}/scripts/config.ini.template" "${TEST_TEMPLATE}/config.ini"

"${PROJECT_ROOT}/scripts/commands/aedmd-workspace-init.sh" \
  --template "${TEST_TEMPLATE}" \
  --target "${TEST_WORKSPACE}" \
  --force

if test -f "${TEST_WORKSPACE}/config.ini"; then
  echo "  ✓ Workspace created"
else
  echo "  ✗ FAILED"
  exit 1
fi

echo "Test 2: Preflight validation"
cd "${TEST_WORKSPACE}"
"${PROJECT_ROOT}/scripts/commands/aedmd-preflight.sh" --config config.ini

if test -f ".handoffs/preflight_validation.json"; then
  echo "  ✓ Preflight ran"
else
  echo "  ✗ FAILED"
  exit 1
fi

echo "Test 3: Handoff inspection"
"${PROJECT_ROOT}/scripts/commands/aedmd-handoff-inspect.sh" --workspace "${TEST_WORKSPACE}"

if test -f ".handoffs/handoff_inspection.json"; then
  echo "  ✓ Inspector ran"
else
  echo "  ✗ FAILED"
  exit 1
fi

if jq -r '.data.latest_stage' ".handoffs/handoff_inspection.json" | grep -q "preflight"; then
  echo "  ✓ Detected preflight"
else
  echo "  ✗ Wrong stage"
  exit 1
fi

echo "Test 4: Group ID checker"
set +e
"${PROJECT_ROOT}/scripts/commands/aedmd-group-id-check.sh" --workspace "${TEST_WORKSPACE}"
GROUP_EXIT=$?
set -e

if [[ $GROUP_EXIT -ne 0 ]]; then
  echo "  ✓ Wrapper returned non-zero on missing index"
else
  echo "  ✗ Expected non-zero exit for missing index"
  exit 1
fi

if jq -r '.status' ".handoffs/group_id_check.json" | grep -q "failure"; then
  echo "  ✓ Handled missing index"
else
  echo "  ✗ Wrong status"
  exit 1
fi

echo "Test 5: ConversionCache import"
python3 -c "from scripts.infra.plugins.conversion_cache import ConversionCache; from pathlib import Path; ConversionCache(Path('/tmp')); print('OK')"
echo "  ✓ ConversionCache imports"

echo "All tests passed!"
