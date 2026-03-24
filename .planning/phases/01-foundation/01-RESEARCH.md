# Phase 01: Foundation - Research

**Researched:** 2026-03-24  
**Domain:** Infrastructure for Scientific Workflow Automation (GROMACS/gnina)  
**Confidence:** HIGH

## Summary

This research addresses the foundation phase for an automated ensemble docking molecular dynamics workflow. The phase establishes configuration management, execution environment detection (local vs HPC/Slurm), job monitoring capabilities, checkpoint infrastructure, and human verification gates. The infrastructure components must support workflow-agnostic utilities that can be reused across all downstream phases.

The primary recommendation is to use Python's built-in configparser for INI-style configuration (per SCRIPT-09 requirement), JSON for checkpoint/state files due to its standard library support and broad compatibility, and a detection mechanism based on SLURM_* environment variables for execution backend identification. Slurm job submission should leverage the standard sbatch command with proper log parsing for monitoring. Human verification gates should implement a file-based approval mechanism with clear state transitions.

**Primary recommendation:** Use Python configparser for INI configs, JSON for state/checkpoint files, and SLURM_* environment variable detection for execution backend identification. Implement verification gates as file-based state machines.

## Standard Stack

The established libraries and tools for this infrastructure phase:

### Core Libraries
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| configparser | Python 3.x stdlib | INI configuration file parsing | Required per SCRIPT-09, built-in, supports sections/comments |
| json | Python 3.x stdlib | Checkpoint and state file serialization | Standard library, no dependencies, human-readable |
| os/sys | Python 3.x stdlib | Environment detection, process management | Required for execution backend detection |
| subprocess | Python 3.x stdlib | Job submission and command execution | Cross-platform process management |

### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| PyYAML | 6.0+ | YAML configuration if needed | When users prefer YAML over INI |
| shlex | Python 3.x stdlib | Shell-like parsing for command generation | When generating shell commands safely |

### Installation
No additional installation required - all core libraries are in Python standard library. Optional PyYAML can be installed via pip if YAML support is needed:

```bash
pip install PyYAML
```

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| INI config | TOML, YAML | TOML is newer, less ubiquitous; YAML requires external library |
| JSON checkpoints | YAML, pickle | YAML is more readable but slower; pickle is Python-specific |
| configparser | custom parsing | Configparser handles edge cases (comments, escaping, interpolation) |

## Architecture Patterns

### Recommended Project Structure
```
scripts/
├── infra/                    # Infrastructure utilities (Phase 1 deliverable)
│   ├── __init__.py
│   ├── config.py            # Config parsing utilities
│   ├── checkpoint.py        # Checkpoint save/load
│   ├── executor.py          # Execution backend detection + job submission
│   ├── monitor.py           # Job monitoring (log parsing, status)
│   ├── verification.py      # Verification gate mechanism
│   └── state.py             # Agent context state management
├── workflow/                 # Workflow-specific scripts (later phases)
└── utils/                    # Shared utilities
```

### Pattern 1: Execution Backend Detection
**What:** Detect whether running on local machine or HPC Slurm environment by checking SLURM_* environment variables.  
**When to use:** Before any job submission to determine execution path.  
**Example:**

```python
# Source: Python stdlib os module
import os

def detect_execution_backend():
    """Detect execution environment (local vs HPC/Slurm)."""
    if os.environ.get('SLURM_JOB_ID') is not None:
        return 'slurm'
    elif os.environ.get('SLURM_TMPDIR') is not None:
        return 'slurm'
    else:
        return 'local'

# Usage
backend = detect_execution_backend()  # Returns 'slurm' or 'local'
```

### Pattern 2: Checkpoint Management
**What:** Save and load workflow state using JSON for portability across phases.  
**When to use:** Between workflow stages and for session continuity.  
**Example:**

