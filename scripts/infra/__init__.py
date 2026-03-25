"""
Infrastructure utilities for autoEnsmblDockMD workflow.

This package provides workflow-agnostic infrastructure for:
- Configuration management (INI format)
- State persistence (JSON-based)
- Checkpoint management
- Execution backend detection (local/Slurm)
- Job monitoring (log parsing)
- Human verification gates
"""

from .config import ConfigManager
from .state import AgentState
from .checkpoint import CheckpointManager
from .executor import detect_execution_backend, LocalExecutor, SlurmExecutor
from .monitor import JobStatus, LogMonitor
from .verification import GateState, VerificationGate

__all__ = [
    # Configuration
    'ConfigManager',
    
    # State management
    'AgentState',
    
    # Checkpoint
    'CheckpointManager',
    
    # Execution
    'detect_execution_backend',
    'LocalExecutor',
    'SlurmExecutor',
    
    # Monitoring
    'JobStatus',
    'LogMonitor',
    
    # Verification
    'GateState',
    'VerificationGate',
]

__version__ = '0.1.0'
