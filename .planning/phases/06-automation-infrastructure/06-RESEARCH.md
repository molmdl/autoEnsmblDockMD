# Phase 6: Automation Infrastructure - Research

**Researched:** 2026-04-28
**Domain:** Python plugin architecture, workflow automation hooks, validation patterns
**Confidence:** MEDIUM

## Summary

This research investigates the technical foundations needed to implement automation hooks and plugins for the autoEnsmblDockMD workflow toolkit. The goal is to reduce token usage in repeated workflow-support operations by creating deterministic, machine-readable infrastructure components.

The codebase already has strong foundations: file-based handoff architecture, structured schemas for state/status, bash/Python hybrid infrastructure, and existing verification gates. Phase 6 builds on these patterns to add five automation hooks ranked by estimated token savings.

**Key findings:**
- Plugins should be simple Python modules in `scripts/infra/plugins/` discovered via direct imports, not dynamic plugin systems
- Existing handoff/verification infrastructure provides templates for machine-readable outputs
- Bash wrappers with `--dry-run` flags are the established pattern for read-only audits
- File-based caching should use per-workspace isolation with timestamp-based staleness detection
- Validation should follow existing three-tier severity: ERROR (block), WARNING (needs_review), INFO (log only)

**Primary recommendation:** Implement plugins as simple Python modules that emit HandoffRecord-compatible JSON outputs, callable from new bash wrapper commands following the `aedmd-*` namespace pattern. Avoid complex plugin discovery mechanisms; prefer explicit imports.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Python stdlib | 3.10+ | importlib, pathlib, json, hashlib | Built-in, no installation needed, sufficient for plugin needs |
| Existing handoff schema | - | HandoffRecord dataclass from `scripts/agents/schemas/handoff.py` | Already proven in production for file-based agent communication |
| Existing config loader | - | Bash INI parser from `scripts/infra/config_loader.sh` | Production-ready, supports environment overrides |
| Existing verification gate | - | VerificationGate class from `scripts/infra/verification.py` | Comprehensive human checkpoint system with state transitions |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| jq | 1.6+ | JSON querying in bash | Wrapper scripts parsing HandoffRecord outputs |
| MDAnalysis | 2.x | Workspace structure validation | When verifying trajectory/topology file consistency |
| hashlib (stdlib) | - | Content-hash caching | If timestamp-based staleness proves insufficient |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Simple module imports | Python entry_points plugin system | Entry points add packaging complexity; Phase 6 plugins are workflow-internal, not third-party |
| Per-workspace caches | Global shared cache | Workspace isolation prevents cross-contamination; aligns with existing workspace-copy pattern |
| HandoffRecord JSON | Custom validation format | Reusing proven schema reduces code; validators become first-class workflow stages |

**Installation:**
No new dependencies required. All automation hooks use existing conda environment packages.

## Architecture Patterns

### Recommended Project Structure
```
scripts/
├── infra/
│   ├── plugins/              # New: automation hook implementations
│   │   ├── __init__.py
│   │   ├── workspace_init.py
│   │   ├── preflight.py
│   │   ├── handoff_inspect.py
│   │   ├── group_id_check.py
│   │   └── conversion_cache.py
│   ├── common.sh             # Existing: bash utilities
│   ├── config_loader.sh      # Existing: INI parsing
│   └── verification.py       # Existing: gate system
├── commands/
│   ├── aedmd-workspace-init.sh    # New: wrapper
│   ├── aedmd-preflight.sh         # New: wrapper
│   ├── aedmd-handoff-inspect.sh   # New: wrapper
│   └── common.sh                  # Existing: dispatch utilities
```

### Pattern 1: Plugin as Standalone Python Module
**What:** Each automation hook is a standalone Python module with a `main()` function that emits HandoffRecord JSON to stdout.

**When to use:** All five automation hooks (workspace-init, preflight, handoff-inspector, group-ID-checker, cache-manager).

