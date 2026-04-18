#!/usr/bin/env python3
"""
Bypass parmed angle type 3 incompatibility for gmx_mmpbsa.

This script:
1. Changes angle function type 3 to type 1 in ligand topology,
   adding a comment for tracking.
2. Optionally updates main topology to include the bypass ligand topology.

Generalized CLI:
    python scripts/com/bypass_angle_type3.py --input ligand.itp --output bypass_ligand.itp
    python scripts/com/bypass_angle_type3.py --input ligand.itp --topology sys.top
    python scripts/com/bypass_angle_type3.py --config config.ini
"""

from __future__ import annotations

import argparse
import configparser
import os
import pathlib
import re
import sys
from dataclasses import dataclass


@dataclass
class Options:
    input_itp: str
    output_itp: str
    topology: str | None
    topology_output: str | None
    dry_run: bool


def _exists_file(path: str, label: str) -> None:
    if not os.path.exists(path):
        raise FileNotFoundError(f"{label} not found: {path}")
    if not os.path.isfile(path):
        raise ValueError(f"{label} is not a file: {path}")


def _looks_like_itp(path: str) -> bool:
    with open(path, "r", encoding="utf-8") as handle:
        for line in handle:
            stripped = line.strip().lower()
            if stripped.startswith("[ angles ]"):
                return True
            if stripped.startswith("[ atoms ]"):
                return True
    return False


def modify_ligand_itp(input_file: str, output_file: str) -> int:
    """
    Change angle function type 3 to type 1 in ligand topology.

    Returns the number of modifications made.
    """
    modified_count = 0
    in_angles_section = False
    lines_out = []

    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    for line in lines:
        stripped = line.strip()

        if stripped.startswith('[ angles ]'):
            in_angles_section = True
            lines_out.append(line)
            continue

        if stripped.startswith('[') and stripped.endswith(']'):
            in_angles_section = False
            lines_out.append(line)
            continue

        if in_angles_section and stripped and not stripped.startswith(';'):
            parts = line.split()
            if len(parts) >= 4:
                func_type = parts[3]
                if func_type == '3':
                    parts[3] = '1'

                    original_comment = ''
                    comment_idx = line.find(';')
                    if comment_idx != -1:
                        original_comment = line[comment_idx:].rstrip()

                    indent = line[:len(line) - len(line.lstrip())]
                    data_part = '     '.join(parts[:4]) + '     ' + '     '.join(parts[4:])

                    if 'type 3 to 1' not in original_comment:
                        if original_comment:
                            new_line = indent + data_part + ' type 3 to 1 for parmed bypass\n'
                        else:
                            new_line = indent + data_part + '    ; type 3 to 1 for parmed bypass\n'
                    else:
                        new_line = indent + data_part + '\n'

                    lines_out.append(new_line)
                    modified_count += 1
                    continue

        lines_out.append(line)

    with open(output_file, 'w', encoding='utf-8') as f:
        f.writelines(lines_out)

    return modified_count


def find_ligand_include(lines: list[str], ligand_filename: str) -> str | None:
    """
    Find ligand include line in main topology matching the ligand filename.
    Returns include filename or None if not found.
    """
    include_pattern = re.compile(r'#include\s+["\']([^"\']+\.itp)["\']')
    ligand_basename = os.path.basename(ligand_filename)

    for line in lines:
        match = include_pattern.search(line)
        if match:
            include_file = match.group(1)
            include_basename = os.path.basename(include_file)
            if include_basename == ligand_basename:
                return include_file

    return None


def modify_main_top(input_file: str, output_file: str, ligand_filename: str) -> tuple[bool, str | None]:
    """
    Change topology include of ligand in main topology.

    Returns (success, include_filename_used).
    """
    lines_out = []

    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    target_include = find_ligand_include(lines, ligand_filename)
    if target_include is None:
        return False, None

    bypass_include = 'bypass_' + os.path.basename(target_include)
    modified = False

    for line in lines:
        include_pattern = re.compile(r'(#include\s+["\'])' + re.escape(target_include) + r'(["\'])')
        match = include_pattern.search(line)
        if match:
            new_line = include_pattern.sub(r'\1' + bypass_include + r'\2', line)
            lines_out.append(new_line)
            modified = True
        else:
            lines_out.append(line)

    with open(output_file, 'w', encoding='utf-8') as f:
        f.writelines(lines_out)

    return modified, target_include


