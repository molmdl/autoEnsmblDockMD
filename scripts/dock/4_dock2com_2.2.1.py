#!/usr/bin/env python3
"""Generate ligand heavy-atom position restraints from GRO files."""

from __future__ import annotations

import argparse
import sys
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


def parse_itp_atoms(itp_path: str | Path) -> list[dict[str, object]]:
    lines = Path(itp_path).read_text(encoding="utf-8", errors="replace").splitlines()
    atoms: list[dict[str, object]] = []
    in_atoms = False

    for raw in lines:
        line = raw.strip()
        if not line:
            continue

        if line.startswith("["):
            in_atoms = line.lower().startswith("[ atoms")
            continue

        if not in_atoms or line.startswith(";") or line.startswith("#"):
            continue

        body = line.split(";", 1)[0].strip()
        if not body:
            continue
        parts = body.split()
        if len(parts) < 5:
            continue

        try:
            atom_id = int(parts[0])
        except ValueError:
            continue
        atom_name = parts[4].strip()
        atoms.append({"id": atom_id, "name": atom_name})

    if not atoms:
        raise ValueError(f"ITP [ atoms ] section is missing or empty: {itp_path}")

    return atoms


def validate_gro_itp_atom_mapping(gro: str | Path, itp: str | Path) -> None:
    gro_atoms = parse_gro_atoms(gro)
    itp_atoms = parse_itp_atoms(itp)

    gro_count = len(gro_atoms)
    itp_count = len(itp_atoms)
    if gro_count != itp_count:
        raise ValueError(
            f"Atom-count mismatch between GRO and ITP: GRO has {gro_count}, ITP has {itp_count}. "
            f"Files: GRO={gro}, ITP={itp}"
        )

    mismatches: list[str] = []
    for idx, (gro_atom, itp_atom) in enumerate(zip(gro_atoms, itp_atoms), start=1):
        gro_name = str(gro_atom["name"]).strip().upper()
        itp_name = str(itp_atom["name"]).strip().upper()
        if gro_name != itp_name:
            mismatches.append(
                f"index {idx}: GRO='{gro_atom['name']}' (id {gro_atom['id']}) vs "
                f"ITP='{itp_atom['name']}' (id {itp_atom['id']})"
            )

    if mismatches:
        preview = "\n".join(mismatches[:10])
        suffix = "" if len(mismatches) <= 10 else f"\n... ({len(mismatches) - 10} more mismatches)"
        raise ValueError(
            "Atom-order/name mismatch between GRO and ITP. Position restraints may target wrong atoms.\n"
            f"First mismatches:\n{preview}{suffix}"
        )


def generate_posre(
    gro: str | Path,
    output: str | Path,
    force_constant: float = 1000.0,
    itp: str | Path | None = None,
) -> Path:
    if itp is not None:
        validate_gro_itp_atom_mapping(gro, itp)

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
    parser.add_argument("--itp", type=Path, help="Ligand ITP for GRO↔ITP atom-order validation")
    parser.add_argument("--force-constant", type=float, default=1000.0, help="Force constant (kJ/mol/nm^2)")
    parser.add_argument("--output", type=Path, default=Path("posre_lig.itp"), help="Output posre ITP path")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        output = generate_posre(args.gro, args.output, args.force_constant, itp=args.itp)
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    print(f"Wrote position restraints: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