**Example:**
```python
# Source: Derived from scripts/agents/schemas/handoff.py pattern
#!/usr/bin/env python3
"""scripts/infra/plugins/preflight.py - Preflight validation plugin."""

import sys
from pathlib import Path
from scripts.agents.schemas.handoff import HandoffRecord, HandoffStatus

def validate_config(config_path: Path) -> HandoffRecord:
    """Validate config.ini completeness and consistency."""
    record = HandoffRecord(
        from_agent="preflight",
        to_agent="runner",
        stage="preflight_validation"
    )
    
    # Validation logic
    if not config_path.exists():
        record.status = HandoffStatus.FAILURE
        record.errors.append(f"Config file not found: {config_path}")
        record.recommendations.append("Create config.ini from scripts/config.ini.template")
    else:
        # Parse and validate sections
        record.status = HandoffStatus.SUCCESS
        record.data["validated_sections"] = ["general", "receptor", "docking"]
    
    return record

def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    args = parser.parse_args()
    
    record = validate_config(Path(args.config))
    print(record.to_dict())  # Emit JSON to stdout
    sys.exit(0 if record.status == HandoffStatus.SUCCESS else 1)

if __name__ == "__main__":
    main()
```

### Pattern 2: Bash Wrapper with Handoff Persistence
**What:** Bash wrapper sources `common.sh`, calls Python plugin, writes handoff JSON to `.handoffs/`, interprets status via `check_handoff_result`.

**When to use:** All new automation hook commands.

**Example:**
```bash
# Source: Derived from scripts/commands/aedmd-status.sh pattern
#!/usr/bin/env bash
# scripts/commands/aedmd-preflight.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

ensure_env
WORKSPACE_ROOT="$(find_workspace_root)"
cd "${WORKSPACE_ROOT}"
parse_flags "$@"

# Run plugin and capture output
PLUGIN="${PROJECT_ROOT}/scripts/infra/plugins/preflight.py"
HANDOFF_FILE=".handoffs/preflight_validation.json"

mkdir -p .handoffs
python3 "$PLUGIN" --config "$CONFIG" > "$HANDOFF_FILE"

# Interpret result using existing common.sh logic
check_handoff_result "preflight_validation"
```

### Pattern 3: Per-Workspace Cache Isolation
**What:** Cache files stored under `<workspace>/.cache/<cache_type>/` with timestamp/hash metadata.

**When to use:** Conversion cache manager for deterministic file transformations.

**Example:**
```python
# Source: Design pattern (no existing equivalent in codebase)
from pathlib import Path
import hashlib
import json

class ConversionCache:
    def __init__(self, workspace: Path, cache_type: str = "conversions"):
        self.cache_dir = workspace / ".cache" / cache_type
        self.cache_dir.mkdir(parents=True, exist_ok=True)
    
    def cache_key(self, source_path: Path, target_format: str) -> str:
        """Generate deterministic cache key."""
        key_input = f"{source_path.resolve()}:{target_format}"
        return hashlib.sha256(key_input.encode()).hexdigest()
    
    def get(self, source_path: Path, target_format: str) -> Path | None:
        """Retrieve cached conversion if fresh."""
        key = self.cache_key(source_path, target_format)
        cache_file = self.cache_dir / f"{key}.result"
        meta_file = self.cache_dir / f"{key}.meta"
        
        if not cache_file.exists() or not meta_file.exists():
            return None
        
        # Check staleness: cache older than source?
        meta = json.loads(meta_file.read_text())
        if source_path.stat().st_mtime > meta["source_mtime"]:
            return None  # Stale
        
        return cache_file
    
    def put(self, source_path: Path, target_format: str, result_path: Path):
        """Store conversion result in cache."""
        key = self.cache_key(source_path, target_format)
        cache_file = self.cache_dir / f"{key}.result"
        meta_file = self.cache_dir / f"{key}.meta"
        
        # Copy result to cache
        cache_file.write_bytes(result_path.read_bytes())
        
        # Write metadata
        meta = {
            "source_path": str(source_path.resolve()),
            "source_mtime": source_path.stat().st_mtime,
            "target_format": target_format,
            "cache_mtime": cache_file.stat().st_mtime
        }
        meta_file.write_text(json.dumps(meta, indent=2))
```

### Pattern 4: Dry-Run Audit Script
**What:** Read-only validation script that inspects workspace state and reports findings without modification.

**When to use:** Phase-end validation to verify all automation hooks are correctly integrated.

