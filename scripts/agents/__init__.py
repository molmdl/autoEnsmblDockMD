"""Public agent API, registry, and factory helpers."""

from __future__ import annotations

from pathlib import Path
from typing import Any, Dict, Type

from .analyzer import AnalyzerAgent
from .base import BaseAgent
from .checker import CheckerAgent
from .debugger import DebuggerAgent
from .orchestrator import OrchestratorAgent
from .runner import RunnerAgent
from .schemas import HandoffRecord, HandoffStatus, WorkflowStage

AGENT_REGISTRY: Dict[str, Type[BaseAgent]] = {
    "orchestrator": OrchestratorAgent,
    "runner": RunnerAgent,
    "analyzer": AnalyzerAgent,
    "checker": CheckerAgent,
    "debugger": DebuggerAgent,
}


def get_agent(
    role: str,
    workspace: Path,
    config: Dict[str, Any] | None = None,
) -> BaseAgent:
    """Instantiate an agent by role string."""
    if not isinstance(role, str):
        raise TypeError("role must be a string")

    normalized_role = role.strip().lower()
    if not normalized_role:
        raise ValueError("role must be a non-empty string")

    if normalized_role not in AGENT_REGISTRY:
        raise ValueError(
            f"Unknown agent role '{role}'. "
            f"Expected one of: {', '.join(sorted(AGENT_REGISTRY.keys()))}"
        )

    agent_cls = AGENT_REGISTRY[normalized_role]
    return agent_cls(workspace=Path(workspace), config=config or {})


__all__ = [
    "BaseAgent",
    "OrchestratorAgent",
    "RunnerAgent",
    "AnalyzerAgent",
    "CheckerAgent",
    "DebuggerAgent",
    "HandoffRecord",
    "HandoffStatus",
    "WorkflowStage",
    "AGENT_REGISTRY",
    "get_agent",
]
