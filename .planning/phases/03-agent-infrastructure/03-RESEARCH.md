# Phase 3: Agent Infrastructure - Research

**Researched:** 2026-04-19
**Domain:** Multi-agent workflow orchestration for scientific pipelines
**Confidence:** MEDIUM

## Summary

Phase 3 implements five specialized agent types (orchestrator, runner, analyzer, checker, debugger) that coordinate execution of the computational chemistry pipeline built in Phase 2. The agents use file-based state passing to maintain context across sessions and enable human verification checkpoints.

This research investigated multi-agent orchestration patterns, agent communication protocols, and state management strategies. The key finding is that **file-based state passing with JSON handoff records** is the industry-standard approach for durable, inspectable agent workflows, particularly when human-in-the-loop verification is required.

The project's unique constraint is that these are **not autonomous AI agents**, but rather **structured workflow templates/skills** that OpenCode (or similar coding agents) can load to perform specific roles. This means the implementation focuses on clear role definitions, state schemas, and handoff protocols rather than agent-to-agent LLM communication.

**Primary recommendation:** Implement agents as Python classes with well-defined state schemas, use JSON for all inter-agent handoff, leverage existing Phase 1 infrastructure (AgentState, CheckpointManager, VerificationGate), and provide both CLI interfaces and importable modules for flexibility.

## Standard Stack

The established libraries/tools for multi-agent workflow orchestration:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Python Standard Library | 3.9+ | Core agent implementation | No external dependencies, maximum compatibility |
| json | stdlib | State serialization | Human-readable, language-agnostic, already used in Phase 1 |
| pathlib | stdlib | File path handling | Cross-platform, type-safe path operations |
| configparser | stdlib | Configuration loading | Already project standard (Phase 1 decision) |
| dataclasses | stdlib | State schemas | Type-safe, built-in validation, Python 3.7+ |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| pydantic | 2.x | Advanced state validation | If complex nested validation needed (optional) |
| typing | stdlib | Type annotations | All agent interfaces and state schemas |
| enum | stdlib | State machine states | Status enums, action types |
| logging | stdlib | Agent action logging | All agents should log decisions |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| JSON | YAML | YAML more human-readable but adds dependency; JSON already used |
| JSON | pickle | pickle smaller but opaque, version-sensitive, security risk |
| dataclasses | pydantic | pydantic adds validation but external dependency |
| File-based | Database | DB adds complexity, file-based meets requirements |

**Installation:**
```bash
# No additional installations required - uses Python stdlib
# Optional: pydantic for enhanced validation
pip install pydantic  # optional
```

## Architecture Patterns

### Recommended Project Structure
```
scripts/agents/
├── __init__.py              # Agent registry
├── base.py                  # BaseAgent abstract class
├── orchestrator.py          # OrchestratorAgent
├── runner.py                # RunnerAgent
├── analyzer.py              # AnalyzerAgent
├── checker.py               # CheckerAgent
├── debugger.py              # DebuggerAgent
├── schemas/
│   ├── __init__.py
│   ├── handoff.py          # Handoff record schemas
│   └── state.py            # Agent state schemas
└── utils/
    ├── __init__.py
    └── routing.py          # Agent routing logic
```

### Pattern 1: Agent Base Class

**What:** Abstract base class defining agent interface contract
**When to use:** All five agent types inherit from this

**Example:**
```python
# Source: Multi-agent systems best practice (informed by LangGraph patterns)
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
from pathlib import Path
from scripts.infra.state import AgentState
from scripts.infra.checkpoint import CheckpointManager

class BaseAgent(ABC):
    """Base class for all agents in the workflow."""
    
    def __init__(self, workspace: Path, config: Optional[Dict[str, Any]] = None):
        self.workspace = Path(workspace)
        self.config = config or {}
        self.state = AgentState(self.workspace / '.agent_state.json')
        self.checkpoint_mgr = CheckpointManager(self.workspace / '.checkpoints')
        
    @abstractmethod
    def execute(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Execute agent's primary function.
        
        Args:
            input_data: Input handoff record from previous agent/stage
            
        Returns:
            Handoff record for next agent/stage
        """
        pass
    
    @abstractmethod
    def get_role(self) -> str:
        """Return agent's role identifier."""
        pass
    
    def save_checkpoint(self, stage: str, state: Dict[str, Any]) -> None:
        """Save checkpoint at stage boundary."""
        self.checkpoint_mgr.save_checkpoint(stage, state)
    
    def load_checkpoint(self, stage: str) -> Optional[Dict[str, Any]]:
        """Load checkpoint for stage."""
        return self.checkpoint_mgr.load_checkpoint(stage=stage)
```

