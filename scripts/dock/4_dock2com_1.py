#!/usr/bin/env python3
"""Convert a selected docking pose from SDF to GRO.

Supports both CLI usage and library mode.
"""

from __future__ import annotations

import argparse
import configparser
import shutil
import subprocess
from pathlib import Path


DEFAULT_SECTION = "docking"


def _load_overrides(config_path: Path) -> dict[str, str]:
    parser = configparser.ConfigParser()
    parser.read(config_path)
    if not parser.has_section(DEFAULT_SECTION):
        return {}
    return {k: v for k, v in parser.items(DEFAULT_SECTION)}


def _write_gro_from_records(coords: list[tuple[str, float, float, float]], output_path: Path, title: str) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8") as handle:
        handle.write(f"{title}\n")
        handle.write(f"{len(coords)}\n")
        for idx, (symbol, x, y, z) in enumerate(coords, start=1):
            atom_name = f"{symbol[:2]}{idx % 1000}"[:5]
            handle.write(
                f"{1:>5d}{'LIG':<5s}{atom_name:>5s}{idx:>5d}"
                f"{(x * 0.1):>8.3f}{(y * 0.1):>8.3f}{(z * 0.1):>8.3f}\n"
            )
        handle.write("   0.00000   0.00000   0.00000\n")


def _convert_with_rdkit(sdf_path: Path, output_path: Path, pose_index: int) -> bool:
    try:
        from rdkit import Chem
    except ImportError:
        return False

    supplier = Chem.SDMolSupplier(str(sdf_path), removeHs=False)
    molecule = None
    valid_pose_count = 0
    for candidate in supplier:
        if candidate is None:
            continue
        valid_pose_count += 1
        if valid_pose_count == pose_index:
            molecule = candidate
            break

    if molecule is None:
        raise IndexError(f"pose-index {pose_index} out of range (1..{valid_pose_count})")

    conf = molecule.GetConformer()
    coords: list[tuple[str, float, float, float]] = []
    for atom in molecule.GetAtoms():
        pos = conf.GetAtomPosition(atom.GetIdx())
        coords.append((atom.GetSymbol(), float(pos.x), float(pos.y), float(pos.z)))

    _write_gro_from_records(coords, output_path, f"Converted from {sdf_path.name} pose {pose_index}")
    return True


def _convert_with_obabel(sdf_path: Path, output_path: Path, pose_index: int) -> bool:
    if shutil.which("obabel") is None:
        return False
    cmd = [
        "obabel",
        "-isdf",
        str(sdf_path),
        "-ogro",
        "-O",
        str(output_path),
        "-f",
        str(pose_index),
        "-l",
        str(pose_index),
    ]
    subprocess.run(cmd, check=True)
    return True


def convert_pose_to_gro(sdf: str | Path, output: str | Path, pose_index: int = 1) -> Path:
    sdf_path = Path(sdf)
    out_path = Path(output)

    if not sdf_path.exists():
        raise FileNotFoundError(f"SDF file not found: {sdf_path}")
    if pose_index < 1:
        raise ValueError("pose-index must be >= 1")

    if _convert_with_rdkit(sdf_path, out_path, pose_index):
        return out_path
    if _convert_with_obabel(sdf_path, out_path, pose_index):
        return out_path

    raise RuntimeError("Neither RDKit nor obabel is available for SDF->GRO conversion")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Convert selected SDF pose to GRO")
    parser.add_argument("--sdf", type=Path, help="Input SDF file (possibly multi-pose)")
    parser.add_argument("--output", type=Path, help="Output GRO file")
    parser.add_argument("--pose-index", type=int, default=1, help="1-based pose index (default: 1)")
    parser.add_argument("--config", type=Path, help="Optional config.ini with [docking] sdf/output/pose_index")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    sdf = args.sdf
    output = args.output
    pose_index = args.pose_index

    if args.config:
        overrides = _load_overrides(args.config)
        if sdf is None and "sdf" in overrides:
            sdf = Path(overrides["sdf"])
        if output is None and "output" in overrides:
            output = Path(overrides["output"])
        if "pose_index" in overrides and args.pose_index == 1:
            pose_index = int(overrides["pose_index"])

    if sdf is None or output is None:
        parser.error("--sdf and --output are required (directly or via --config)")

    converted = convert_pose_to_gro(sdf=sdf, output=output, pose_index=pose_index)
    print(f"Wrote GRO: {converted}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
