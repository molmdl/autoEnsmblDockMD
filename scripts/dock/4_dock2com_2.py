#!/usr/bin/env python3
"""Assemble MD-ready complex topology from receptor and ligand topologies."""

from __future__ import annotations

import argparse
import configparser
from pathlib import Path

try:
    from scripts.dock.dock2com_2_1 import parse_itp, parse_itp_section
except ModuleNotFoundError:
    import importlib.util
    import sys

    _WRAPPER = Path(__file__).with_name("dock2com_2_1.py")
    _SPEC = importlib.util.spec_from_file_location("dock2com_2_1", _WRAPPER)
    if _SPEC is None or _SPEC.loader is None:
        raise
    _MODULE = importlib.util.module_from_spec(_SPEC)
    sys.modules[_SPEC.name] = _MODULE
    _SPEC.loader.exec_module(_MODULE)
    parse_itp = _MODULE.parse_itp
    parse_itp_section = _MODULE.parse_itp_section


DEFAULT_SECTION = "docking"


def _load_overrides(config_path: Path) -> dict[str, str]:
    parser = configparser.ConfigParser()
    parser.read(config_path)
    if not parser.has_section(DEFAULT_SECTION):
        return {}
    return {k: v for k, v in parser.items(DEFAULT_SECTION)}


def _clean_itp_text(itp_path: Path) -> str:
    text = itp_path.read_text(encoding="utf-8", errors="replace")
    lower = text.lower()
    marker = "[ moleculetype ]"
    atomtypes = lower.find("[ atomtypes ]")
    if atomtypes == -1:
        return text
    moltype = lower.find(marker, atomtypes)
    if moltype == -1:
        return text
    return text[:atomtypes].rstrip() + "\n\n" + text[moltype:].lstrip()


def _extract_receptor_moleculetype(top_path: Path) -> str:
    lines = top_path.read_text(encoding="utf-8", errors="replace").splitlines()
    start = None
    for i, line in enumerate(lines):
        if "[ moleculetype ]" in line.lower():
            start = i
            break
    if start is None:
        raise ValueError(f"Could not find [ moleculetype ] in {top_path}")

    out: list[str] = []
    for line in lines[start:]:
        stripped = line.strip()
        if stripped.startswith("#include") and ".ff/" in stripped and out:
            break
        out.append(line)
    return "\n".join(out).rstrip() + "\n"


def _moleculetype_name(itp_or_top: Path) -> str | None:
    section = parse_itp_section(itp_or_top, "moleculetype")
    for line in section:
        token = line.split()
        if token:
            return token[0]
    return None


def _detect_ff_includes(top_path: Path) -> tuple[str | None, str | None, str | None]:
    ff_path = None
    water = None
    ions = None
    for line in top_path.read_text(encoding="utf-8", errors="replace").splitlines():
        stripped = line.strip()
        if not stripped.startswith("#include"):
            continue
        parts = stripped.split('"')
        if len(parts) < 2:
            continue
        inc = parts[1]
        low = inc.lower()
        if "forcefield.itp" in low:
            ff_path = inc
        elif "ions.itp" in low:
            ions = inc
        elif low.endswith(".itp") and ".ff/" in low and "forcefield" not in low and "ions" not in low:
            water = inc
    return ff_path, water, ions


def build_complex_topology(
    receptor_top: str | Path,
    ligand_itp: str | Path,
    output_top: str | Path,
    ff: str = "amber",
) -> Path:
    receptor_top_path = Path(receptor_top)
    ligand_itp_path = Path(ligand_itp)
    output_top_path = Path(output_top)

    if ff.lower() not in {"amber", "charmm"}:
        raise ValueError("--ff must be 'amber' or 'charmm'")

    if not receptor_top_path.exists():
        raise FileNotFoundError(f"Receptor topology not found: {receptor_top_path}")
    if not ligand_itp_path.exists():
        raise FileNotFoundError(f"Ligand ITP not found: {ligand_itp_path}")

    # Validation parse to ensure input sections are present.
    lig_sections = parse_itp(ligand_itp_path)
    if "moleculetype" not in lig_sections:
        raise ValueError(f"Ligand ITP missing [ moleculetype ]: {ligand_itp_path}")

    receptor_itp_name = f"{receptor_top_path.stem}_rec.itp"
    receptor_itp_path = output_top_path.parent / receptor_itp_name
    receptor_itp_path.write_text(_extract_receptor_moleculetype(receptor_top_path), encoding="utf-8")

    ligand_clean_name = f"{ligand_itp_path.stem}_clean.itp"
    ligand_clean_path = output_top_path.parent / ligand_clean_name
    ligand_clean_path.write_text(_clean_itp_text(ligand_itp_path), encoding="utf-8")

    ff_path, water_itp, ions_itp = _detect_ff_includes(receptor_top_path)
    rec_name = _moleculetype_name(receptor_itp_path) or "Protein"
    lig_name = _moleculetype_name(ligand_clean_path) or "LIG"
    system_name = f"{receptor_top_path.stem}_{ligand_itp_path.stem}_{ff.lower()}"

    includes: list[str] = []
    if ff_path:
        includes.append(f"#include \"{ff_path}\"")
    includes.append(f"#include \"{receptor_itp_path.name}\"")
    includes.append(f"#include \"{ligand_clean_path.name}\"")
    if water_itp:
        includes.append(f"#include \"{water_itp}\"")
    if ions_itp:
        includes.append(f"#include \"{ions_itp}\"")

    output_top_path.parent.mkdir(parents=True, exist_ok=True)
    output_top_path.write_text(
        "\n".join(
            [
                "; Auto-generated by 4_dock2com_2.py",
                f"; Force field mode: {ff.lower()}",
                "",
                *includes,
                "",
                "[ system ]",
                system_name,
                "",
                "[ molecules ]",
                "; Compound        #mols",
                f"{rec_name:<15s} 1",
                f"{lig_name:<15s} 1",
                "",
            ]
        ),
        encoding="utf-8",
    )
    return output_top_path


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Build receptor+ligand complex topology")
    parser.add_argument("--receptor-top", type=Path, help="Receptor topology (.top)")
    parser.add_argument("--ligand-itp", type=Path, help="Ligand topology (.itp)")
    parser.add_argument("--output-top", type=Path, help="Output complex topology (.top)")
    parser.add_argument("--ff", choices=["amber", "charmm"], default="amber", help="Force-field family")
    parser.add_argument("--config", type=Path, help="Optional config file with [docking] values")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    receptor_top = args.receptor_top
    ligand_itp = args.ligand_itp
    output_top = args.output_top
    ff = args.ff

    if args.config:
        overrides = _load_overrides(args.config)
        if receptor_top is None and "receptor_top" in overrides:
            receptor_top = Path(overrides["receptor_top"])
        if ligand_itp is None and "ligand_itp" in overrides:
            ligand_itp = Path(overrides["ligand_itp"])
        if output_top is None and "output_top" in overrides:
            output_top = Path(overrides["output_top"])
        if ff == "amber" and "ff" in overrides:
            ff = overrides["ff"].strip().lower()

    if receptor_top is None or ligand_itp is None or output_top is None:
        parser.error("--receptor-top, --ligand-itp, and --output-top are required (directly or via --config)")

    written = build_complex_topology(receptor_top, ligand_itp, output_top, ff=ff)
    print(f"Wrote complex topology: {written}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