```python
# Source: Python stdlib json module
import json
from pathlib import Path
from datetime import datetime
from typing import Any, Dict, Optional

class CheckpointManager:
    """Format-agnostic checkpoint management for scientific workflows."""
    
    def __init__(self, checkpoint_dir: str = '.checkpoints'):
        self.checkpoint_dir = Path(checkpoint_dir)
        self.checkpoint_dir.mkdir(exist_ok=True)
    
    def save_checkpoint(self, stage: str, state: Dict[str, Any], 
                        metadata: Optional[Dict[str, Any]] = None) -> Path:
        """Save checkpoint with stage name."""
        checkpoint_data = {
            'stage': stage,
            'timestamp': datetime.now().isoformat(),
            'state': state,
            'metadata': metadata or {}
        }
        checkpoint_path = self.checkpoint_dir / f'{stage}_checkpoint.json'
        with open(checkpoint_path, 'w') as f:
            json.dump(checkpoint_data, f, indent=2)
        return checkpoint_path
    
    def load_checkpoint(self, stage: str) -> Optional[Dict[str, Any]]:
        """Load checkpoint for given stage."""
        checkpoint_path = self.checkpoint_dir / f'{stage}_checkpoint.json'
        if checkpoint_path.exists():
            with open(checkpoint_path, 'r') as f:
                return json.load(f)
        return None
    
    def list_checkpoints(self) -> Dict[str, str]:
        """List all available checkpoints with timestamps."""
        checkpoints = {}
        for ckpt_file in self.checkpoint_dir.glob('*_checkpoint.json'):
            stage = ckpt_file.stem.replace('_checkpoint', '')
            with open(ckpt_file, 'r') as f:
                data = json.load(f)
                checkpoints[stage] = data.get('timestamp', 'unknown')
        return checkpoints
```

### Pattern 3: Slurm Job Submission
**What:** Submit jobs to Slurm using sbatch and track status via squeue.  
**When to use:** For demanding computational tasks requiring HPC resources.  
**Example:**

```python
# Source: Python stdlib subprocess + Slurm documentation
import subprocess
import time
from typing import Tuple, Optional

class SlurmExecutor:
    """Slurm job submission and monitoring."""
    
    def __init__(self, default_account: Optional[str] = None):
        self.default_account = default_account
    
    def submit_job(self, script_path: str, job_name: str = 'autoDock',
                   time_limit: str = '02:00:00', 
                   ntasks: int = 1, ncpus: int = 1,
                   mem: str = '4G', output_file: str = 'slurm-%j.out') -> str:
        """Submit a job to Slurm and return job ID."""
        cmd = [
            'sbatch',
            '--job-name', job_name,
            '--time', time_limit,
            '--ntasks', str(ntasks),
            '--cpus-per-task', str(ncpus),
            '--mem', mem,
            '--output', output_file,
        ]
        if self.default_account:
            cmd.extend(['--account', self.default_account])
        
        cmd.append(script_path)
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            raise RuntimeError(f"sbatch failed: {result.stderr}")
        
        # Extract job ID from output like "Submitted batch job 12345"
        job_id = result.stdout.strip().split()[-1]
        return job_id
    
    def get_job_status(self, job_id: str) -> str:
        """Get job status using squeue."""
        result = subprocess.run(
            ['squeue', '-j', job_id, '-o', '%T'],
            capture_output=True, text=True
        )
        if result.returncode != 0:
            return 'UNKNOWN'
        
        lines = result.stdout.strip().split('\n')
        return lines[1].strip() if len(lines) > 1 else 'UNKNOWN'
    
    def wait_for_job(self, job_id: str, poll_interval: int = 30) -> Tuple[str, str]:
        """Wait for job to complete and return final status."""
        terminal_states = ['COMPLETED', 'FAILED', 'CANCELLED', 'TIMEOUT']
        
        while True:
            status = self.get_job_status(job_id)
            if status not in ['PENDING', 'RUNNING', 'UNKNOWN']:
                return status, f'slurm-{job_id}.out'
            time.sleep(poll_interval)
```

### Pattern 4: Verification Gate Mechanism
**What:** File-based approval mechanism with pause/resume/approve/reject states.  
**When to use:** At stage boundaries requiring human verification before proceeding.  
**Example:**