### Pattern 2: Handoff Record Schema

**What:** Standardized format for agent-to-agent communication
**When to use:** Every agent-to-agent handoff

**Example:**
```python
# Source: Research on state handoff patterns
from dataclasses import dataclass, field
from typing import Dict, Any, List, Optional
from datetime import datetime
from enum import Enum

class HandoffStatus(Enum):
    SUCCESS = "success"
    FAILURE = "failure"
    NEEDS_REVIEW = "needs_review"
    BLOCKED = "blocked"

@dataclass
class HandoffRecord:
    """Standard handoff record between agents."""
    
    # Routing
    from_agent: str
    to_agent: str
    timestamp: str = field(default_factory=lambda: datetime.utcnow().isoformat() + 'Z')
    
    # Status
    status: HandoffStatus = HandoffStatus.SUCCESS
    stage: str = ""
    
    # Data
    data: Dict[str, Any] = field(default_factory=dict)
    
    # Context
    warnings: List[str] = field(default_factory=list)
    errors: List[str] = field(default_factory=list)
    recommendations: List[str] = field(default_factory=list)
    
    # Metadata
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to JSON-serializable dict."""
        return {
            'from_agent': self.from_agent,
            'to_agent': self.to_agent,
            'timestamp': self.timestamp,
            'status': self.status.value,
            'stage': self.stage,
            'data': self.data,
            'warnings': self.warnings,
            'errors': self.errors,
            'recommendations': self.recommendations,
            'metadata': self.metadata
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'HandoffRecord':
        """Create from dict."""
        data_copy = data.copy()
        data_copy['status'] = HandoffStatus(data_copy.get('status', 'success'))
        return cls(**data_copy)
```

### Pattern 3: Orchestrator State Machine

**What:** State machine for workflow orchestration with human gates
**When to use:** Orchestrator agent workflow management

**Example:**
```python
# Source: Workflow orchestration patterns
from enum import Enum
from typing import Optional

class WorkflowStage(Enum):
    INIT = "init"
    REC_PREP = "receptor_prep"
    REC_MD = "receptor_md"
    REC_CLUSTER = "receptor_cluster"
    DOCK_PREP = "docking_prep"
    DOCK_RUN = "docking_run"
    COM_PREP = "complex_prep"
    COM_MD = "complex_md"
    COM_MMPBSA = "complex_mmpbsa"
    COM_ANA = "complex_analysis"
    COMPLETE = "complete"

class OrchestratorAgent(BaseAgent):
    """Orchestrates workflow and spawns specialized agents."""
    
    def get_role(self) -> str:
        return "orchestrator"
    
    def route_to_agent(self, stage: WorkflowStage) -> str:
        """Determine which agent handles a stage."""
        stage_to_agent = {
            WorkflowStage.REC_PREP: "runner",
            WorkflowStage.REC_MD: "runner",
            WorkflowStage.REC_CLUSTER: "runner",
            WorkflowStage.DOCK_PREP: "runner",
            WorkflowStage.DOCK_RUN: "runner",
            WorkflowStage.COM_PREP: "runner",
            WorkflowStage.COM_MD: "runner",
            WorkflowStage.COM_MMPBSA: "runner",
            WorkflowStage.COM_ANA: "analyzer",
        }
        return stage_to_agent.get(stage, "unknown")
    
    def check_verification_gate(self, stage: str) -> bool:
        """Check if stage has passed verification gate."""
        from scripts.infra.verification import VerificationGate
        gate = VerificationGate(stage, self.workspace / '.gates')
        return gate.can_proceed()
```

### Pattern 4: Runner Execution Pattern

**What:** Runner executes scripts and shapes outputs into handoff records
**When to use:** All script execution stages

