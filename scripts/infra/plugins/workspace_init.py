#!/usr/bin/env python3
"""Workspace initialization plugin for template-based setup."""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[3]))

from scripts.agents.schemas.handoff import HandoffRecord, HandoffStatus


def initialize_workspace(
    template_dir: Path,
    target_dir: Path,
    force: bool = False,
) -> HandoffRecord:
    """Initialize an isolated workspace from a validated template directory."""
    record = HandoffRecord(
        from_agent="workspace_init",
        to_agent="runner",
        stage="workspace_init",
    )

    if target_dir.exists() and not force:
        record.status = HandoffStatus.BLOCKED
        record.errors.append(f"Target workspace already exists: {target_dir}")
        record.recommendations.append(
            "Use --force to overwrite existing workspace or choose a new --target path."
        )
        return record

    if not template_dir.exists() or not template_dir.is_dir():
        record.status = HandoffStatus.FAILURE
        record.errors.append(f"Template directory not found: {template_dir}")
        record.recommendations.append("Provide a valid --template directory path.")
        return record

    required_structure = ["config.ini", "mdp/rec", "mdp/com"]
    missing_structure = [
        path for path in required_structure if not (template_dir / path).exists()
    ]
    if missing_structure:
        record.status = HandoffStatus.FAILURE
        record.errors.append(
            "Template is missing required files/directories: "
            + ", ".join(missing_structure)
        )
        record.recommendations.append(
            "Ensure template contains config.ini and MDP directories (mdp/rec, mdp/com)."
        )
        return record

    critical_inputs = [
        "rec.pdb",
        "ref.pdb",
        "dzp",
        "ibp",
    ]
    for item in critical_inputs:
        if not (template_dir / item).exists():
            record.warnings.append(
                f"Potentially critical input missing from template: {item}"
            )

    try:
        if target_dir.exists() and force:
            shutil.rmtree(target_dir)

        shutil.copytree(template_dir, target_dir, dirs_exist_ok=force)
    except Exception as exc:  # pragma: no cover - defensive error path
        record.status = HandoffStatus.FAILURE
        record.errors.append(f"Workspace copy failed: {exc}")
        record.recommendations.append(
            "Check permissions and verify source/target paths are accessible."
        )
        return record

    created_dirs = sorted(
        str(path.relative_to(target_dir))
        for path in target_dir.iterdir()
        if path.is_dir()
    )

    record.status = HandoffStatus.SUCCESS
    record.data["workspace_path"] = str(target_dir.resolve())
    record.data["template_source"] = str(template_dir.resolve())
    record.metadata["created_dirs"] = created_dirs

    return record


def main() -> int:
    """CLI entrypoint for workspace initialization."""
    parser = argparse.ArgumentParser(
        description="Initialize isolated workspace from template."
    )
    parser.add_argument("--template", required=True, help="Template directory path")
    parser.add_argument("--target", required=True, help="Target workspace path")
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite target if it already exists",
    )
    args = parser.parse_args()

    record = initialize_workspace(
        template_dir=Path(args.template),
        target_dir=Path(args.target),
        force=args.force,
    )
    print(json.dumps(record.to_dict(), indent=2))

    if record.status == HandoffStatus.SUCCESS:
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