```python
# Source: Python stdlib + workflow best practices
import os
from pathlib import Path
from enum import Enum
from datetime import datetime
from typing import Optional

class GateState(Enum):
    """Verification gate states."""
    PENDING = 'pending'
    APPROVED = 'approved'
    REJECTED = 'rejected'
    PAUSED = 'paused'

class VerificationGate:
    """Human verification gate mechanism."""
    
    def __init__(self, stage_name: str, gate_dir: str = '.gates'):
        self.gate_dir = Path(gate_dir)
        self.gate_dir.mkdir(exist_ok=True)
        self.gate_file = self.gate_dir / f'{stage_name}_gate.json'
    
    def create_gate(self, description: str, metadata: dict = None) -> None:
        """Create a new verification gate."""
        gate_data = {
            'stage': stage_name,
            'state': GateState.PENDING.value,
            'created_at': datetime.now().isoformat(),
            'description': description,
            'metadata': metadata or {},
            'history': []
        }
        self._save_gate(gate_data)
    
    def approve(self, approver: str = 'human', notes: str = '') -> bool:
        """Approve the gate."""
        gate_data = self._load_gate()
        if gate_data is None:
            return False
        
        gate_data['state'] = GateState.APPROVED.value
        gate_data['approved_at'] = datetime.now().isoformat()
        gate_data['approver'] = approver
        gate_data['notes'] = notes
        self._save_gate(gate_data)
        return True
    
    def reject(self, reason: str, rejecter: str = 'human') -> bool:
        """Reject the gate."""
        gate_data = self._load_gate()
        if gate_data is None:
            return False
        
        gate_data['state'] = GateState.REJECTED.value
        gate_data['rejected_at'] = datetime.now().isoformat()
        gate_data['reason'] = reason
        gate_data['rejecter'] = rejecter
        self._save_gate(gate_data)
        return True
    
    def pause(self, reason: str = '') -> bool:
        """Pause at current gate."""
        gate_data = self._load_gate()
        if gate_data is None:
            return False
        
        gate_data['state'] = GateState.PAUSED.value
        gate_data['paused_at'] = datetime.now().isoformat()
        gate_data['pause_reason'] = reason
        self._save_gate(gate_data)
        return True
    
    def get_state(self) -> GateState:
        """Get current gate state."""
        gate_data = self._load_gate()
        if gate_data is None:
            return GateState.PENDING  # Default for non-existent gate
        return GateState(gate_data['state'])
    
    def can_proceed(self) -> bool:
        """Check if gate allows proceeding to next stage."""
        return self.get_state() == GateState.APPROVED
    
    def _save_gate(self, data: dict) -> None:
        import json
        with open(self.gate_file, 'w') as f:
            json.dump(data, f, indent=2)
    
    def _load_gate(self) -> Optional[dict]:
        import json
        if not self.gate_file.exists():
            return None
        with open(self.gate_file, 'r') as f:
            return json.load(f)
```

### Pattern 5: Agent Context State Management
**What:** File-based state passing for agent session continuity to avoid context overflow.  
**When to use:** For maintaining agent session state across checkpoint boundaries.  
**Example:**

```python
# Source: Python stdlib json module
import json
from pathlib import Path
from typing import Any, Dict, Optional
from datetime import datetime

class AgentState:
    """File-based state management for agent session continuity."""
    
    def __init__(self, state_file: str = '.agent_state.json'):
        self.state_file = Path(state_file)
        self.state: Dict[str, Any] = {}
        self._load()
    
    def _load(self) -> None:
        """Load state from file."""
        if self.state_file.exists():
            with open(self.state_file, 'r') as f:
                self.state = json.load(f)
    
    def _save(self) -> None:
        """Save state to file."""
        self.state['last_updated'] = datetime.now().isoformat()
        with open(self.state_file, 'w') as f:
            json.dump(self.state, f, indent=2)
    
    def set(self, key: str, value: Any) -> None:
        """Set a state value."""
        self.state[key] = value
        self._save()
    
    def get(self, key: str, default: Any = None) -> Any:
        """Get a state value."""
        return self.state.get(key, default)
    
    def update(self, updates: Dict[str, Any]) -> None:
        """Update multiple state values."""
        self.state.update(updates)
        self._save()
    
    def clear(self) -> None:
        """Clear all state."""
        self.state = {}
        self._save()
    
    def dump_to_file(self, output_path: str) -> None:
        """Dump state to specified file for session continuity."""
        with open(output_path, 'w') as f:
            json.dump(self.state, f, indent=2)
    
    def load_from_file(self, input_path: str) -> bool:
        """Load state from specified file."""
        if not Path(input_path).exists():
            return False
        with open(input_path, 'r') as f:
            self.state = json.load(f)
        self._save()
        return True
```

