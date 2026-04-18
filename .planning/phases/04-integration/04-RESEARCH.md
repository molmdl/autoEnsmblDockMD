# Phase 4: Integration - Research

**Researched:** 2026-04-19
**Domain:** Agent integration, slash commands, agent skills, error/feedback patterns
**Confidence:** HIGH

## Summary

Phase 4 integrates Phase 2 scripts and Phase 3 agents through slash commands and loadable agent skills. Research focused on three key areas flagged in STATE.md: (1) agent skills format standards, (2) error/feedback flow conventions, and (3) slash command mechanisms in OpenCode/VS Code Copilot.

**Key findings:**
- Agent Skills is an open standard (agentskills.io) using Markdown files with YAML frontmatter, designed for progressive disclosure and portability across AI tools
- VS Code Copilot discovers skills from `.github/skills/`, `.claude/skills/`, `.agents/skills/` (workspace) and `~/.copilot/skills/` (user profile)
- Error/feedback uses structured JSON handoff records (already implemented in Phase 3) with status enums, warnings, errors, and recommendations
- OpenCode integrates with VS Code Copilot's slash command system (though specific .opencode/commands/ format not verified in documentation)

**Primary recommendation:** Use Agent Skills standard format for skill files, leverage existing HandoffRecord schema for error reporting, and create shell script wrappers as the bridge between slash commands and Python agent CLI.

## Standard Stack

The established patterns for agent integration in VS Code Copilot ecosystem:

### Core
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Agent Skills | agentskills.io spec | Runtime-loadable capability bundles | Open standard, works across VS Code, Copilot CLI, Copilot cloud agent |
| YAML Frontmatter | YAML 1.2 | Skill metadata (name, description, etc.) | Minimal parsing, standard across all skill systems |
| Markdown | CommonMark | Skill instruction body | Human-readable, AI-friendly, universal support |
| JSON | RFC 8259 | Handoff records & structured data | Language-agnostic, standard for agent communication |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Bash shell scripts | 4.0+ | Command dispatch layer | Bridge slash commands to Python agents |
| Python dataclasses | 3.10+ | Structured schemas | Already used in Phase 3 (HandoffRecord) |
| INI config | stdlib | Parameter configuration | Already established in Phase 2 |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Agent Skills (Markdown+YAML) | Custom JSON schema | Skills format is portable; custom schema locks to this project only |
| Shell script bridge | Direct Python invocation | Shell scripts provide better workspace detection, environment setup, consistent CLI interface |
| JSON handoffs | Plain text logs | JSON is structured, parseable, enables programmatic error handling |

**Installation:**
```bash
# No additional dependencies beyond existing Phase 3 stack
# Agent Skills format uses standard Markdown/YAML parsing
# Handoff records use Python stdlib json module
```

## Architecture Patterns

### Recommended Project Structure
```
.github/
├── skills/                # Workspace skills (discovered by VS Code Copilot)
│   ├── dock-run/
│   │   ├── SKILL.md      # Metadata + instructions
│   │   └── examples/     # Optional: example configs
│   ├── rec-ensemble/
│   │   └── SKILL.md
│   └── ...
└── commands/              # Slash command definitions (if needed for OpenCode)
    ├── rec-ensemble.md
    └── dock-run.md

scripts/
├── agents/                # Phase 3 agents (existing)
│   ├── runner.py
│   ├── orchestrator.py
│   └── ...
├── commands/              # NEW: Slash command bridge scripts
│   ├── rec-ensemble.sh
│   ├── dock-run.sh
│   └── common.sh         # Shared command utilities
└── rec/, dock/, com/      # Phase 2 scripts (existing)

.run_logs/                 # Command execution logs
.handoffs/                 # JSON handoff records
```

### Pattern 1: Skill Progressive Disclosure
**What:** Skills load in three stages: (1) metadata at startup, (2) instructions when activated, (3) resources on-demand
**When to use:** All skill files
**Example:**
```markdown
---
name: dock-run
description: Execute ensemble docking with gnina (targeted or blind mode). Use when preparing docking runs or when user mentions docking, gnina, or protein-ligand binding predictions.
---

# Docking Execution Skill

## When to use this skill
- User requests docking execution
- Docking configuration is prepared
- Receptor ensemble is ready

## Instructions
1. Validate docking configuration exists
2. Check receptor ensemble availability
3. Dispatch to runner agent with dock_run stage
4. Monitor for completion or errors

## Configuration
See [example config](./examples/dock.ini) for reference parameters.
```

**Key insight:** Keep SKILL.md body under 500 lines (~5000 tokens). Move detailed reference to separate files loaded on-demand.