**Example:**
```bash
# Source: Derived from scripts/run_pipeline.sh --dry-run pattern
#!/usr/bin/env bash
# scripts/infra/plugins/dry_run_audit.sh

set -euo pipefail

echo "=== Phase 6 Automation Infrastructure Dry-Run Audit ==="
echo

# Check plugin files exist
PLUGINS=(
    "scripts/infra/plugins/workspace_init.py"
    "scripts/infra/plugins/preflight.py"
    "scripts/infra/plugins/handoff_inspect.py"
    "scripts/infra/plugins/group_id_check.py"
    "scripts/infra/plugins/conversion_cache.py"
)

for plugin in "${PLUGINS[@]}"; do
    if [[ -f "$plugin" ]]; then
        echo "[OK] $plugin exists"
        # Syntax check
        python3 -m py_compile "$plugin" 2>/dev/null && echo "  ✓ Syntax valid" || echo "  ✗ Syntax error"
    else
        echo "[MISSING] $plugin"
    fi
done

echo
echo "=== Wrapper Scripts ==="
WRAPPERS=(
    "scripts/commands/aedmd-workspace-init.sh"
    "scripts/commands/aedmd-preflight.sh"
    "scripts/commands/aedmd-handoff-inspect.sh"
)

for wrapper in "${WRAPPERS[@]}"; do
    if [[ -f "$wrapper" ]]; then
        echo "[OK] $wrapper exists"
        bash -n "$wrapper" && echo "  ✓ Syntax valid" || echo "  ✗ Syntax error"
    else
        echo "[MISSING] $wrapper"
    fi
done

echo
echo "=== Integration Test (Dry-Run) ==="
echo "[DRY-RUN] Would test: aedmd-workspace-init.sh --config config.ini.template --dry-run"
echo "[DRY-RUN] Would test: aedmd-preflight.sh --config work/test/config.ini --dry-run"
echo "[DRY-RUN] Would test: aedmd-handoff-inspect.sh --workspace work/test --dry-run"

echo
echo "Audit complete. Review output for missing files or syntax errors."
```

### Anti-Patterns to Avoid
- **Complex plugin discovery:** Don't use entry_points, namespace packages, or pkgutil.iter_modules for workflow-internal plugins. Simple imports suffice.
- **Global caches:** Don't store caches outside workspace directories. Cross-workspace contamination breaks reproducibility.
- **Custom handoff formats:** Don't invent new JSON schemas. Reuse HandoffRecord for consistency.
- **Silent failures in plugins:** Don't catch exceptions and return success. Plugins should fail loudly with clear HandoffRecord error messages.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Plugin discovery | Custom finder/registry | Direct imports (`from scripts.infra.plugins import preflight`) | Phase 6 plugins are workflow-internal; no third-party plugin ecosystem needed |
| JSON schema validation | Custom dict validation | HandoffRecord dataclass | Existing schema already handles status/errors/warnings/data; proven in production |
| File locking | Custom mutex implementation | `scripts.infra.verification.py` fcntl patterns | VerificationGate already implements atomic file operations with timeouts |
| Config parsing | New parser | `scripts.infra.config_loader.sh` | Existing bash INI parser handles environment overrides and normalization |
| Workspace detection | Recursive directory search | `find_workspace_root()` from `common.sh` | Already walks up tree looking for config.ini or .gsd-workspace marker |

**Key insight:** The codebase already provides file-based handoff infrastructure, config parsing, verification gates, and workspace detection. Phase 6 plugins should compose existing primitives, not replace them.

## Common Pitfalls

### Pitfall 1: Plugin Import Errors in Conda Environment
**What goes wrong:** Plugin imports fail because `PYTHONPATH` doesn't include project root.

**Why it happens:** Bash wrappers run plugins via `python3 script.py` without sourcing `setenv.sh`.

**How to avoid:** Always call `ensure_env` in bash wrappers before invoking plugins. Add project root to PYTHONPATH in setenv.sh if not already present.

**Warning signs:** `ModuleNotFoundError: No module named 'scripts'` when running plugins directly.

### Pitfall 2: Cache Staleness False Negatives
**What goes wrong:** Cache reports "fresh" when source file actually changed but mtime unchanged (e.g., `cp --preserve=timestamps` or time rewind).

**Why it happens:** Timestamp-based staleness detection assumes monotonic clocks and mtime updates on modification.

