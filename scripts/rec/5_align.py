#!/usr/bin/env python3
"""Align receptor ensemble structures to a reference complex using MDAnalysis."""

from __future__ import annotations

import argparse
import configparser
import glob
from pathlib import Path
from typing import Iterable, Sequence

import MDAnalysis as mda
from MDAnalysis.analysis import align
from MDAnalysis.analysis.rms import rmsd


def _split_list(value: str) -> list[str]:
    return [item.strip() for item in value.replace("\n", ",").split(",") if item.strip()]


def _load_config(path: Path) -> dict[str, str]:
    cfg = configparser.ConfigParser()
    if not cfg.read(path):
        raise FileNotFoundError(f"Could not read config file: {path}")
    if "receptor" not in cfg:
        return {}
    return {k: v for k, v in cfg["receptor"].items()}


def _resolve_structures(items: Sequence[str]) -> list[Path]:
    resolved: list[Path] = []
    for item in items:
        matches = sorted(glob.glob(item))
        if matches:
            resolved.extend(Path(m) for m in matches)
        else:
            resolved.append(Path(item))
    seen: set[Path] = set()
    unique: list[Path] = []
    for path in resolved:
        if path not in seen:
            seen.add(path)
            unique.append(path)
    return unique


def align_structures(
    structures: Iterable[Path],
    reference: Path,
    output_dir: Path,
    selection: str = "backbone",
    prefix: str = "",
) -> list[tuple[Path, Path, float, float]]:
    """Align each structure to reference and return RMSD stats.

    Returns tuples of (input_path, output_path, rmsd_before, rmsd_after).
    """
    ref = mda.Universe(str(reference))
    ref_sel = ref.select_atoms(selection)
    if ref_sel.n_atoms == 0:
        raise ValueError(f"Reference selection '{selection}' matched 0 atoms")

    output_dir.mkdir(parents=True, exist_ok=True)

    results: list[tuple[Path, Path, float, float]] = []
    for structure in structures:
        if not structure.exists():
            raise FileNotFoundError(f"Structure not found: {structure}")

        mobile = mda.Universe(str(structure))
        mobile_sel = mobile.select_atoms(selection)
        if mobile_sel.n_atoms == 0:
            raise ValueError(f"Selection '{selection}' matched 0 atoms in {structure}")

        rmsd_before = float(rmsd(mobile_sel.positions, ref_sel.positions, superposition=False))
        _, rmsd_after = align.alignto(mobile, ref, select=selection, match_atoms=False)

        out_name = f"{prefix}{structure.name}" if prefix else structure.name
        out_path = output_dir / out_name
        mobile.atoms.write(str(out_path))

        results.append((structure, out_path, rmsd_before, float(rmsd_after)))

    return results


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--structures",
        nargs="+",
        help="Input structures as file list and/or glob patterns (GRO/PDB)",
    )
    parser.add_argument("--reference", help="Reference complex PDB/GRO for alignment")
    parser.add_argument("--output-dir", help="Directory for aligned outputs")
    parser.add_argument("--selection", default=None, help="Atom selection for alignment (default: backbone)")
    parser.add_argument("--prefix", default=None, help="Optional filename prefix for aligned outputs")
    parser.add_argument("--config", type=Path, default=None, help="INI config file; reads [receptor] alignment values")
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    cfg: dict[str, str] = {}
    if args.config is not None:
        cfg = _load_config(args.config)

    structures_raw: list[str] = []
    if args.structures:
        structures_raw.extend(args.structures)
    elif "align_structures" in cfg:
        structures_raw.extend(_split_list(cfg["align_structures"]))

    if not structures_raw:
        raise ValueError("No structures provided (use --structures or [receptor] align_structures in --config)")

    reference = Path(args.reference or cfg.get("align_reference", ""))
    if not str(reference):
        raise ValueError("--reference is required (or set [receptor] align_reference in --config)")

    output_dir = Path(args.output_dir or cfg.get("align_output_dir", "aligned"))
    selection = args.selection or cfg.get("align_selection", "backbone")
    prefix = args.prefix if args.prefix is not None else cfg.get("align_output_prefix", "")

    structures = _resolve_structures(structures_raw)
    results = align_structures(
        structures=structures,
        reference=reference,
        output_dir=output_dir,
        selection=selection,
        prefix=prefix,
    )

    print("Alignment summary")
    print("=================")
    for src, dst, before, after in results:
        print(f"{src} -> {dst} | RMSD before: {before:.3f} A | after: {after:.3f} A")

    n = len(results)
    mean_before = sum(x[2] for x in results) / n
    mean_after = sum(x[3] for x in results) / n
    print("-----------------")
    print(f"Aligned: {n} structures")
    print(f"Mean RMSD before: {mean_before:.3f} A")
    print(f"Mean RMSD after:  {mean_after:.3f} A")


if __name__ == "__main__":
    main()