### Pattern 2: Shell Script Command Bridge
**What:** Shell scripts wrap Python agent CLI, handle workspace detection, environment setup, and parameter validation
**When to use:** All slash commands
**Example:**
```bash
#!/usr/bin/env bash
# scripts/commands/dock-run.sh - Bridge for /dock-run slash command

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"  # Load shared utilities

# Workspace detection
WORKSPACE_ROOT="$(find_workspace_root)"
cd "${WORKSPACE_ROOT}"

# Environment setup
source scripts/setenv.sh

# Parse flags and build handoff
CONFIG="${WORKSPACE_ROOT}/config.ini"
PARAMS="{}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --config) CONFIG="$2"; shift 2 ;;
    --autobox-add) PARAMS=$(echo "$PARAMS" | jq --arg v "$2" '.autobox_add = ($v | tonumber)'); shift 2 ;;
    *) shift ;;
  esac
done

# Dispatch to runner agent
python -m scripts.agents \
  --agent runner \
  --input <(cat <<EOF
{
  "stage": "dock_run",
  "config": "$CONFIG",
  "params": $PARAMS
}
EOF
)
```

### Pattern 3: Structured Handoff Records
**What:** JSON handoff payloads with status, data, warnings, errors, recommendations
**When to use:** All agent-to-agent communication, command result reporting
**Example:**
```python
# Source: Existing Phase 3 implementation (scripts/agents/schemas/handoff.py)
from scripts.agents.schemas.handoff import HandoffRecord, HandoffStatus

# Success case
handoff = HandoffRecord(
    from_agent="runner",
    to_agent="checker",
    status=HandoffStatus.SUCCESS,
    stage="dock_run",
    data={"output_dir": "work/dock/output", "poses_count": 10},
    warnings=["Ligand RMSD exceeds 2.0 Å for pose 5"],
    recommendations=["Run checker-validate to review pose quality"]
)
handoff.save(".handoffs/dock_run.json")

# Failure case
handoff = HandoffRecord(
    from_agent="runner",
    to_agent="debugger",
    status=HandoffStatus.FAILURE,
    stage="dock_run",
    errors=["gnina execution failed: autobox center not found"],
    recommendations=["Check receptor PDB file format", "Run debugger-diagnose"]
)
```

**Key insight:** Status enum provides clear semantics: SUCCESS, FAILURE, NEEDS_REVIEW, BLOCKED. Errors list is machine-parseable for debugging automation.

### Anti-Patterns to Avoid
- **Hardcoded workspace paths:** Always detect CWD or use --workspace flag
- **Mixing command and agent logic:** Commands dispatch, agents execute; no business logic in shell scripts
- **Large monolithic skills:** Split detailed reference material into separate files (progressive disclosure)
- **Plain text error reporting:** Use structured JSON handoffs for machine-readable errors

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Skill metadata parsing | Custom parser | agentskills.io spec + stdlib YAML | Standard format, validation tools exist (`skills-ref validate`) |
| Command parameter handling | Ad-hoc argument parsing | Bash getopts + jq | Battle-tested, handles edge cases (spaces, quotes, etc.) |
| Agent communication | Custom RPC | JSON handoff files + status enum | Atomic writes, persistent records, human-debuggable |
| Workspace detection | `pwd` + assumptions | Git root detection or config file search | Handles monorepos, symlinks, nested workspaces |
| Environment activation | Inline `conda activate` | Source `scripts/setenv.sh` | Centralized, tested, handles module loading on HPC |

**Key insight:** Agent Skills is an open standard with validation tooling. Custom skill formats fragment the ecosystem and reduce portability.

## Common Pitfalls

### Pitfall 1: Skill Name Mismatch
**What goes wrong:** Skill `name` field doesn't match parent directory name; skill silently fails to load
**Why it happens:** Validation happens at runtime; no immediate feedback during development
**How to avoid:** Use `skills-ref validate` tool before committing; enforce in pre-commit hook
**Warning signs:** Skill doesn't appear in `/` menu; agent never loads skill content

### Pitfall 2: Overly Broad Skill Descriptions
**What goes wrong:** Agent loads irrelevant skills, wasting context
**Why it happens:** Description is vague ("helps with docking") instead of specific ("execute gnina targeted/blind docking")
**How to avoid:** Include specific keywords and use cases in description; test by searching for skill by task
**Warning signs:** Agent loads multiple skills for same task; context budget exhausted early

### Pitfall 3: Non-Atomic Handoff Writes
**What goes wrong:** Handoff file corrupted if process interrupted; downstream agent reads partial JSON
**Why it happens:** Direct `open(path, 'w')` without atomic write (write-to-temp, rename)
**How to avoid:** Use `HandoffRecord.save()` method (already implements atomic write)
**Warning signs:** JSON parse errors in handoff loading; intermittent agent failures