**How to avoid:** For critical conversions, add optional content-hash verification. Store both `source_mtime` and `source_sha256` in cache metadata.

**Warning signs:** Cached conversion used despite source file content change; workflow produces stale results.

### Pitfall 3: Handoff Status Vocabulary Drift
**What goes wrong:** Plugin emits status values not recognized by `check_handoff_result()` in `common.sh`.

**Why it happens:** Plugin author adds new status like "skipped" without updating `common.sh` parser.

**How to avoid:** Only use HandoffStatus enum values (`success`, `failure`, `needs_review`, `blocked`). If new status needed, update both HandoffStatus enum and `common.sh` case statement together.

**Warning signs:** `check_handoff_result` prints "Unknown handoff status" and returns exit code 1.

### Pitfall 4: Workspace Overwrite Without Confirmation
**What goes wrong:** `workspace-init` plugin silently overwrites existing workspace, destroying prior results.

**Why it happens:** Plugin doesn't check for existing workspace or asks for confirmation but runs non-interactively.

**How to avoid:** Check for existing `config.ini` or `.handoffs/` directory. Emit `HandoffStatus.BLOCKED` with error "Workspace already exists at <path>. Use --force to overwrite or specify different --workdir."

**Warning signs:** User reports lost simulation results after re-running workspace initialization.

### Pitfall 5: Preflight Validation Blocks Valid Edge Cases
**What goes wrong:** Preflight validation rejects config that would work but looks unusual (e.g., blind docking without reference ligand).

**Why it happens:** Validation rules too strict; don't account for mode-specific requirements.

**How to avoid:** Make preflight validation **mode-aware**. Parse `[docking] mode` first, then apply mode-specific rules. Emit WARNING for unusual configs, not ERROR.

**Warning signs:** Users bypass preflight validation entirely because it rejects valid configurations.

## Code Examples

Verified patterns from official sources:

### Workspace Initialization with Template Copy
```python
# Source: Derived from WORKFLOW.md workspace structure and work/input→work/test pattern
import shutil
from pathlib import Path
from scripts.agents.schemas.handoff import HandoffRecord, HandoffStatus

def initialize_workspace(template_dir: Path, target_dir: Path, force: bool = False) -> HandoffRecord:
    """Copy workspace template to target directory with validation."""
    record = HandoffRecord(
        from_agent="workspace_init",
        to_agent="runner",
        stage="init"
    )
    
    # Check for existing workspace
    if target_dir.exists() and not force:
        record.status = HandoffStatus.BLOCKED
        record.errors.append(f"Workspace exists: {target_dir}")
        record.recommendations.append("Use --force to overwrite or choose different target")
        return record
    
    # Validate template
    required_files = ["config.ini", "mdp/rec", "mdp/com"]
    missing = [f for f in required_files if not (template_dir / f).exists()]
    
    if missing:
        record.status = HandoffStatus.FAILURE
        record.errors.append(f"Template incomplete: missing {missing}")
        return record
    
    # Copy template
    if target_dir.exists():
        shutil.rmtree(target_dir)  # force=True
    shutil.copytree(template_dir, target_dir)
    
    record.status = HandoffStatus.SUCCESS
    record.data["workspace_path"] = str(target_dir.resolve())
    record.data["template_source"] = str(template_dir.resolve())
    record.metadata["created_dirs"] = ["rec", "dock", "com", "mdp"]
    
    return record
```

