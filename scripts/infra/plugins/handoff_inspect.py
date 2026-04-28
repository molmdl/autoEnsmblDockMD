#!/usr/bin/env python3
"""Handoff inspector plugin - parses latest handoff and provides next-action guidance."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[3]))

from scripts.agents.schemas.handoff import HandoffRecord, HandoffStatus


STATUS_MAP = {
    "success": "SUCCESS",
    "failure": "FAILED",
    "needs_review": "NEEDS_REVIEW",
    "blocked": "BLOCKED",
}


def _format_items(items: list[str]) -> str:
    """Render warning/error list into a concise string."""
    if not items:
        return "none"
    return "; ".join(items)


def inspect_latest_handoff(workspace: Path) -> HandoffRecord:
    """Inspect latest handoff JSON and return normalized guidance record."""
    record = HandoffRecord(
        from_agent="handoff_inspector",
        to_agent="orchestrator",
        stage="handoff_inspection",
    )

    if not workspace.exists() or not workspace.is_dir():
        record.status = HandoffStatus.FAILURE
        record.errors.append(f"Workspace unreadable or missing: {workspace}")
        record.recommendations.append("Provide a readable --workspace directory path.")
        return record

    handoff_dir = workspace / ".handoffs"
    if not handoff_dir.exists():
        record.status = HandoffStatus.SUCCESS
        record.warnings.append("No handoffs found (new workspace)")
        record.data.update(
            {
                "latest_stage": "none",
                "latest_status": "NONE",
                "handoff_file": "",
                "next_action": "Run workspace initialization",
            }
        )
        return record

    handoffs = list(handoff_dir.glob("*.json"))
    if not handoffs:
        record.status = HandoffStatus.SUCCESS
        record.warnings.append("No handoffs found (new workspace)")
        record.data.update(
            {
                "latest_stage": "none",
                "latest_status": "NONE",
                "handoff_file": "",
                "next_action": "Run workspace initialization",
            }
        )
        return record

    latest = max(handoffs, key=lambda p: p.stat().st_mtime)
    try:
        payload = json.loads(latest.read_text(encoding="utf-8"))
    except Exception as exc:
        record.status = HandoffStatus.FAILURE
        record.errors.append(f"Failed to parse latest handoff JSON ({latest}): {exc}")
        record.recommendations.append("Repair or remove malformed handoff JSON file.")
        return record

    stage = str(payload.get("stage", "unknown"))
    status_raw = str(payload.get("status", "unknown"))
    normalized_status = STATUS_MAP.get(status_raw, "UNKNOWN")
    warnings = [str(w) for w in payload.get("warnings", [])]
    errors = [str(e) for e in payload.get("errors", [])]
    recommendations = [str(r) for r in payload.get("recommendations", [])]

    if normalized_status == "SUCCESS":
        next_action = f"Stage {stage} completed successfully. Proceed to next stage."
    elif normalized_status == "NEEDS_REVIEW":
        next_action = f"Stage {stage} needs review. Check warnings: {_format_items(warnings)}"
        record.warnings.extend(warnings)
    elif normalized_status in {"FAILED", "BLOCKED"}:
        next_action = f"Stage {stage} failed. Review errors: {_format_items(errors)}"
        record.errors.extend(errors)
        record.recommendations.extend(recommendations)
    else:
        next_action = (
            f"Stage {stage} has unrecognized status '{status_raw}'. "
            "Inspect handoff details before proceeding."
        )
        record.warnings.append(
            f"Unrecognized handoff status '{status_raw}' in {latest.name}."
        )

    record.status = HandoffStatus.SUCCESS
    record.data.update(
        {
            "latest_stage": stage,
            "latest_status": normalized_status,
            "handoff_file": str(latest.resolve()),
            "next_action": next_action,
        }
    )
    return record


def main() -> int:
    """CLI entrypoint for handoff inspector plugin."""
    parser = argparse.ArgumentParser(
        description="Inspect latest handoff and provide normalized next-action guidance."
    )
    parser.add_argument("--workspace", required=True, help="Workspace directory to inspect")
    args = parser.parse_args()

    record = inspect_latest_handoff(Path(args.workspace))
    print(json.dumps(record.to_dict(), indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