### Pitfall 4: Command Script PATH Assumptions
**What goes wrong:** Shell script can't find Python module or helper script; breaks in production
**Why it happens:** Development uses virtualenv with scripts on PATH; production doesn't
**How to avoid:** Always resolve script directory (`SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`) and use absolute paths
**Warning signs:** Works locally, fails in CI/CD; fails when invoked from different directory

### Pitfall 5: Missing Error Context in Handoffs
**What goes wrong:** Debugger agent can't diagnose failure; user sees "script failed" with no actionable info
**Why it happens:** Errors list contains only exit codes or generic messages
**How to avoid:** Capture stderr, include relevant config values, suggest next debugging steps in recommendations
**Warning signs:** Repeated debugger escalations for same issue; user frustration with vague errors

## Code Examples

Verified patterns from official sources and existing codebase:

### Complete Skill File (from agentskills.io spec)
```markdown
---
name: dock-run
description: Execute ensemble docking with gnina (targeted or blind mode). Use when preparing docking runs or when user mentions docking, gnina, or protein-ligand binding predictions.
license: MIT
compatibility: Requires gnina, gromacs 2022+, python 3.10+
metadata:
  author: autoEnsmblDockMD
  version: "1.0"
---

# Docking Execution Skill

Execute gnina docking against receptor ensemble conformations.

## When to use this skill
- User requests docking execution
- Docking configuration prepared in config.ini
- Receptor ensemble available in work/rec/aligned/

## Workflow
1. Validate configuration: `[dock]` section required in config.ini
2. Check receptor ensemble: aligned PDB files exist
3. Invoke `/dock-run` command or dispatch to runner agent
4. Monitor output in .run_logs/dock_run.log
5. Review handoff in .handoffs/dock_run.json

## Configuration Example
See [example dock.ini](./examples/dock.ini) for reference parameters:
- autobox_add, exhaustiveness, num_modes
- mode (targeted/blind), pocket center/size

## Troubleshooting
- **No receptor files:** Run `/rec-ensemble` first
- **Config missing [dock] section:** Copy from config.ini.template
- **gnina not found:** Source scripts/setenv.sh to load modules
```

### Command Bridge Script Template
```bash
#!/usr/bin/env bash
# Source: Pattern derived from Phase 2 scripts structure + VS Code Copilot conventions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Load shared utilities
source "${SCRIPT_DIR}/common.sh"

# Workspace detection
WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(find_workspace_root)}"
cd "${WORKSPACE_ROOT}"

# Environment setup
if [[ -f "${PROJECT_ROOT}/scripts/setenv.sh" ]]; then
  source "${PROJECT_ROOT}/scripts/setenv.sh"
fi

# Parse CLI flags
CONFIG="${WORKSPACE_ROOT}/config.ini"
EXTRA_PARAMS="{}"
VERBOSE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config) CONFIG="$2"; shift 2 ;;
    --verbose) VERBOSE=true; shift ;;
    --*) 
      KEY="${1#--}"
      VALUE="$2"
      EXTRA_PARAMS=$(echo "$EXTRA_PARAMS" | jq --arg k "$KEY" --arg v "$VALUE" '.[$k] = $v')
      shift 2
      ;;
    *) shift ;;
  esac
done

# Validate prerequisites
if [[ ! -f "$CONFIG" ]]; then
  echo "ERROR: Config file not found: $CONFIG" >&2
  echo "TIP: Copy from ${PROJECT_ROOT}/config.ini.template" >&2
  exit 1
fi

# Build handoff input
HANDOFF_INPUT=$(cat <<EOF
{
  "stage": "STAGE_NAME_HERE",
  "config": "$CONFIG",
  "params": $EXTRA_PARAMS
}
EOF
)

# Dispatch to runner agent
if [[ "$VERBOSE" == "true" ]]; then
  echo "Dispatching to runner agent..." >&2
  echo "$HANDOFF_INPUT" | jq . >&2
fi

python -m scripts.agents \
  --agent runner \
  --input <(echo "$HANDOFF_INPUT")

# Check result
HANDOFF_FILE="${WORKSPACE_ROOT}/.handoffs/STAGE_NAME_HERE.json"
if [[ -f "$HANDOFF_FILE" ]]; then
  STATUS=$(jq -r '.status' "$HANDOFF_FILE")
  
  if [[ "$STATUS" == "failure" ]]; then
    echo "ERROR: Stage failed. Details:" >&2
    jq -r '.errors[]' "$HANDOFF_FILE" >&2
    echo "" >&2
    echo "Recommendations:" >&2
    jq -r '.recommendations[]' "$HANDOFF_FILE" >&2
    exit 1
  elif [[ "$STATUS" == "needs_review" ]]; then
    echo "WARNING: Stage requires review:" >&2
    jq -r '.warnings[]' "$HANDOFF_FILE" >&2
    exit 2
  fi
fi
```

