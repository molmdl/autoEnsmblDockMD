"""Orchestrator agent implementation for workflow stage routing."""

from __future__ import annotations

from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

from scripts.agents.base import BaseAgent
from scripts.agents.schemas.handoff import HandoffStatus
from scripts.agents.schemas.state import WorkflowStage
from scripts.agents.utils.routing import get_agent_for_stage
from scripts.infra.verification import VerificationGate, list_gates


class OrchestratorAgent(BaseAgent):
    """Workflow state-machine agent coordinating stage execution."""

    def get_role(self) -> str:
        """Return role identifier for this agent."""
        return "orchestrator"

    def execute(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Route a workflow stage to the responsible downstream agent."""
        stage = self._parse_stage(input_data["stage"])
        target_agent = get_agent_for_stage(stage)

        self.state.set("workflow.current_stage", stage.value)

        previous_stage = self._get_previous_stage(stage)
        if previous_stage and not self.check_gate(previous_stage.value):
            return self.create_handoff(
                to_agent=target_agent,
                stage=stage.value,
                status=HandoffStatus.BLOCKED,
                data={
                    "stage": stage.value,
                    "target_agent": target_agent,
                    "blocked_by_gate": previous_stage.value,
                },
                warnings=[f"Verification gate for '{previous_stage.value}' is not approved."],
                errors=[f"Cannot proceed to '{stage.value}' until '{previous_stage.value}' gate is approved."],
            )

        return self.create_handoff(
            to_agent=target_agent,
            stage=stage.value,
            status=HandoffStatus.SUCCESS,
            data={
                "stage": stage.value,
                "target_agent": target_agent,
            },
        )

    def advance_stage(self, current_stage: WorkflowStage) -> Optional[WorkflowStage]:
        """Return the next workflow stage, or None when complete."""
        ordered = list(WorkflowStage)
        if current_stage == WorkflowStage.COMPLETE:
            return None

        idx = ordered.index(current_stage)
        if idx + 1 >= len(ordered):
            return None

        next_stage = ordered[idx + 1]
        return None if next_stage == WorkflowStage.COMPLETE else next_stage

    def create_verification_gate(
        self,
        stage: str,
        description: str,
        metadata: Dict[str, Any] = None,
        output_paths: List[str] = None,
    ) -> None:
        """Create a verification gate for a workflow stage."""
        gate = VerificationGate(stage_name=stage, gate_dir=str(self.workspace / ".gates"))
        gate.create_gate(
            description=description,
            metadata=metadata or {},
            output_paths=output_paths or [],
        )

    def check_gate(self, stage: str) -> bool:
        """Return True when stage gate is approved or does not exist."""
        gate = VerificationGate(stage_name=stage, gate_dir=str(self.workspace / ".gates"))
        state = gate.get_state()
        if state is None:
            return True
        return gate.can_proceed()

    def get_workflow_status(self) -> Dict[str, Any]:
        """Return structured workflow status from persisted orchestrator state."""
        current_stage = self.state.get("workflow.current_stage", WorkflowStage.INIT.value)
        completed_stages = self.state.get("workflow.completed_stages", [])

        pending_gates = [
            gate["stage"]
            for gate in list_gates(str(self.workspace / ".gates"))
            if gate.get("state") != "approved"
        ]

        return {
            "current_stage": current_stage,
            "completed_stages": completed_stages,
            "pending_gates": pending_gates,
            "last_updated": datetime.utcnow().isoformat() + "Z",
        }

    def initialize_workflow(self) -> Dict[str, Any]:
        """Initialize workflow state and return handoff to first stage."""
        self.state.update(
            {
                "workflow.current_stage": WorkflowStage.INIT.value,
                "workflow.completed_stages": [],
            }
        )
        self.save_checkpoint(
            stage=WorkflowStage.INIT.value,
            state={"current_stage": WorkflowStage.INIT.value, "completed_stages": []},
        )

        first_stage = self.advance_stage(WorkflowStage.INIT)
        if first_stage is None:
            return self.create_handoff(
                to_agent="orchestrator",
                stage=WorkflowStage.COMPLETE.value,
                status=HandoffStatus.SUCCESS,
                data={"stage": WorkflowStage.COMPLETE.value, "target_agent": "orchestrator"},
            )

        target_agent = get_agent_for_stage(first_stage)
        return self.create_handoff(
            to_agent=target_agent,
            stage=first_stage.value,
            status=HandoffStatus.SUCCESS,
            data={
                "stage": first_stage.value,
                "target_agent": target_agent,
                "workflow_initialized": True,
            },
        )

    def _parse_stage(self, stage_value: Any) -> WorkflowStage:
        """Normalize a stage value into WorkflowStage enum."""
        if isinstance(stage_value, WorkflowStage):
            return stage_value
        if not isinstance(stage_value, str):
            raise ValueError("stage must be a WorkflowStage or stage string")
        return WorkflowStage(stage_value)

    def _get_previous_stage(self, stage: WorkflowStage) -> Optional[WorkflowStage]:
        """Return previous stage from enum order, if any."""
        ordered = list(WorkflowStage)
        idx = ordered.index(stage)
        if idx <= 0:
            return None
        return ordered[idx - 1]
