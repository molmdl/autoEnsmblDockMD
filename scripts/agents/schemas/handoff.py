"""Handoff schemas for communication between workflow agents."""

from __future__ import annotations

import json
import os
import tempfile
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Dict, List


class HandoffStatus(Enum):
    """Status values for an agent handoff record."""

    SUCCESS = "success"
    FAILURE = "failure"
    NEEDS_REVIEW = "needs_review"
    BLOCKED = "blocked"


@dataclass
class HandoffRecord:
    """Structured handoff payload exchanged between agents."""

    from_agent: str
    to_agent: str
    timestamp: str = field(default_factory=lambda: datetime.utcnow().isoformat() + "Z")

    status: HandoffStatus = HandoffStatus.SUCCESS
    stage: str = ""

    data: Dict[str, Any] = field(default_factory=dict)
    warnings: List[str] = field(default_factory=list)
    errors: List[str] = field(default_factory=list)
    recommendations: List[str] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        """Serialize record to a JSON-compatible dictionary."""
        return {
            "from_agent": self.from_agent,
            "to_agent": self.to_agent,
            "timestamp": self.timestamp,
            "status": self.status.value,
            "stage": self.stage,
            "data": self.data,
            "warnings": self.warnings,
            "errors": self.errors,
            "recommendations": self.recommendations,
            "metadata": self.metadata,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "HandoffRecord":
        """Deserialize a record from dictionary form."""
        payload = dict(data)
        status_value = payload.get("status", HandoffStatus.SUCCESS.value)
        payload["status"] = HandoffStatus(status_value)
        return cls(**payload)

    def save(self, filepath: str | Path) -> None:
        """Persist handoff record as JSON using atomic write."""
        path = Path(filepath)
        path.parent.mkdir(parents=True, exist_ok=True)

        with tempfile.NamedTemporaryFile(
            mode="w",
            dir=path.parent,
            delete=False,
            suffix=".json",
        ) as tmp:
            json.dump(self.to_dict(), tmp, indent=2)
            tmp_path = tmp.name

        os.replace(tmp_path, path)

    @classmethod
    def load(cls, filepath: str | Path) -> "HandoffRecord":
        """Load handoff record from a JSON file."""
        path = Path(filepath)
        with open(path, "r", encoding="utf-8") as handle:
            payload = json.load(handle)
        return cls.from_dict(payload)