### Handoff Inspector with Status Normalization
```python
# Source: Derived from scripts/commands/aedmd-status.sh parsing logic
from pathlib import Path
import json
from scripts.agents.schemas.handoff import HandoffRecord, HandoffStatus

def inspect_latest_handoff(workspace: Path) -> HandoffRecord:
    """Parse latest handoff and provide next-action guidance."""
    record = HandoffRecord(
        from_agent="handoff_inspector",
        to_agent="orchestrator",
        stage="handoff_inspection"
    )
    
    handoff_dir = workspace / ".handoffs"
    
    if not handoff_dir.exists():
        record.status = HandoffStatus.SUCCESS
        record.warnings.append("No handoffs found (new workspace)")
        record.data["next_action"] = "Run workspace initialization"
        return record
    
    # Find latest handoff by timestamp
    handoffs = list(handoff_dir.glob("*.json"))
    if not handoffs:
        record.status = HandoffStatus.SUCCESS
        record.warnings.append("Handoff directory exists but empty")
        return record
    
    latest = max(handoffs, key=lambda p: p.stat().st_mtime)
    
    with open(latest) as f:
        data = json.load(f)
    
    # Normalize status vocabulary
    status_map = {
        "success": "SUCCESS",
        "failure": "FAILED",
        "needs_review": "NEEDS_REVIEW",
        "blocked": "BLOCKED"
    }
    
    stage = data.get("stage", "unknown")
    status = data.get("status", "unknown")
    normalized_status = status_map.get(status, "UNKNOWN")
    
    record.status = HandoffStatus.SUCCESS
    record.data["latest_stage"] = stage
    record.data["latest_status"] = normalized_status
    record.data["handoff_file"] = str(latest)
    
    # Provide next-action guidance
    if normalized_status == "SUCCESS":
        record.data["next_action"] = f"Stage {stage} completed successfully. Proceed to next stage."
    elif normalized_status == "NEEDS_REVIEW":
        record.data["next_action"] = f"Stage {stage} needs review. Check warnings and verify outputs."
        record.warnings.extend(data.get("warnings", []))
    else:
        record.data["next_action"] = f"Stage {stage} failed or blocked. Review errors and recommendations."
        record.errors.extend(data.get("errors", []))
        record.recommendations.extend(data.get("recommendations", []))
    
    return record
```

