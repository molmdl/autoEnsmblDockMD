"""Base agent abstraction for workflow role implementations."""

from __future__ import annotations

import logging
from abc import ABC, abstractmethod
from pathlib import Path
from typing import Any, Dict, List, Optional

from scripts.agents.schemas.handoff import HandoffRecord, HandoffStatus
from scripts.infra.checkpoint import CheckpointManager
from scripts.infra.state import AgentState


class BaseAgent(ABC):
    """Abstract base class shared by all workflow agents."""

    def __init__(self, workspace: Path, config: Optional[Dict[str, Any]] = None):
        self.workspace = Path(workspace)
        self.config: Dict[str, Any] = config or {}
        self.state = AgentState(self.workspace / ".agent_state.json")
        self.checkpoint_mgr = CheckpointManager(self.workspace / ".checkpoints")
        self.logger = logging.getLogger(f"agent.{self.get_role()}")

    @abstractmethod
    def execute(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Execute agent logic and return handoff dictionary."""

    @abstractmethod
    def get_role(self) -> str:
        """Return role identifier string for this agent."""

    def save_checkpoint(self, stage: str, state: Dict[str, Any]) -> None:
        """Save checkpoint state for a workflow stage."""
        self.checkpoint_mgr.save_checkpoint(stage, state)

    def load_checkpoint(self, stage: str) -> Optional[Dict[str, Any]]:
        """Load checkpoint state for a workflow stage."""
        return self.checkpoint_mgr.load_checkpoint(stage=stage)

    def create_handoff(
        self,
        to_agent: str,
        stage: str,
        status: HandoffStatus,
        data: Optional[Dict[str, Any]] = None,
        warnings: Optional[List[str]] = None,
        errors: Optional[List[str]] = None,
        recommendations: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        """Create a standardized handoff payload for downstream agents."""
        handoff = HandoffRecord(
            from_agent=self.get_role(),
            to_agent=to_agent,
            status=status,
            stage=stage,
            data=data or {},
            warnings=warnings or [],
            errors=errors or [],
            recommendations=recommendations or [],
        )
        return handoff.to_dict()
