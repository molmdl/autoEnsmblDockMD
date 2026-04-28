#!/usr/bin/env python3
"""Group ID consistency checker - validates MM/PBSA group IDs against index.ndx."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[3]))

from scripts.agents.schemas.handoff import HandoffRecord, HandoffStatus


GROUP_HEADER_RE = re.compile(r"^\s*\[(.+)\]\s*$")
AUTODETECT_RECEPTOR = ("Protein", "Receptor")
AUTODETECT_LIGAND = ("LIG", "Ligand", "Other")


def parse_index_groups(index_file: Path) -> dict[str, int]:
    """Return group-name -> numeric group-id (0-based, header order)."""
    groups: dict[str, int] = {}
    ordered: list[str] = []
    for line in index_file.read_text(encoding="utf-8").splitlines():
        match = GROUP_HEADER_RE.match(line)
        if not match:
            continue
        group_name = match.group(1).strip()
        if group_name in groups:
            continue
        groups[group_name] = len(ordered)
        ordered.append(group_name)
    return groups


def parse_group_file(groups_file: Path) -> tuple[str | None, str | None]:
    """Parse receptor/ligand group names from mmpbsa_groups.dat.

    Supports both key-value format and simple line-based fallback.
    """
    receptor_name: str | None = None
    ligand_name: str | None = None
    data_lines: list[str] = []

    for raw_line in groups_file.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        data_lines.append(line)
        if "=" in line:
            key, value = [part.strip() for part in line.split("=", 1)]
            if key == "receptor_group":
                receptor_name = value
            elif key == "ligand_group":
                ligand_name = value

    # Fallback for older line-based format: lines 2-3 are names
    if receptor_name is None and len(data_lines) >= 2 and "=" not in data_lines[1]:
        receptor_name = data_lines[1]
    if ligand_name is None and len(data_lines) >= 3 and "=" not in data_lines[2]:
        ligand_name = data_lines[2]

    return receptor_name, ligand_name


def _auto_detect_group_id(groups: dict[str, int], patterns: tuple[str, ...]) -> int | None:
    """Pick first index group matching any pattern (exact, then substring)."""
    for pattern in patterns:
        for name, gid in groups.items():
            if name == pattern:
                return gid
    for pattern in patterns:
        lowered = pattern.lower()
        for name, gid in groups.items():
            if lowered in name.lower():
                return gid
    return None


def validate_group_ids(workspace: Path) -> HandoffRecord:
    """Validate MM/PBSA receptor/ligand group consistency against index.ndx."""
    record = HandoffRecord(
        from_agent="group_id_check",
        to_agent="runner",
        stage="group_id_check",
    )

    index_file = workspace / "index.ndx"
    groups_file = workspace / "mmpbsa_groups.dat"

    if not index_file.exists():
        record.status = HandoffStatus.FAILURE
        record.errors.append("index.ndx not found - run trj4mmpbsa first")
        record.recommendations.append("Run scripts/com/2_trj4mmpbsa.sh to generate index.ndx.")
        record.data = {
            "validated": False,
            "receptor_group_id": None,
            "ligand_group_id": None,
        }
        return record

    groups = parse_index_groups(index_file)
    if not groups:
        record.status = HandoffStatus.FAILURE
        record.errors.append(f"No groups found in index file: {index_file}")
        record.recommendations.append("Regenerate index.ndx and verify gmx make_ndx completed.")
        record.data = {
            "validated": False,
            "receptor_group_id": None,
            "ligand_group_id": None,
        }
        return record

    receptor_group_id: int | None = None
    ligand_group_id: int | None = None
    validated = False

    if groups_file.exists():
        receptor_name, ligand_name = parse_group_file(groups_file)
        if receptor_name:
            if receptor_name in groups:
                receptor_group_id = groups[receptor_name]
            else:
                record.warnings.append(
                    f"Receptor group '{receptor_name}' from mmpbsa_groups.dat not found in index.ndx"
                )
        else:
            record.warnings.append("Could not parse receptor group name from mmpbsa_groups.dat")

        if ligand_name:
            if ligand_name in groups:
                ligand_group_id = groups[ligand_name]
            else:
                record.warnings.append(
                    f"Ligand group '{ligand_name}' from mmpbsa_groups.dat not found in index.ndx"
                )
        else:
            record.warnings.append("Could not parse ligand group name from mmpbsa_groups.dat")

        validated = receptor_group_id is not None and ligand_group_id is not None
    else:
        record.metadata.setdefault("info", []).append(
            "mmpbsa_groups.dat not found - will be generated from index.ndx"
        )
        receptor_group_id = _auto_detect_group_id(groups, AUTODETECT_RECEPTOR)
        ligand_group_id = _auto_detect_group_id(groups, AUTODETECT_LIGAND)

        suggestions: list[str] = []
        if receptor_group_id is None:
            suggestions.append("Unable to auto-detect receptor group (expected Protein/Receptor)")
        else:
            suggestions.append(f"Suggested receptor_group_id={receptor_group_id}")
        if ligand_group_id is None:
            suggestions.append("Unable to auto-detect ligand group (expected LIG/Ligand/Other)")
        else:
            suggestions.append(f"Suggested ligand_group_id={ligand_group_id}")
        record.recommendations.extend(suggestions)

    record.data = {
        "validated": validated,
        "receptor_group_id": receptor_group_id,
        "ligand_group_id": ligand_group_id,
    }
    record.metadata["index_group_count"] = len(groups)
    record.metadata["index_file"] = str(index_file)
    record.metadata["groups_file"] = str(groups_file)

    if record.errors:
        record.status = HandoffStatus.FAILURE
    elif record.warnings:
        record.status = HandoffStatus.NEEDS_REVIEW
    else:
        record.status = HandoffStatus.SUCCESS

    return record


def main() -> int:
    """CLI entrypoint for group ID consistency checker."""
    parser = argparse.ArgumentParser(
        description="Validate MM/PBSA group IDs against index.ndx"
    )
    parser.add_argument("--workspace", required=True, help="Workspace path containing index.ndx")
    args = parser.parse_args()

    record = validate_group_ids(Path(args.workspace).resolve())
    print(json.dumps(record.to_dict(), indent=2))

    if record.status in {HandoffStatus.SUCCESS, HandoffStatus.NEEDS_REVIEW}:
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
