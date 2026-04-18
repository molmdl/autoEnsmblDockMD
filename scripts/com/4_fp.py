#!/usr/bin/env python3
"""Fingerprint analysis utility for complex MD trajectories.

Computes frame-wise receptor-ligand contact fingerprints and writes:
1) Fingerprint matrix CSV
2) Frame-frame similarity heatmap PNG

Designed for both CLI and library usage.
"""

from __future__ import annotations

import argparse
import configparser
from pathlib import Path
from typing import Dict, Any

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

try:
    import MDAnalysis as mda
except Exception as exc:  # pragma: no cover
    raise SystemExit(f"MDAnalysis is required: {exc}")


def _pairwise_dice(binary_matrix: np.ndarray) -> np.ndarray:
    """Compute pairwise Dice similarity between frames."""
    matrix = binary_matrix.astype(np.int8, copy=False)
    intersection = matrix @ matrix.T
    counts = matrix.sum(axis=1, dtype=np.int32)
    denom = counts[:, None] + counts[None, :]
    sim = np.where(denom > 0, (2.0 * intersection) / denom, 1.0)
    return sim.astype(np.float32)


def _write_matrix_csv(
    output_csv: Path,
    frame_ids: np.ndarray,
    times_ps: np.ndarray,
    receptor_resids: np.ndarray,
    fingerprint_matrix: np.ndarray,
) -> None:
    output_csv.parent.mkdir(parents=True, exist_ok=True)
    header = ["frame", "time_ps"] + [f"resid_{int(r)}" for r in receptor_resids]
    data = np.column_stack([frame_ids, times_ps, fingerprint_matrix.astype(np.int8)])
    np.savetxt(output_csv, data, delimiter=",", header=",".join(header), comments="", fmt="%g")


def _write_heatmap_png(output_png: Path, similarity_matrix: np.ndarray) -> None:
    output_png.parent.mkdir(parents=True, exist_ok=True)
    fig, ax = plt.subplots(figsize=(7, 6))
    im = ax.imshow(similarity_matrix, cmap="viridis", vmin=0.0, vmax=1.0, interpolation="nearest")
    ax.set_title("Fingerprint Similarity (Dice)")
    ax.set_xlabel("Frame index")
    ax.set_ylabel("Frame index")
    cbar = fig.colorbar(im, ax=ax, fraction=0.046, pad=0.04)
    cbar.set_label("Dice similarity")
    fig.tight_layout()
    fig.savefig(output_png, dpi=300)
    plt.close(fig)


def calculate_fingerprints(
    topology: str,
    trajectory: str,
    ligand_selection: str,
    receptor_selection: str = "protein and not name H*",
    cutoff: float = 4.5,
) -> Dict[str, Any]:
    """Calculate receptor-ligand contact fingerprints.

    Returns dict containing frame metadata, receptor residue IDs, and binary matrix.
    """
    universe = mda.Universe(topology, trajectory)
    receptor = universe.select_atoms(receptor_selection)
    ligand = universe.select_atoms(ligand_selection)

    if len(receptor) == 0:
        raise ValueError(f"Receptor selection returned no atoms: {receptor_selection}")
    if len(ligand) == 0:
        raise ValueError(f"Ligand selection returned no atoms: {ligand_selection}")

    receptor_residues = receptor.residues
    receptor_resids = np.array([int(res.resid) for res in receptor_residues], dtype=np.int32)

    n_frames = len(universe.trajectory)
    n_res = len(receptor_residues)
    matrix = np.zeros((n_frames, n_res), dtype=np.int8)
    frame_ids = np.zeros(n_frames, dtype=np.int32)
    times_ps = np.zeros(n_frames, dtype=np.float64)

    for i, ts in enumerate(universe.trajectory):
        frame_ids[i] = int(ts.frame)
        times_ps[i] = float(ts.time)
        for j, residue in enumerate(receptor_residues):
            if len(residue.atoms) == 0:
                continue
            distances = mda.lib.distances.distance_array(residue.atoms.positions, ligand.positions)
            if np.any(distances <= cutoff):
                matrix[i, j] = 1

    return {
        "frame_ids": frame_ids,
        "times_ps": times_ps,
        "receptor_resids": receptor_resids,
        "fingerprint_matrix": matrix,
    }