### Preflight Validation with Tiered Severity
```python
# Source: Derived from scripts/infra/config_loader.sh patterns and WORKFLOW.md requirements
from pathlib import Path
from scripts.agents.schemas.handoff import HandoffRecord, HandoffStatus

class PreflightValidator:
    def __init__(self, config_path: Path):
        self.config_path = config_path
        self.record = HandoffRecord(
            from_agent="preflight",
            to_agent="runner",
            stage="preflight_validation"
        )
    
    def validate(self) -> HandoffRecord:
        """Run all preflight checks with tiered severity."""
        self.check_config_exists()
        if self.record.status == HandoffStatus.FAILURE:
            return self.record
        
        self.check_required_sections()
        self.check_tool_availability()
        self.check_input_files()
        
        # Determine final status
        if self.record.errors:
            self.record.status = HandoffStatus.FAILURE
        elif self.record.warnings:
            self.record.status = HandoffStatus.NEEDS_REVIEW
        else:
            self.record.status = HandoffStatus.SUCCESS
        
        return self.record
    
    def check_config_exists(self):
        """ERROR severity: blocking failure."""
        if not self.config_path.exists():
            self.record.status = HandoffStatus.FAILURE
            self.record.errors.append(f"Config not found: {self.config_path}")
            self.record.recommendations.append("Create from scripts/config.ini.template")
    
    def check_required_sections(self):
        """ERROR severity: missing critical sections."""
        # Parse config (simplified - use actual config_loader in production)
        required = ["general", "receptor", "docking", "complex"]
        # ... parsing logic ...
        missing = ["docking"]  # Example
        
        if missing:
            self.record.errors.append(f"Missing required config sections: {missing}")
    
    def check_tool_availability(self):
        """WARNING severity: tools should exist but might be in non-standard paths."""
        tools = ["gmx", "gnina", "gmx_MMPBSA"]
        # ... which tool check logic ...
        missing_tools = ["gnina"]  # Example
        
        if missing_tools:
            self.record.warnings.append(f"Tools not in PATH: {missing_tools}")
            self.record.recommendations.append("Source scripts/setenv.sh or install missing tools")
    
    def check_input_files(self):
        """WARNING severity: inputs might be provided later."""
        # ... check receptor PDB, ligand files ...
        if not Path("work/input/receptor.pdb").exists():
            self.record.warnings.append("Receptor PDB not found in work/input/")
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual workspace setup | Template copy pattern | Phase 1-5 | Workspace-init plugin formalizes existing pattern |
| In-band validation in stage scripts | Separated preflight validation | Phase 6 (new) | Fail-fast before expensive computations |
| Ad-hoc handoff parsing | HandoffRecord schema | Phase 3-5 | Handoff-inspector plugin leverages proven schema |
| No caching | Per-workspace conversion cache | Phase 6 (new) | Deterministic transformations reused safely |
| Hardcoded group IDs | Dynamic resolution from index.ndx | Phase 5.1 | Group-ID-checker plugin prevents silent MM/PBSA errors |

**Deprecated/outdated:**
- Custom JSON schemas for validation outputs: Use HandoffRecord schema instead
- Global plugin registries: Phase 6 plugins are workflow-internal; direct imports preferred

## Open Questions

1. **Should conversion cache support cross-workspace deduplication?**
   - What we know: Per-workspace isolation prevents contamination
   - What's unclear: Whether storage overhead justifies isolated caches
   - Recommendation: Start with per-workspace; add optional shared cache in Phase 7 if storage becomes issue

2. **Should preflight validation cache results to avoid re-checking?**
   - What we know: Config changes invalidate preflight assumptions
   - What's unclear: Frequency of config changes vs preflight overhead
   - Recommendation: No caching initially; measure overhead in real workflows first

3. **How should workspace-init handle partial initialization failures?**
   - What we know: shutil.copytree is atomic (fails before partial copy)
   - What's unclear: Whether cleanup on failure is expected
   - Recommendation: Let copytree atomicity handle cleanup; emit clear FAILURE handoff

4. **Should dry-run audit be executable script or documentation checklist?**
   - What we know: Existing --dry-run pattern is executable
   - What's unclear: Whether audit needs to run automatically in CI
   - Recommendation: Executable script for consistency with codebase; supports CI integration later

## Sources

### Primary (HIGH confidence)
- `scripts/agents/schemas/handoff.py` - HandoffRecord schema definition and usage
- `scripts/commands/common.sh` - Handoff status interpretation and dispatch patterns
- `scripts/infra/verification.py` - VerificationGate implementation with atomic file operations
- `scripts/infra/config_loader.sh` - INI parsing and environment override patterns
- `WORKFLOW.md` - Workspace structure, stage execution order, dry-run conventions
- `AGENTS.md` - File-based handoff pattern, status vocabulary, wrapper exit codes

### Secondary (MEDIUM confidence)
- Python official docs: importlib, pathlib, json, hashlib standard library usage
- Python Packaging User Guide: plugin discovery patterns (entry_points, namespace packages, naming conventions)

### Tertiary (LOW confidence)
- None - all findings verified with existing codebase patterns or official documentation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Uses only existing codebase components and Python stdlib
- Architecture patterns: HIGH - Directly derived from proven codebase patterns (HandoffRecord, common.sh, verification.py)
- Cache invalidation strategy: MEDIUM - Timestamp-based staleness is proven but content-hash addition is untested
- Plugin discovery approach: HIGH - Rejecting complex discovery is informed by codebase simplicity and workflow-internal use case
- Dry-run audit implementation: MEDIUM - Pattern exists (--dry-run flags) but specific audit script is new

**Research date:** 2026-04-28
**Valid until:** 2026-05-28 (30 days - stable infrastructure domain)

---

## Implementation Priorities (Token Savings Ranking)

Based on quick-003 dry-run analysis:

| Hook | Est. Token Savings/Run | Implementation Complexity | Priority |
|------|----------------------:|---------------------------|----------|
| Preflight validation | 2,000–4,000 | Medium (mode-aware rules) | 1 |
| Workspace initialization | 1,500–3,000 | Low (template copy) | 2 |
| Handoff inspector | 1,200–2,500 | Low (JSON parsing) | 3 |
| Group ID consistency | 900–1,800 | Medium (index.ndx parsing) | 4 |
| Conversion cache | 1,000–2,000 | Medium (staleness detection) | 5 |

**Aggregate estimated savings:** 6,600–13,300 tokens per workflow run-support cycle

**Recommended implementation order:**
1. **Workspace-init** (lowest complexity, immediate value)
2. **Preflight** (highest savings, foundational for other hooks)
3. **Handoff-inspector** (enables debugging/resume workflows)
4. **Group-ID-checker** (prevents silent MM/PBSA failures)
5. **Conversion-cache** (optimization after others proven)
6. **Dry-run audit** (validation after all hooks implemented)