### Anti-Patterns to Avoid
- **Hardcoding execution paths:** Always detect execution backend at runtime rather than hardcoding paths for local or HPC.
- **Storing state in memory only:** Agent state must be persisted to file for session continuity; in-memory state is lost on context overflow.
- **Blocking wait for Slurm jobs:** Use polling with configurable intervals rather than blocking indefinitely; allow for interruptibility.
- **Silent failure on verification gates:** Always check gate state before proceeding; proceeding without verification defeats the purpose.
- **Binary checkpoint formats:** Use JSON or YAML for checkpoints to ensure interoperability and human readability for debugging.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| INI config parsing | Custom regex/line parsing | Python configparser | Handles escaping, comments, interpolation, type conversion edge cases |
| JSON serialization | Custom to-string methods | Python json module | Handles Unicode, nested structures, type coercion correctly |
| Environment detection | Platform-specific shell checks | Check SLURM_* env vars | Standard HPC detection pattern, reliable across systems |
| Command escaping | String formatting for shell commands | shlex.quote() | Prevents shell injection vulnerabilities |
| Log parsing | Line-by-line regex matching | Structured logging or known patterns | Consistent error detection across GROMACS/gnina tools |

**Key insight:** The scientific computing domain (GROMACS, gnina, gmx_MMPBSA) uses standard file formats and conventions. Custom implementations risk incompatibility with these established tools and introduce maintenance burden.

## Common Pitfalls

### Pitfall 1: SLURM Environment Variable Assumptions
**What goes wrong:** Code assumes only SLURM_JOB_ID exists, but some HPC systems set SLURM_TMPDIR or other partial environment variables.  
**Why it happens:** Different Slurm configurations expose different environment variables.  
**How to avoid:** Check for multiple SLURM_* variables or use a wrapper that tests multiple indicators.  
**Warning signs:** Code works on one HPC cluster but fails on another with the same execution logic.

### Pitfall 2: Checkpoint Corruption on Interrupted Writes
**What goes wrong:** Partial JSON write leaves checkpoint file in unreadable state after script crash.  
**Why it happens:** Writing JSON directly without atomic write pattern.  
**How to avoid:** Write to temporary file then rename (atomic on POSIX systems).  
**Warning signs:** Checkpoint files with trailing truncation or missing closing braces.

### Pitfall 3: Gate State Race Conditions
**What goes wrong:** Multiple agents checking same gate simultaneously may create conflicting transitions.  
**Why it happens:** No locking mechanism on gate files when multiple processes access.  
**How to avoid:** Use file-based locking (fcntl.flock) or implement optimistic locking with version numbers.  
**Warning signs:** Gate state shows PENDING when APPROVED was just set, or history shows unexpected transitions.

### Pitfall 4: Context Window Overflow Not Accounted For
**What goes wrong:** Agent state accumulates without bound until context window overflows mid-stage.  
**Why it happens:** No checkpointing of agent context during long-running workflows.  
**How to avoid:** Implement periodic context dumps (per AGENT-06), checkpoint at stage boundaries, and load state from file on session resume.  
**Warning signs:** Mid-stage failures, truncated agent conversations, loss of workflow progress.