**Example:**
```python
# Source: Script orchestration patterns
import subprocess
from pathlib import Path

class RunnerAgent(BaseAgent):
    """Executes stage scripts and formats results."""
    
    def get_role(self) -> str:
        return "runner"
    
    def execute(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Execute stage script and return structured result."""
        stage = input_data.get('stage')
        script_path = input_data.get('script')
        params = input_data.get('params', {})
        
        # Execute script
        result = self._run_script(script_path, params)
        
        # Shape into handoff record
        handoff = HandoffRecord(
            from_agent="runner",
            to_agent=input_data.get('next_agent', 'orchestrator'),
            stage=stage,
            status=HandoffStatus.SUCCESS if result['returncode'] == 0 else HandoffStatus.FAILURE,
            data={
                'output_dir': result.get('output_dir'),
                'log_file': result.get('log_file'),
                'metrics': self._extract_metrics(result)
            },
            warnings=self._extract_warnings(result),
            errors=result.get('errors', [])
        )
        
        return handoff.to_dict()
    
    def _run_script(self, script: str, params: Dict[str, Any]) -> Dict[str, Any]:
        """Execute shell script with parameters."""
        # Build command with params
        cmd = self._build_command(script, params)
        
        # Execute
        proc = subprocess.run(
            cmd,
            cwd=self.workspace,
            capture_output=True,
            text=True
        )
        
        return {
            'returncode': proc.returncode,
            'stdout': proc.stdout,
            'stderr': proc.stderr,
            'command': ' '.join(cmd)
        }
```

### Pattern 5: Checker Validation Pattern

**What:** Checker validates results and generates warnings
**When to use:** After any stage completion, before human gate

**Example:**
```python
# Source: Validation patterns
class CheckerAgent(BaseAgent):
    """Validates stage results and flags issues."""
    
    def get_role(self) -> str:
        return "checker"
    
    def execute(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Validate stage results."""
        stage = input_data.get('stage')
        results = input_data.get('data', {})
        
        # Run validation checks
        checks = self._get_checks_for_stage(stage)
        warnings = []
        errors = []
        recommendations = []
        
        for check in checks:
            result = check(results)
            if result.level == 'error':
                errors.append(result.message)
            elif result.level == 'warning':
                warnings.append(result.message)
            if result.recommendation:
                recommendations.append(result.recommendation)
        
        # Determine if gate should pass
        status = HandoffStatus.SUCCESS
        if errors:
            status = HandoffStatus.FAILURE
        elif warnings:
            status = HandoffStatus.NEEDS_REVIEW
        
        handoff = HandoffRecord(
            from_agent="checker",
            to_agent="orchestrator",
            stage=stage,
            status=status,
            data={'validation_passed': len(errors) == 0},
            warnings=warnings,
            errors=errors,
            recommendations=recommendations
        )
        
        return handoff.to_dict()
```

### Anti-Patterns to Avoid

- **Direct agent-to-agent calls:** Agents should not import and call other agents directly. All communication via handoff files.
- **Shared mutable state:** Each agent reads input, produces output. No shared global state.
- **Implicit dependencies:** All inputs/outputs explicit in handoff records.
- **Synchronous blocking:** Agents write handoff and return; orchestrator handles routing.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Agent state persistence | Custom file format | AgentState (Phase 1) | Already implements atomic writes, dot notation |
| Checkpoint management | Custom checkpoint logic | CheckpointManager (Phase 1) | Handles timestamps, listing, stage lookup |
| Verification gates | Custom approval logic | VerificationGate (Phase 1) | State transitions, history, file locking |
| Job execution | Direct subprocess calls | LocalExecutor/SlurmExecutor (Phase 1) | Handles job managers, logging, monitoring |
| Configuration loading | Custom parsers | ConfigManager (Phase 1) | INI format, validation, type conversion |
| File locking | fcntl directly | VerificationGate approach | Already handles timeouts, deadlock prevention |

**Key insight:** Phase 1 already built all the infrastructure needed. Phase 3 adds agent role definitions and handoff schemas on top of existing primitives.

## Common Pitfalls

### Pitfall 1: Agent State Leakage Between Sessions

**What goes wrong:** Agent state accumulates across runs without proper cleanup, causing stale data to influence decisions.

**Why it happens:** AgentState persists by design, but agents don't clean up completed stages.

**How to avoid:** 
- Orchestrator clears agent state at workflow initialization
- Each agent namespace uses stage-scoped keys (`stage.receptor_prep.status`)
- State file includes `last_updated` timestamp for staleness detection

**Warning signs:**
- Agent makes decision based on previous run's data
- State file grows unbounded
- Checkpoints and state files show mismatched stage numbers

### Pitfall 2: Handoff Record Schema Drift

