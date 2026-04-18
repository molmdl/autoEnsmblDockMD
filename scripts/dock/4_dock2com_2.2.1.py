#!/usr/bin/env python3
"""Generate ligand heavy-atom position restraints from GRO files."""

from __future__ import annotations

import argparse
from pathlib import Path


def _is_hydrogen(atom_name: str) -> bool:
    name = atom_name.strip().upper()
    return name.startswith("H")


def parse_gro_atoms(gro_path: str | Path) -> list[dict[str, object]]:
    lines = Path(gro_path).read_text(encoding="utf-8", errors="replace").splitlines()
    if len(lines) < 3:
        raise ValueError("Invalid GRO file: too short")
    atom_count = int(lines[1].strip().split()[0])
    atom_lines = lines[2 : 2 + atom_count]
    atoms: list[dict[str, object]] = []
    for line in atom_lines:
        atom_id = int(line[15:20])
        atom_name = line[10:15].strip()
        atoms.append({"id": atom_id, "name": atom_name})
    return atoms


def generate_posre(gro: str | Path, output: str | Path, force_constant: float = 1000.0) -> Path:
    atoms = parse_gro_atoms(gro)
    heavy = [atom for atom in atoms if not _is_hydrogen(str(atom["name"]))]

    out = Path(output)
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", encoding="utf-8") as handle:
        handle.write("[ position_restraints ]\n")
        handle.write(";  i funct       fcx        fcy        fcz\n")
        for atom in heavy:
            atom_id = int(atom["id"])
            handle.write(
                f"{atom_id:>4d}    1  {force_constant:>10.1f}  {force_constant:>10.1f}  {force_constant:>10.1f}\n"
            )
    return out


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Generate ligand posre ITP from GRO")
    parser.add_argument("--gro", type=Path, required=True, help="Ligand GRO structure")
    parser.add_argument("--force-constant", type=float, default=1000.0, help="Force constant (kJ/mol/nm^2)")
    parser.add_argument("--output", type=Path, default=Path("posre_lig.itp"), help="Output posre ITP path")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    output = generate_posre(args.gro, args.output, args.force_constant)
    print(f"Wrote position restraints: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
