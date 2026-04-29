#!/usr/bin/env python3
"""Advanced MD trajectory analysis for protein-ligand complexes.

Computes RMSD, per-residue RMSF, receptor-ligand contacts, and distance metrics.
Outputs CSV tables and publication-quality plots.
"""

from __future__ import annotations

import argparse
import configparser
import csv
import importlib.util
import logging
from pathlib import Path
from typing import Dict, Iterable, Tuple

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

try:
    import MDAnalysis as mda
    from MDAnalysis.analysis import rms
except Exception as exc:  # pragma: no cover - runtime dependency
    raise SystemExit(f"MDAnalysis is required: {exc}")


def _load_selection_module(script_dir: Path):
    module_path = script_dir / "3_selection_defaults.py"
    spec = importlib.util.spec_from_file_location("selection_defaults_local", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load selection module from {module_path}")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="MDAnalysis trajectory analysis for complex MD")
    parser.add_argument("--trajectory", required=True, help="Trajectory file (.xtc/.trr)")
    parser.add_argument("--topology", required=True, help="Topology file (.tpr/.gro/.pdb)")
    parser.add_argument("--output-dir", required=True, help="Directory for analysis outputs")
    parser.add_argument(
        "--selections",
        default="",
        help="Selection overrides as 'name=selection;name2=selection2'",
    )
    parser.add_argument("--config", default=None, help="INI config file with [analysis] overrides")
    parser.add_argument("--plot-format", default="png", choices=["png", "pdf", "svg"])
    parser.add_argument("--dpi", type=int, default=300)
    parser.add_argument("--contact-cutoff", type=float, default=4.5)
    parser.add_argument("--contact-max-frames", type=int, default=1000)
    parser.add_argument("--distance-reference", default="protein_backbone")
    return parser.parse_args()


def _parse_inline_selections(raw: str) -> Dict[str, str]:
    values: Dict[str, str] = {}
    if not raw:
        return values
    for item in raw.split(";"):
        item = item.strip()
        if not item or "=" not in item:
            continue
        key, value = item.split("=", 1)
        key = key.strip()
        value = value.strip()
        if key and value:
            values[key] = value
    return values


def _load_selections(topology: str, config_path: str | None, inline: str) -> Dict[str, str]:
    script_dir = Path(__file__).resolve().parent
    mod = _load_selection_module(script_dir)
    selections = mod.get_selections(topology=topology, config_path=config_path)
    selections.update(_parse_inline_selections(inline))
    return selections


def _frames_and_times(universe: "mda.Universe") -> Tuple[np.ndarray, np.ndarray]:
    frames: list[int] = []
    times: list[float] = []
    for ts in universe.trajectory:
        frames.append(int(ts.frame))
        times.append(float(ts.time))
    return np.array(frames, dtype=int), np.array(times, dtype=float)


def compute_rmsd(universe: "mda.Universe", selection: str) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
    atoms = universe.select_atoms(selection)
    if len(atoms) == 0:
        raise ValueError(f"Selection yielded no atoms for RMSD: {selection}")

    universe.trajectory[0]
    reference = atoms.positions.copy()
    frames: list[int] = []
    times: list[float] = []
    values: list[float] = []
    for ts in universe.trajectory:
        rmsd_value = rms.rmsd(atoms.positions, reference, superposition=True)
        frames.append(int(ts.frame))
        times.append(float(ts.time))
        values.append(float(rmsd_value))
    return np.array(frames), np.array(times), np.array(values)


def compute_rmsf(universe: "mda.Universe", selection: str) -> Tuple[np.ndarray, np.ndarray]:
    atoms = universe.select_atoms(selection)
    if len(atoms) == 0:
        raise ValueError(f"Selection yielded no atoms for RMSF: {selection}")

    n_frames = 0
    mean_xyz = np.zeros((len(atoms), 3), dtype=float)
    m2_xyz = np.zeros((len(atoms), 3), dtype=float)

    for _ in universe.trajectory:
        n_frames += 1
        xyz = atoms.positions.astype(float, copy=True)
        delta = xyz - mean_xyz
        mean_xyz += delta / n_frames
        delta2 = xyz - mean_xyz
        m2_xyz += delta * delta2

    if n_frames == 0:
        raise ValueError("Trajectory contains no frames for RMSF analysis")

    per_atom_var = m2_xyz / n_frames
    per_atom_rmsf = np.sqrt(np.sum(per_atom_var, axis=1))

    residue_to_values: Dict[int, list[float]] = {}
    for atom, value in zip(atoms, per_atom_rmsf):
        residue_to_values.setdefault(int(atom.resid), []).append(float(value))

    residue_ids = np.array(sorted(residue_to_values.keys()), dtype=int)
    if len(residue_ids) > 1:
        gaps = np.diff(residue_ids)
        if np.any(gaps > 1):
            gap_positions = np.where(gaps > 1)[0]
            gap_details = [(int(residue_ids[i]), int(residue_ids[i + 1])) for i in gap_positions]
            logging.warning(
                "Non-sequential residue IDs detected in RMSF calculation. "
                f"Gaps found: {gap_details[:5]} {'...' if len(gap_details) > 5 else ''}. "
                f"Total gaps: {len(gap_positions)}. "
                "Residue-to-RMSF mapping uses explicit dictionary keys to maintain correctness."
            )

    residue_rmsf = np.array([np.mean(residue_to_values[r]) for r in residue_ids], dtype=float)
    return residue_ids, residue_rmsf


def compute_contact_frequency(
    universe: "mda.Universe",
    receptor_sel: str,
    ligand_sel: str,
    cutoff: float,
    max_frames: int = 1000,
) -> Tuple[np.ndarray, np.ndarray]:
    """Compute contact frequency with optional frame striding.

    Args:
        universe: MDAnalysis universe.
        receptor_sel: Receptor selection for contact detection.
        ligand_sel: Ligand selection for contact detection.
        cutoff: Contact cutoff distance (Å).
        max_frames: Maximum frames to analyze. Stride is auto-calculated to
            sample uniformly across trajectory. Set to None to analyze all
            frames.
    """
    receptor = universe.select_atoms(receptor_sel)
    ligand = universe.select_atoms(ligand_sel)
    if len(receptor) == 0 or len(ligand) == 0:
        raise ValueError("Selections yielded empty atoms for contact analysis")

    receptor_resids = receptor.resids.astype(int, copy=False)
    residue_ids = np.unique(receptor_resids)
    counts = np.zeros(len(residue_ids), dtype=int)
    total_frames = 0

    traj_length = len(universe.trajectory)
    stride = max(1, traj_length // max_frames) if max_frames else 1

    if stride > 1:
        logging.info(
            "Analyzing %s frames with stride %s (trajectory length: %s frames)",
            traj_length // stride,
            stride,
            traj_length,
        )

    for _ in universe.trajectory[::stride]:
        total_frames += 1
        contacts = mda.lib.distances.capped_distance(
            receptor.positions,
            ligand.positions,
            max_cutoff=cutoff,
            box=universe.dimensions,
            return_distances=False,
        )
        if contacts.size == 0:
            continue

        contact_atom_indices = np.unique(contacts[:, 0])
        contacting_resids = np.unique(receptor_resids[contact_atom_indices])
        residue_indices = np.searchsorted(residue_ids, contacting_resids)
        counts[residue_indices] += 1

    frequencies = counts.astype(float) / max(total_frames, 1)
    return residue_ids, frequencies


def compute_distance_metrics(
    universe: "mda.Universe", reference_sel: str, ligand_sel: str
) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
    reference = universe.select_atoms(reference_sel)
    ligand = universe.select_atoms(ligand_sel)
    if len(reference) == 0 or len(ligand) == 0:
        raise ValueError("Selections yielded empty atoms for distance analysis")

    frames: list[int] = []
    times: list[float] = []
    distances: list[float] = []
    for ts in universe.trajectory:
        frames.append(int(ts.frame))
        times.append(float(ts.time))
        d = np.linalg.norm(reference.center_of_mass() - ligand.center_of_mass())
        distances.append(float(d))
    return np.array(frames), np.array(times), np.array(distances)


def _write_csv(path: Path, header: Iterable[str], rows: Iterable[Iterable[object]]) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(list(header))
        for row in rows:
            writer.writerow(list(row))


def _plot_line(x: np.ndarray, y: np.ndarray, title: str, xlabel: str, ylabel: str, output: Path, dpi: int):
    fig, ax = plt.subplots(figsize=(8, 4))
    ax.plot(x, y, linewidth=1.2)
    ax.set_title(title)
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    fig.tight_layout()
    fig.savefig(output, dpi=dpi)
    plt.close(fig)


def _plot_bar(x: np.ndarray, y: np.ndarray, title: str, xlabel: str, ylabel: str, output: Path, dpi: int):
    fig, ax = plt.subplots(figsize=(9, 4.5))
    ax.bar(x, y, width=0.9)
    ax.set_title(title)
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    fig.tight_layout()
    fig.savefig(output, dpi=dpi)
    plt.close(fig)


def analyze_trajectory(
    trajectory: str,
    topology: str,
    output_dir: str,
    selections: Dict[str, str],
    plot_format: str = "png",
    dpi: int = 300,
    contact_cutoff: float = 4.5,
    contact_max_frames: int = 1000,
    distance_reference: str = "protein_backbone",
) -> Dict[str, Path]:
    out = Path(output_dir)
    out.mkdir(parents=True, exist_ok=True)

    universe = mda.Universe(topology, trajectory)

    bb_sel = selections.get("protein_backbone", "protein and name N CA C O")
    lig_sel = selections.get("ligand_heavy", "resname MOL and not name H*")
    rec_sel = selections.get("protein_heavy", "protein and not name H*")
    ref_sel = selections.get(distance_reference, bb_sel)

    rmsd_frames, rmsd_time, rmsd_vals = compute_rmsd(universe, bb_sel)
    _write_csv(
        out / "rmsd_timeseries.csv",
        ["frame", "time_ps", "rmsd_angstrom"],
        zip(rmsd_frames, rmsd_time, rmsd_vals),
    )
    _plot_line(
        rmsd_time,
        rmsd_vals,
        "Protein Backbone RMSD",
        "Time (ps)",
        "RMSD (Å)",
        out / f"rmsd_timeseries.{plot_format}",
        dpi,
    )

    # Reset trajectory iterator for each analysis
    universe.trajectory[0]
    rmsf_res, rmsf_vals = compute_rmsf(universe, bb_sel)
    _write_csv(out / "rmsf_per_residue.csv", ["resid", "rmsf_angstrom"], zip(rmsf_res, rmsf_vals))
    _plot_bar(
        rmsf_res,
        rmsf_vals,
        "Per-residue RMSF",
        "Residue ID",
        "RMSF (Å)",
        out / f"rmsf_per_residue.{plot_format}",
        dpi,
    )

    universe.trajectory[0]
    contact_res, contact_freq = compute_contact_frequency(
        universe,
        rec_sel,
        lig_sel,
        contact_cutoff,
        max_frames=contact_max_frames,
    )
    _write_csv(
        out / "contact_frequency.csv",
        ["resid", "contact_frequency"],
        zip(contact_res, contact_freq),
    )
    _plot_bar(
        contact_res,
        contact_freq,
        f"Contact Frequency (cutoff={contact_cutoff:.2f} Å)",
        "Residue ID",
        "Frequency",
        out / f"contact_frequency.{plot_format}",
        dpi,
    )

    universe.trajectory[0]
    dist_frames, dist_time, dist_vals = compute_distance_metrics(universe, ref_sel, lig_sel)
    _write_csv(
        out / "distance_metrics.csv",
        ["frame", "time_ps", "com_distance_angstrom"],
        zip(dist_frames, dist_time, dist_vals),
    )
    _plot_line(
        dist_time,
        dist_vals,
        "Reference-Ligand COM Distance",
        "Time (ps)",
        "Distance (Å)",
        out / f"distance_metrics.{plot_format}",
        dpi,
    )

    selections_path = out / "selections_used.csv"
    _write_csv(selections_path, ["name", "selection"], selections.items())

    return {
        "rmsd_csv": out / "rmsd_timeseries.csv",
        "rmsf_csv": out / "rmsf_per_residue.csv",
        "contact_csv": out / "contact_frequency.csv",
        "distance_csv": out / "distance_metrics.csv",
        "selections_csv": selections_path,
    }


def _apply_config_defaults(args: argparse.Namespace) -> argparse.Namespace:
    if not args.config:
        return args
    parser = configparser.ConfigParser()
    parser.read(args.config)
    if not parser.has_section("analysis"):
        return args

    section = parser["analysis"]
    if args.plot_format == "png" and section.get("plot_format"):
        args.plot_format = section.get("plot_format", args.plot_format)
    if args.dpi == 300 and section.get("plot_dpi"):
        try:
            args.dpi = int(section.get("plot_dpi", "300"))
        except ValueError:
            pass
    if args.contact_cutoff == 4.5 and section.get("contact_cutoff"):
        try:
            args.contact_cutoff = float(section.get("contact_cutoff", "4.5"))
        except ValueError:
            pass
    if args.contact_max_frames == 1000 and section.get("contact_max_frames"):
        try:
            args.contact_max_frames = int(section.get("contact_max_frames", "1000"))
        except ValueError:
            pass
    if args.distance_reference == "protein_backbone" and section.get("distance_reference"):
        args.distance_reference = section.get("distance_reference", args.distance_reference)
    return args


def main() -> int:
    args = _apply_config_defaults(parse_args())
    selections = _load_selections(args.topology, args.config, args.selections)

    analyze_trajectory(
        trajectory=args.trajectory,
        topology=args.topology,
        output_dir=args.output_dir,
        selections=selections,
        plot_format=args.plot_format,
        dpi=args.dpi,
        contact_cutoff=args.contact_cutoff,
        contact_max_frames=args.contact_max_frames,
        distance_reference=args.distance_reference,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