### Pitfall 5: Ignoring GROMACS/gnina Exit Codes
**What goes wrong:** Pipeline continues after GROMACS or gnina failure due to ignoring non-zero exit codes.  
**Why it happens:** Script continues without checking subprocess return codes.  
**How to avoid:** Always check return codes; implement proper error detection in log parsing.  
**Warning signs:** Downstream stages receive corrupted inputs from failed predecessors.

## Code Examples

### Config File Example (INI Style - Per SCRIPT-09)
```ini
# Source: Python configparser documentation
# config.ini - Pipeline configuration

[DEFAULT]
work_dir = ./work
checkpoint_dir = .checkpoints
log_dir = ./logs

[execution]
backend = auto  # auto-detect, local, or slurm
max_parallel_jobs = 4

[slurm]
account = null
time_limit = 24:00:00
ntasks = 8
cpus_per_task = 4
mem = 16G

[gromacs]
version = 2024
mdrun_args = -nt 8 -gpu on

[gnina]
model = default
exhaustiveness = 8

[mmpbsa]
nproc = 8
```

### Config Parser Usage
```python
# Source: Python configparser stdlib
import configparser
from pathlib import Path
from typing import Any, Optional

class ConfigManager:
    """INI configuration file manager."""
    
    def __init__(self, config_path: str = 'config.ini'):
        self.config = configparser.ConfigParser()
        self.config.read(config_path)
    
    def get(self, section: str, key: str, fallback: Any = None) -> str:
        """Get string value with fallback."""
        return self.config.get(section, key, fallback=fallback)
    
    def getint(self, section: str, key: str, fallback: Any = None) -> int:
        """Get integer value with fallback."""
        return self.config.getint(section, key, fallback=fallback)
    
    def getboolean(self, section: str, key: str, fallback: Any = None) -> bool:
        """Get boolean value with fallback."""
        return self.config.getboolean(section, key, fallback=fallback)
    
    def get_section(self, section: str) -> dict:
        """Get all key-value pairs from a section."""
        if self.config.has_section(section):
            return dict(self.config.items(section))
        return {}
    
    def get_execution_backend(self) -> str:
        """Get execution backend with auto-detection."""
        backend = self.get('execution', 'backend', fallback='local')
        if backend == 'auto':
            # Import executor module for detection
            from scripts.infra.executor import detect_execution_backend
            return detect_execution_backend()
        return backend

# Usage
config = ConfigManager('config.ini')
backend = config.get_execution_backend()  # 'local' or 'slurm'
slurm_account = config.get('slurm', 'account')  # Returns None if not set
```