### Handoff Record Usage (from Phase 3 implementation)
```python
# Source: scripts/agents/schemas/handoff.py
from scripts.agents.schemas.handoff import HandoffRecord, HandoffStatus

# Runner agent creates handoff after script execution
def execute_stage(stage: str, script: str, params: dict) -> HandoffRecord:
    try:
        result = subprocess.run([script], **params, capture_output=True, text=True)
        
        if result.returncode == 0:
            return HandoffRecord(
                from_agent="runner",
                to_agent="checker",
                status=HandoffStatus.SUCCESS,
                stage=stage,
                data={"output": result.stdout},
                warnings=parse_warnings(result.stderr),
                recommendations=["Run checker-validate for quality assurance"]
            )
        else:
            return HandoffRecord(
                from_agent="runner",
                to_agent="debugger",
                status=HandoffStatus.FAILURE,
                stage=stage,
                errors=[f"Script exit code {result.returncode}", result.stderr],
                recommendations=[
                    "Check log file in .run_logs/",
                    "Run debugger-diagnose for detailed analysis"
                ]
            )
    except Exception as e:
        return HandoffRecord(
            from_agent="runner",
            to_agent="debugger",
            status=HandoffStatus.FAILURE,
            stage=stage,
            errors=[str(e)],
            recommendations=["Check environment setup", "Verify script permissions"]
        )

# Save handoff for downstream consumption
handoff.save(f".handoffs/{stage}.json")
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom agent protocols | Agent Skills standard (agentskills.io) | 2024-2025 | Skills now portable across VS Code, Copilot CLI, Claude, etc. |
| Inline command scripts | Skill progressive disclosure | 2025 | Context efficiency: load only relevant content |
| Text-based error messages | Structured JSON handoffs | Ongoing | Machine-readable errors enable automated debugging |
| Manual slash command registration | Convention-based discovery | 2025-2026 | Skills auto-discovered from `.github/skills/` paths |

**Deprecated/outdated:**
- **Custom skill formats:** Use Agent Skills standard (agentskills.io)
- **`@`-participant mentions for custom agents:** Use `/` slash commands for skills
- **Inline error handling in chat responses:** Use structured handoff records

## Open Questions

Things that couldn't be fully resolved:

1. **OpenCode `.opencode/commands/` slash command format**
   - What we know: Objective mentioned "slash commands are markdown files in .opencode/commands/"
   - What's unclear: Exact markdown format for OpenCode slash command registration; whether distinct from Agent Skills
   - Recommendation: Treat as optional extension; prioritize Agent Skills format which is verified and standard. If OpenCode-specific commands needed, create thin markdown wrappers that invoke Agent Skills.

2. **Multi-stage command batching**
   - What we know: CONTEXT.md defers decision on batching (e.g., `/run-full-workflow`)
   - What's unclear: Whether orchestrator should handle multi-stage sequences or expose batch commands
   - Recommendation: Start with granular single-stage commands (`/rec-ensemble`, `/dock-run`); add batch commands only if user workflow demands it.

3. **Permission levels for autonomous tool execution**
   - What we know: VS Code Copilot supports permission levels (auto-approve, prompt, deny)
   - What's unclear: How to configure per-skill permission levels in this project
   - Recommendation: Default to prompt for destructive operations (file writes, command execution); use `allowed-tools` field in SKILL.md for pre-approved safe operations.

## Sources

### Primary (HIGH confidence)
- agentskills.io specification - https://agentskills.io/specification (2026-04-19 fetch)
- VS Code Copilot agent skills documentation - https://code.visualstudio.com/docs/copilot/customization/agent-skills (2026-04-19 fetch)
- Phase 3 implementation - scripts/agents/schemas/handoff.py (existing codebase)
- Phase 2 script structure - scripts/ directory conventions (existing codebase)

### Secondary (MEDIUM confidence)
- VS Code Copilot chat overview - https://code.visualstudio.com/docs/copilot/chat/copilot-chat (general patterns)
- GitHub awesome-copilot repository - https://github.com/github/awesome-copilot (skill examples, community patterns)

### Tertiary (LOW confidence)
- OpenCode `.opencode/commands/` format - mentioned in objective but not verified in official documentation

## Metadata

**Confidence breakdown:**
- Agent Skills format: HIGH - Official specification at agentskills.io, VS Code docs confirm implementation
- Error/feedback patterns: HIGH - Existing Phase 3 HandoffRecord schema aligns with best practices
- Slash command bridge: MEDIUM - Pattern derived from Phase 2 conventions + VS Code examples, not project-tested
- OpenCode commands: LOW - Format mentioned in objective but not verified in official sources

**Research date:** 2026-04-19
**Valid until:** 2026-06-19 (60 days - Agent Skills is stable standard, unlikely to change rapidly)