**What goes wrong:** Different agents produce handoff records with inconsistent structure, breaking downstream consumers.

**Why it happens:** No centralized schema enforcement, agents add fields ad-hoc.

**How to avoid:**
- Define HandoffRecord schema in `scripts/agents/schemas/handoff.py`
- All agents import and use the schema
- Use dataclass validation or pydantic to enforce structure
- Version handoff schema (`schema_version` field)

**Warning signs:**
- KeyError when agent reads handoff record
- Optional fields being required by consumers
- Handoff records missing critical routing info

### Pitfall 3: Verification Gate Bypass

**What goes wrong:** Workflow continues past failed verification gate because gate state not checked.

**Why it happens:** Orchestrator checks gate but doesn't enforce blocking on REJECTED state.

**How to avoid:**
- Orchestrator MUST check `gate.can_proceed()` before advancing stage
- REJECTED gates require human intervention to clear
- Gate state transition rules prevent auto-approval
- Log all gate state checks with outcomes

**Warning signs:**
- Stages running despite previous stage warnings
- Human checkpoints being skipped
- Gate files show REJECTED but workflow continued

### Pitfall 4: Agent Role Confusion

**What goes wrong:** Checker tries to fix problems instead of just flagging them; Runner tries to validate instead of just executing.

**Why it happens:** Unclear agent boundaries and responsibilities.

**How to avoid:**
- **Runner:** Execute only, never validate or debug
- **Analyzer:** Run analysis, never fix data
- **Checker:** Validate only, never execute or fix
- **Debugger:** Diagnose and fix, never validate or execute workflows
- **Orchestrator:** Route and checkpoint, never execute scripts directly

**Warning signs:**
- Agent files contain overlapping logic
- Agent execution times unexpectedly long (doing too much)
- Handoff records contain actions outside agent's role

### Pitfall 5: Silent Failures in Handoff Chain

**What goes wrong:** Agent fails but writes SUCCESS handoff, downstream agent proceeds with bad data.

**Why it happens:** Error detection incomplete, status field not updated on failure.

**How to avoid:**
- All exceptions caught and converted to FAILURE status
- Return code checks for subprocess execution
- Required output files checked for existence
- Status MUST reflect actual outcome, not intent

**Warning signs:**
- Workflow reports complete but outputs missing
- Handoff records show SUCCESS but errors in logs
- Next stage fails with "file not found" for required input

## Code Examples

Verified patterns from research and Phase 1 infrastructure:

### Orchestrator Main Loop

```python
# Source: Workflow orchestration patterns
from pathlib import Path
from typing import Optional
from scripts.agents.orchestrator import OrchestratorAgent
from scripts.agents.schemas.handoff import HandoffRecord, HandoffStatus
from scripts.infra.verification import VerificationGate

def run_workflow(workspace: Path, config: Dict[str, Any]) -> None:
    """Run full workflow with agent orchestration."""
    
    orch = OrchestratorAgent(workspace, config)
    current_stage = orch.get_current_stage()
    
    while current_stage != WorkflowStage.COMPLETE:
        # Check verification gate
        if not orch.check_verification_gate(current_stage.value):
            print(f"Stage {current_stage.value} blocked by verification gate")
            break
        
        # Route to appropriate agent
        agent_type = orch.route_to_agent(current_stage)
        handoff = orch.dispatch_to_agent(agent_type, current_stage)
        
        # Process handoff result
        if handoff['status'] == HandoffStatus.FAILURE.value:
            print(f"Stage {current_stage.value} failed: {handoff.get('errors')}")
            break
        
        # Save checkpoint
        orch.save_checkpoint(
            stage=current_stage.value,
            state=handoff['data']
        )
        
        # Create verification gate if needed
        if orch.requires_human_check(current_stage):
            gate = VerificationGate(current_stage.value, workspace / '.gates')
            gate.create_gate(
                description=f"Verify {current_stage.value} results",
                output_paths=handoff['data'].get('output_files', []),
                metrics=handoff['data'].get('metrics', {})
            )
            print(f"Human verification required for {current_stage.value}")
            break
        
        # Advance to next stage
        current_stage = orch.get_next_stage(current_stage)
```

### CLI Interface for Agents