def run_fingerprint_analysis(
    topology: str,
    trajectory: str,
    ligand_selection: str,
    output_prefix: str,
    receptor_selection: str = "protein and not name H*",
    cutoff: float = 4.5,
) -> Dict[str, Any]:
    """Library-mode entrypoint used by wrappers and direct imports."""
    results = calculate_fingerprints(
        topology=topology,
        trajectory=trajectory,
        ligand_selection=ligand_selection,
        receptor_selection=receptor_selection,
        cutoff=cutoff,
    )
    matrix = results["fingerprint_matrix"]
    similarity = _pairwise_dice(matrix)

    output_base = Path(output_prefix)
    matrix_csv = output_base.with_name(f"{output_base.name}_matrix.csv")
    heatmap_png = output_base.with_name(f"{output_base.name}_similarity_heatmap.png")

    _write_matrix_csv(
        output_csv=matrix_csv,
        frame_ids=results["frame_ids"],
        times_ps=results["times_ps"],
        receptor_resids=results["receptor_resids"],
        fingerprint_matrix=matrix,
    )
    _write_heatmap_png(heatmap_png, similarity)

    return {
        **results,
        "similarity_matrix": similarity,
        "matrix_csv": matrix_csv,
        "heatmap_png": heatmap_png,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Calculate receptor-ligand interaction fingerprints")
    parser.add_argument("--trajectory", required=True, help="Trajectory file (.xtc/.trr)")
    parser.add_argument("--topology", required=True, help="Topology file (.tpr/.gro/.pdb)")
    parser.add_argument(
        "--ligand-selection",
        "--ligand_sel",
        dest="ligand_selection",
        required=True,
        help="MDAnalysis selection for ligand atoms",
    )
    parser.add_argument(
        "--receptor-selection",
        "--receptor_sel",
        dest="receptor_selection",
        default="protein and not name H*",
        help="MDAnalysis selection for receptor atoms",
    )
    parser.add_argument("--cutoff", type=float, default=4.5, help="Contact cutoff in Angstrom")
    parser.add_argument(
        "--output",
        required=True,
        help="Output prefix path (writes <prefix>_matrix.csv and <prefix>_similarity_heatmap.png)",
    )
    parser.add_argument("--config", default=None, help="INI config file with [fingerprint] overrides")
    return parser.parse_args()


def _apply_config_overrides(args: argparse.Namespace) -> argparse.Namespace:
    if not args.config:
        return args
    cfg = configparser.ConfigParser()
    cfg.read(args.config)
    if not cfg.has_section("fingerprint"):
        return args
    section = cfg["fingerprint"]
    if section.get("trajectory") and not args.trajectory:
        args.trajectory = section.get("trajectory")
    if section.get("topology") and not args.topology:
        args.topology = section.get("topology")
    if section.get("ligand_selection") and not args.ligand_selection:
        args.ligand_selection = section.get("ligand_selection")
    if section.get("receptor_selection") and args.receptor_selection == "protein and not name H*":
        args.receptor_selection = section.get("receptor_selection")
    if section.get("output") and not args.output:
        args.output = section.get("output")
    if section.get("cutoff"):
        try:
            args.cutoff = float(section.get("cutoff", str(args.cutoff)))
        except ValueError:
            pass
    return args


def main() -> int:
    args = _apply_config_overrides(parse_args())
    results = run_fingerprint_analysis(
        topology=args.topology,
        trajectory=args.trajectory,
        ligand_selection=args.ligand_selection,
        receptor_selection=args.receptor_selection,
        cutoff=args.cutoff,
        output_prefix=args.output,
    )
    print(f"Fingerprint matrix: {results['matrix_csv']}")
    print(f"Similarity heatmap: {results['heatmap_png']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
