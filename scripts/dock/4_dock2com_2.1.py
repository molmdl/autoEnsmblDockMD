#!/usr/bin/env python3
"""ITP parsing utilities for dock-to-complex conversion workflows."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def parse_itp(path: str | Path) -> dict[str, list[str]]:
    """Parse an ITP file into section -> lines (comments removed)."""
    current = ""
    sections: dict[str, list[str]] = {}
    for raw in Path(path).read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw.strip()
        if not line or line.startswith(";"):
            continue
        if line.startswith("[") and line.endswith("]"):
            current = line.strip("[]").strip().lower()
            sections.setdefault(current, [])
            continue
        if line.startswith("#"):
            continue
        if current:
            clean = raw.split(";", 1)[0].strip()
            if clean:
                sections[current].append(clean)
    return sections


def parse_itp_section(path: str | Path, section: str) -> list[str]:
    return parse_itp(path).get(section.lower(), [])


def _write_output(lines: list[str], output: Path | None) -> None:
    if output is None:
        for line in lines:
            print(line)
        return
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Parse ITP sections")
    parser.add_argument("--itp", type=Path, required=True, help="Input ITP file")
    parser.add_argument(
        "--section",
        type=str,
        default="atoms",
        help="ITP section to extract (atoms|bonds|angles|dihedrals|pairs|all)",
    )
    parser.add_argument("--output", type=Path, help="Optional output file")
    parser.add_argument("--json", action="store_true", help="Write parsed output as JSON")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    sections = parse_itp(args.itp)
    requested = args.section.lower()

    if args.json:
        payload = sections if requested == "all" else {requested: sections.get(requested, [])}
        text = json.dumps(payload, indent=2)
        if args.output:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(text + "\n", encoding="utf-8")
        else:
            print(text)
        return 0

    if requested == "all":
        lines: list[str] = []
        for key, items in sections.items():
            lines.append(f"[{key}]")
            lines.extend(items)
            lines.append("")
        _write_output(lines, args.output)
        return 0

    _write_output(sections.get(requested, []), args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
