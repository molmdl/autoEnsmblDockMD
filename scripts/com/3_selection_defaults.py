#!/usr/bin/env python3
"""Default MDAnalysis selections for complex trajectory analysis.

Provides reusable selection definitions for protein-ligand analysis and
optionally augments them from INI config values.
"""

from __future__ import annotations

import argparse
import configparser
import json
from pathlib import Path
from typing import Dict

DEFAULT_SELECTIONS: Dict[str, str] = {
    "protein_backbone": "protein and name N CA C O",
    "protein_heavy": "protein and not name H*",
    "protein_ca": "protein and name CA",
    "ligand_heavy": "resname MOL and not name H*",
    "ligand_all": "resname MOL",
    "binding_site": "protein and around 4.5 (resname MOL)",
}


def _load_mdanalysis():
    try:
        import MDAnalysis as mda  # type: ignore

        return mda
    except Exception:
        return None


def _load_config_overrides(config_path: str | None) -> Dict[str, str]:
    if not config_path:
        return {}

    parser = configparser.ConfigParser()
    parser.read(config_path)
    if not parser.has_section("analysis"):
        return {}

    overrides: Dict[str, str] = {}

    # Format 1: [analysis] selection.my_key = selection string
    for key, value in parser.items("analysis"):
        if key.startswith("selection."):
            name = key.split("selection.", 1)[1].strip()
            if name and value.strip():
                overrides[name] = value.strip()

    # Format 2: [analysis] custom_selections = key=sel;key2=sel2
    blob = parser.get("analysis", "custom_selections", fallback="").strip()
    if blob:
        for item in blob.split(";"):
            item = item.strip()
            if not item or "=" not in item:
                continue
            name, sel = item.split("=", 1)
            name = name.strip()
            sel = sel.strip()
            if name and sel:
                overrides[name] = sel

    return overrides


def _detect_ligand_resname(topology: str) -> str:
    mda = _load_mdanalysis()
    if mda is None:
        return "MOL"

    try:
        universe = mda.Universe(topology)
    except Exception:
        return "MOL"

    protein_resids = {r.resid for r in universe.select_atoms("protein").residues}
    candidates = []
    for residue in universe.residues:
        if residue.resid in protein_resids:
            continue
        if residue.n_atoms < 4:
            continue
        if residue.resname.upper() in {"SOL", "WAT", "HOH", "NA", "CL", "K", "MG", "CA"}:
            continue
        candidates.append((residue.resname, residue.n_atoms))

    if not candidates:
        return "MOL"

    candidates.sort(key=lambda x: x[1], reverse=True)
    return candidates[0][0]


def get_selections(topology: str | None = None, config_path: str | None = None) -> Dict[str, str]:
    selections = dict(DEFAULT_SELECTIONS)

    if topology:
        ligand_resname = _detect_ligand_resname(topology)
        selections["ligand_all"] = f"resname {ligand_resname}"
        selections["ligand_heavy"] = f"resname {ligand_resname} and not name H*"
        selections["binding_site"] = f"protein and around 4.5 (resname {ligand_resname})"

    selections.update(_load_config_overrides(config_path))
    return selections


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate standard MDAnalysis selection strings for complex analysis."
    )
    parser.add_argument(
        "--topology",
        default=None,
        help="Topology file used to auto-detect ligand residue name (optional).",
    )
    parser.add_argument(
        "--config",
        default=None,
        help="INI config file path for [analysis] selection overrides.",
    )
    parser.add_argument(
        "--output",
        default=None,
        help="Output file path. If omitted, prints JSON to stdout.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    selections = get_selections(topology=args.topology, config_path=args.config)
    rendered = json.dumps(selections, indent=2, sort_keys=True)

    if args.output:
        output_path = Path(args.output)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(rendered + "\n", encoding="utf-8")
    else:
        print(rendered)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