def get_output_path(input_path: str, prefix: str = 'bypass_') -> str:
    """Generate output path with prefix added to filename."""
    dirname = os.path.dirname(input_path)
    basename = os.path.basename(input_path)
    return os.path.join(dirname, prefix + basename)


def _load_config(path: str) -> dict[str, str]:
    cfg = configparser.ConfigParser()
    read_files = cfg.read(path)
    if not read_files:
        raise FileNotFoundError(f"Config file not found or unreadable: {path}")

    values: dict[str, str] = {}
    if cfg.has_section("bypass_angle"):
        for key, val in cfg.items("bypass_angle"):
            values[key.strip().lower()] = val.strip()
    if cfg.has_section("complex"):
        for key, val in cfg.items("complex"):
            values.setdefault(key.strip().lower(), val.strip())
    return values


def _resolve_options(args: argparse.Namespace) -> Options:
    cfg_values: dict[str, str] = {}
    if args.config:
        cfg_values = _load_config(args.config)

    input_itp = args.input or cfg_values.get("input") or cfg_values.get("ligand_itp")
    if not input_itp:
        raise ValueError("Input ligand ITP is required (--input or [bypass_angle]/[complex] input key in --config)")

    output_itp = args.output or cfg_values.get("output")
    if not output_itp:
        output_itp = get_output_path(input_itp)

    topology = args.topology or cfg_values.get("topology")
    topology_output = args.topology_output or cfg_values.get("topology_output")

    if topology and not topology_output:
        topology_output = get_output_path(topology)

    return Options(
        input_itp=os.path.abspath(input_itp),
        output_itp=os.path.abspath(output_itp),
        topology=os.path.abspath(topology) if topology else None,
        topology_output=os.path.abspath(topology_output) if topology_output else None,
        dry_run=bool(args.dry_run),
    )


def _validate_inputs(opts: Options) -> None:
    _exists_file(opts.input_itp, "Input ligand ITP")
    if not _looks_like_itp(opts.input_itp):
        raise ValueError(f"Input does not look like a valid ITP topology: {opts.input_itp}")

    if opts.topology is not None:
        _exists_file(opts.topology, "Main topology")


def _print_plan(opts: Options) -> None:
    print("Bypass angle type 3 execution plan:")
    print(f"  input ITP    : {opts.input_itp}")
    print(f"  output ITP   : {opts.output_itp}")
    if opts.topology:
        print(f"  input TOP    : {opts.topology}")
        print(f"  output TOP   : {opts.topology_output}")
    else:
        print("  input TOP    : <none>")
    print(f"  dry-run      : {opts.dry_run}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Bypass parmed angle type 3 incompatibility for gmx_mmpbsa."
    )
    parser.add_argument("--input", help="Ligand topology file (.itp)")
    parser.add_argument("--output", help="Output ligand topology file (default: bypass_<input>)")
    parser.add_argument("--topology", help="Main topology file (.top) to update include paths")
    parser.add_argument("--topology-output", help="Output for updated topology (default: bypass_<topology>)")
    parser.add_argument("--config", help="INI config file. Reads [bypass_angle] or [complex] keys")
    parser.add_argument("--dry-run", action="store_true", help="Validate inputs and print planned actions only")

    args = parser.parse_args()

    try:
        opts = _resolve_options(args)
        _validate_inputs(opts)
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        sys.exit(1)

    _print_plan(opts)
    if opts.dry_run:
        return

    pathlib.Path(opts.output_itp).parent.mkdir(parents=True, exist_ok=True)
    modified_count = modify_ligand_itp(opts.input_itp, opts.output_itp)
    print(f"Modified angle entries: {modified_count}")
    print(f"Wrote ligand ITP: {opts.output_itp}")

    if opts.topology and opts.topology_output:
        pathlib.Path(opts.topology_output).parent.mkdir(parents=True, exist_ok=True)
        modified, include_used = modify_main_top(
            opts.topology,
            opts.topology_output,
            os.path.basename(opts.input_itp),
        )
        if modified and include_used:
            print(f"Updated topology include: {include_used} -> bypass_{os.path.basename(include_used)}")
            print(f"Wrote main topology: {opts.topology_output}")
        else:
            print("Warning: No ligand include found to modify in topology")


if __name__ == '__main__':
    main()
