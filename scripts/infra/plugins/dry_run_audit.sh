#!/usr/bin/env bash

set -euo pipefail

echo "=== Phase 6 Automation Infrastructure Dry-Run Audit ==="
echo

missing_count=0
syntax_error_count=0
sdk_missing_count=0
doc_missing_count=0

echo "=== Python Plugins ==="
PLUGINS=(
  "scripts/infra/plugins/__init__.py"
  "scripts/infra/plugins/workspace_init.py"
  "scripts/infra/plugins/preflight.py"
  "scripts/infra/plugins/handoff_inspect.py"
  "scripts/infra/plugins/group_id_check.py"
  "scripts/infra/plugins/conversion_cache.py"
)

for plugin in "${PLUGINS[@]}"; do
  if [[ -f "$plugin" ]]; then
    echo "[OK] $plugin exists"
    if python3 -m py_compile "$plugin" 2>/dev/null; then
      echo "  ✓ Syntax valid"
    else
      echo "  ✗ Syntax error"
      syntax_error_count=$((syntax_error_count + 1))
    fi
  else
    echo "[MISSING] $plugin"
    missing_count=$((missing_count + 1))
  fi
done

echo
echo "=== Bash Wrapper Scripts ==="
WRAPPERS=(
  "scripts/commands/aedmd-workspace-init.sh"
  "scripts/commands/aedmd-preflight.sh"
  "scripts/commands/aedmd-handoff-inspect.sh"
  "scripts/commands/aedmd-group-id-check.sh"
)

for wrapper in "${WRAPPERS[@]}"; do
  if [[ -f "$wrapper" ]]; then
    echo "[OK] $wrapper exists"
    if bash -n "$wrapper" 2>/dev/null; then
      echo "  ✓ Syntax valid"
    else
      echo "  ✗ Syntax error"
      syntax_error_count=$((syntax_error_count + 1))
    fi
  else
    echo "[MISSING] $wrapper"
    missing_count=$((missing_count + 1))
  fi
done

echo
echo "=== OpenCode Plugins ==="
OC_PLUGINS=(
  ".opencode/plugins/workspace-init.js"
  ".opencode/plugins/preflight.js"
  ".opencode/plugins/handoff-inspect.js"
  ".opencode/plugins/group-id-check.js"
  ".opencode/plugins/conversion-cache.js"
)

for plugin in "${OC_PLUGINS[@]}"; do
  if [[ -f "$plugin" ]]; then
    echo "[OK] $plugin exists"
    if grep -q "definePlugin" "$plugin"; then
      echo "  ✓ Uses SDK"
    else
      echo "  ✗ Missing SDK"
      sdk_missing_count=$((sdk_missing_count + 1))
    fi
  else
    echo "[MISSING] $plugin"
    missing_count=$((missing_count + 1))
  fi
done

echo
echo "=== Skill Documentation ==="
SKILLS=(
  ".opencode/skills/aedmd-workspace-init/SKILL.md"
  ".opencode/skills/aedmd-preflight/SKILL.md"
  ".opencode/skills/aedmd-handoff-inspect/SKILL.md"
  ".opencode/skills/aedmd-group-id-check/SKILL.md"
  ".opencode/skills/aedmd-conversion-cache/SKILL.md"
)

for skill in "${SKILLS[@]}"; do
  if [[ -f "$skill" ]]; then
    echo "[OK] $skill exists"
    if grep -q "token_savings" "$skill"; then
      echo "  ✓ Documented"
    else
      echo "  ✗ Missing token_savings"
      doc_missing_count=$((doc_missing_count + 1))
    fi
  else
    echo "[MISSING] $skill"
    missing_count=$((missing_count + 1))
  fi
done

echo
echo "=== Audit Summary ==="
echo "Missing files: $missing_count"
echo "Syntax errors: $syntax_error_count"
echo "SDK markers missing: $sdk_missing_count"
echo "Skill metadata missing: $doc_missing_count"
echo
echo "Audit complete. Review output for missing files or syntax errors."