```python
# Source: Agent CLI patterns
import argparse
import json
from pathlib import Path

def main():
    """CLI interface for agent execution."""
    parser = argparse.ArgumentParser(description='Execute workflow agent')
    parser.add_argument('--agent', required=True, choices=['orchestrator', 'runner', 'analyzer', 'checker', 'debugger'])
    parser.add_argument('--workspace', required=True, type=Path)
    parser.add_argument('--config', type=Path, help='Config INI file')
    parser.add_argument('--input', type=Path, help='Input handoff JSON')
    parser.add_argument('--output', type=Path, help='Output handoff JSON')
    
    args = parser.parse_args()
    
    # Load config
    config = {}
    if args.config:
        from scripts.infra.config import ConfigManager
        cfg_mgr = ConfigManager(str(args.config))
        config = cfg_mgr.get_all()
    
    # Load input handoff
    input_data = {}
    if args.input and args.input.exists():
        with open(args.input) as f:
            input_data = json.load(f)
    
    # Instantiate agent
    from scripts.agents import get_agent
    agent = get_agent(args.agent, args.workspace, config)
    
    # Execute
    output_data = agent.execute(input_data)
    
    # Write output handoff
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with open(args.output, 'w') as f:
            json.dump(output_data, f, indent=2)
    else:
        print(json.dumps(output_data, indent=2))

if __name__ == '__main__':
    main()
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Agent-to-agent LLM calls | File-based handoff with schemas | 2024-2025 | Better debuggability, human inspection, session recovery |
| Pickle for state | JSON for state | Ongoing | Language-agnostic, version-safe, human-readable |
| Monolithic orchestrator | Specialized agent roles | 2024 | Clearer separation of concerns, easier testing |
| In-memory state | Persistent checkpoints | 2023-2024 | Session recovery, human-in-the-loop support |
| Black-box agents | Structured handoff records | 2024-2025 | Transparency, validation, debugging |

**Deprecated/outdated:**
- **Autonomous agent loops:** Modern approach uses human-in-the-loop gates rather than fully autonomous operation
- **Shared memory multi-agent:** File-based handoff preferred for scientific workflows where reproducibility matters
- **Agent-specific state formats:** Standardized handoff schemas across all agents

## Open Questions

Things that couldn't be fully resolved:

1. **Agent skill file format for OpenCode**
   - What we know: OpenCode supports loading "skills" but exact format unclear
   - What's unclear: File extension, schema, discovery mechanism
   - Recommendation: Implement as Python modules first, create skill wrappers if format becomes clear

2. **Slash command registration**
   - What we know: User wants slash commands like `/run-receptor-md`
   - What's unclear: How slash commands are registered with OpenCode
   - Recommendation: Provide CLI entrypoints first (`python -m scripts.agents.runner`), slash command layer can wrap these

3. **Optimal checkpoint granularity**
   - What we know: Checkpoint at every stage transition
   - What's unclear: Whether to checkpoint within long-running stages (e.g., MD production)
   - Recommendation: Stage-level checkpoints required; within-stage optional and left to runner's discretion

4. **Debugger version awareness**
   - What we know: Debugger should be version-aware (GROMACS 2023.5, etc.)
   - What's unclear: How to maintain version documentation in agent-readable format
   - Recommendation: Create `scripts/agents/data/tool_versions.json` with canonical version info

## Sources

### Primary (HIGH confidence)
- Phase 1 infrastructure code: `scripts/infra/*.py` - Verified implementation patterns
- AGENTS.md: Agent role definitions and requirements - Project specification
- Phase 3 CONTEXT.md: User decisions on agent boundaries - Project constraints

### Secondary (MEDIUM confidence)
- LangGraph documentation (https://www.langchain.com/langgraph) - Multi-agent patterns
- Multi-agent LLM survey (arXiv:2402.01680) - Agent communication patterns

### Tertiary (LOW confidence)
- General multi-agent system patterns - Architectural concepts only

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Uses Python stdlib and existing Phase 1 infrastructure
- Architecture: HIGH - Based on verified Phase 1 patterns and project requirements
- Pitfalls: MEDIUM - Informed by multi-agent research but project-specific

**Research date:** 2026-04-19
**Valid until:** 30 days (stable domain, patterns well-established)

**Key constraints from CONTEXT.md:**
- Agents are workflow templates/skills, not autonomous AI agents
- File-based state passing required (already in Phase 1)
- Human verification gates required at stage boundaries
- Must follow GSD workflow reporting style
- Checker and Debugger have distinct, non-overlapping roles
