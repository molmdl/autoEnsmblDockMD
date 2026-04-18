"""Workflow state schemas for agent orchestration."""

from enum import Enum


class WorkflowStage(Enum):
    """Canonical workflow stages mapped to pipeline execution."""

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
