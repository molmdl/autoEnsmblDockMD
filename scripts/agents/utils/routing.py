"""Stage-to-agent routing utilities for workflow orchestration."""

from __future__ import annotations

from typing import Dict, List

from scripts.agents.schemas.state import WorkflowStage


STAGE_AGENT_MAP: Dict[WorkflowStage, str] = {
    WorkflowStage.INIT: "orchestrator",
    WorkflowStage.REC_PREP: "runner",
    WorkflowStage.REC_MD: "runner",
    WorkflowStage.REC_CLUSTER: "runner",
    WorkflowStage.DOCK_PREP: "runner",
    WorkflowStage.DOCK_RUN: "runner",
    WorkflowStage.COM_PREP: "runner",
    WorkflowStage.COM_MD: "runner",
    WorkflowStage.COM_MMPBSA: "runner",
    WorkflowStage.COM_ANA: "analyzer",
    WorkflowStage.COMPLETE: "orchestrator",
}


def get_agent_for_stage(stage: WorkflowStage) -> str:
    """Return the role identifier that handles a workflow stage."""
    return STAGE_AGENT_MAP[stage]


def get_stages_for_agent(role: str) -> List[WorkflowStage]:
    """Return ordered stages handled by a given role identifier."""
    return [stage for stage, mapped_role in STAGE_AGENT_MAP.items() if mapped_role == role]