### Job Monitoring with Log Parsing
```python
# Source: Python stdlib re module + scientific workflow patterns
import re
import subprocess
from pathlib import Path
from typing import Tuple, List, Optional
from enum import Enum

class JobStatus(Enum):
    """Job status enumeration."""
    RUNNING = 'running'
    COMPLETED = 'completed'
    FAILED = 'failed'
    UNKNOWN = 'unknown'

class LogMonitor:
    """Monitor job execution via log parsing."""
    
    # Common error patterns in scientific software
    ERROR_PATTERNS = [
        r'ERROR',
        r'Fatal error',
        r'Segmentation fault',
        r'SIGSEGV',
        r'Aborted',
        r'CUDA ERROR',
        r'GROMACS error',
    ]
    
    WARNING_PATTERNS = [
        r'WARNING',
        r'WARN',
    ]
    
    COMPLETION_MARKERS = [
        r'GROMACS.*completed',
        r'gnina.*finished',
        r'Performance:',  # Common MD completion indicator
    ]
    
    def __init__(self, log_file: str):
        self.log_file = Path(log_file)
    
    def check_errors(self) -> List[str]:
        """Scan log file for error patterns."""
        if not self.log_file.exists():
            return ['Log file not found']
        
        errors = []
        with open(self.log_file, 'r') as f:
            for line_num, line in enumerate(f, 1):
                for pattern in self.ERROR_PATTERNS:
                    if re.search(pattern, line, re.IGNORECASE):
                        errors.append(f'Line {line_num}: {line.strip()}')
        return errors
    
    def check_warnings(self) -> List[str]:
        """Scan log file for warning patterns."""
        if not self.log_file.exists():
            return []
        
        warnings = []
        with open(self.log_file, 'r') as f:
            for line_num, line in enumerate(f, 1):
                for pattern in self.WARNING_PATTERNS:
                    if re.search(pattern, line, re.IGNORECASE):
                        warnings.append(f'Line {line_num}: {line.strip()}')
        return warnings
    
    def is_completed(self) -> bool:
        """Check if job completed successfully."""
        if not self.log_file.exists():
            return False
        
        with open(self.log_file, 'r') as f:
            content = f.read()
            for pattern in self.COMPLETION_MARKERS:
                if re.search(pattern, content, re.IGNORECASE):
                    return True
        return False
    
    def get_status(self) -> JobStatus:
        """Determine job status from log analysis."""
        if not self.log_file.exists():
            return JobStatus.UNKNOWN
        
        errors = self.check_errors()
        if errors:
            return JobStatus.FAILED
        
        if self.is_completed():
            return JobStatus.COMPLETED
        
        return JobStatus.RUNNING
    
    def get_summary(self) -> dict:
        """Get comprehensive log analysis summary."""
        return {
            'status': self.get_status().value,
            'errors': self.check_errors(),
            'warnings': self.check_warnings(),
            'completed': self.is_completed(),
        }
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoded configuration in scripts | INI/YAML config files | 2010s | Enables user customization without code changes |
| Memory-only state between sessions | File-based state persistence | Always needed | Enables session continuity and checkpoint recovery |
| Local-only execution | Local + Slurm hybrid | HPC普及 | Enables scaling to demanding MD/docking tasks |
| Manual job monitoring | Log parsing automation | Modern | Reduces human intervention in long-running workflows |
| Blocking waits | Async polling | Modern | Enables interruptibility and better resource utilization |

**Deprecated/outdated:**
- XML configuration files: Replaced by JSON/YAML for most scientific workflows
- Database-backed state: Overkill for workflow state; file-based is simpler and sufficient
- Custom job schedulers: Slurm is the HPC standard; custom schedulers unnecessary
- Shell script-only infrastructure: Python offers better error handling and cross-platform support

## Open Questions

1. **Multi-cluster Slurm Support**
   - What we know: Different HPC clusters may have different Slurm configurations and environment setups
   - What's unclear: How to handle cluster-specific quirks (different tmpdirs, account requirements)
   - Recommendation: Implement cluster detection via hostname and provide cluster-specific config overrides

2. **Verification Gate Inter-Agent Communication**
   - What we know: Gates need approval from human users between stages
   - What's unclear: How to handle multiple agents needing to signal through the same gate
   - Recommendation: Implement a notification system for gate state changes

3. **Checkpoint Format Versioning**
   - What we know: Checkpoint files may become incompatible across workflow versions
   - What's unclear: How to handle migration of old checkpoint formats
   - Recommendation: Include schema version in checkpoint header; implement migration path

4. **Agent Context Size Management**
   - What we know: AGENT-06 requires file-based state passing to avoid context overflow
   - What's unclear: How to prioritize what state to keep when approaching limits
   - Recommendation: Implement tiered state with critical vs optional components

## Sources

### Primary (HIGH confidence)
- Python 3.x configparser documentation - INI parsing standards
- Python 3.x json documentation - Checkpoint serialization
- Slurm sbatch/squeue documentation (slurm.schedmd.com) - HPC job management

### Secondary (MEDIUM confidence)
- PyYAML documentation - Alternative configuration format
- Python shlex documentation - Shell command safety

### Tertiary (LOW confidence)
- Community patterns for scientific workflow automation (webfetch only)
- HPC best practices discussions

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All core libraries are Python standard library or well-established
- Architecture: HIGH - Patterns derived from Python stdlib and Slurm documentation
- Pitfalls: MEDIUM - Based on standard HPC and workflow patterns; some specifics need validation

**Research date:** 2026-03-24  
**Valid until:** 2026-04-24 (30 days for stable infrastructure patterns)