#!/usr/bin/env python3
"""
dock2com_2.2.1.py
=================
Bugfix release for manual model selection.

Fixes in v2.2.1:
- Respect `--model` in one-step workflow.
  In v2.2, the script always auto-selected the best model first, then used that
  model for conversion, even when `--model` was provided.
- `--model` now explicitly selects the requested model index.
"""

import importlib.util
import os
import sys


def _load_base_module():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    base_path = os.path.join(script_dir, "dock2com_2.2.py")

    if not os.path.exists(base_path):
        raise FileNotFoundError(f"Base script not found: {base_path}")

    spec = importlib.util.spec_from_file_location("dock2com_2_2_base", base_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Failed to load base script: {base_path}")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


BASE = _load_base_module()


def _select_manual_model(config):
    if len(config.sdf_paths) != 1:
        raise ValueError(
            f"--model requires exactly one SDF file, but got {len(config.sdf_paths)}. "
            "Please provide a single SDF when selecting a specific model."
        )

    sdf_path = config.sdf_paths[0]
    print(f"Parsing SDF:        {sdf_path}")
    models = BASE.parse_sdf(sdf_path)
    print(f"  {len(models)} models found")

    if not models:
        raise ValueError(f"No models found in SDF: {sdf_path}")

    if config.model_num < 1 or config.model_num > len(models):
        raise ValueError(
            f"Requested model {config.model_num} is out of range for "
            f"{os.path.basename(sdf_path)} (valid range: 1-{len(models)})."
        )

    model = models[config.model_num - 1]
    return model, sdf_path, config.model_num


def main():
    parser = BASE.build_parser()
    parser.prog = "dock2com_2.2.1.py"

    args = parser.parse_args()
    config = BASE.Config(args)

    if config.list_models:
        list_metrics = None
        if config.metric == "sasa":
            all_keys = []
            seen = set()
            for sdf_path in config.sdf_paths:
                models = BASE.parse_sdf(sdf_path)
                for m in models:
                    for k in m["scores"]:
                        if k not in seen:
                            all_keys.append(k)
                            seen.add(k)
            all_keys.append("sasa")
            list_metrics = all_keys

        BASE.list_models_across_sdfiles(
            config.sdf_paths,
            metrics=list_metrics,
            rec_gro_pattern=config.rec_gro_pattern,
            rec_dir=config.rec_dir,
            probe_radius=config.probe_radius,
        )
        return 0

    if config.rec_top is None:
        parser.error("-r/--rec-top is required unless --list-models is specified.")

    print("=" * 60)
    print("STEP 1: Selecting docking model...")
    print("=" * 60)

    if config.model_num is not None:
        print(f"Manual model requested: {config.model_num}")
        best_model, best_file, best_model_num = _select_manual_model(config)
    else:
        best_model, best_file, best_model_num = BASE.select_best_across_sdfiles(
            config.sdf_paths,
            metric=config.metric,
            rec_gro_pattern=config.rec_gro_pattern,
            rec_dir=config.rec_dir,
            probe_radius=config.probe_radius,
        )

    sc = best_model["scores"]
    if config.model_num is not None:
        print("\nModel selected (manual override):")
    else:
        print("\nBest model selected:")
    print(f"  File:   {os.path.basename(best_file)}")
    print(f"  Model:  {best_model_num}")
    print(
        f"  Scores: minimizedAffinity={sc.get('minimizedAffinity', float('nan')):.4f}  "
        f"CNNscore={sc.get('CNNscore', float('nan')):.4f}  "
        f"CNNaffinity={sc.get('CNNaffinity', float('nan')):.4f}"
    )

    if "sasa" in sc:
        print(f"          SASA={sc['sasa']:.4f} nm^2")

    print("\n" + "=" * 60)
    print("STEP 2: Locating receptor GRO file...")
    print("=" * 60)

    rec_gro = None
    prefix = None

    if config.rec_gro:
        rec_gro = config.rec_gro
        prefix = os.path.splitext(os.path.basename(rec_gro))[0]
        if not os.path.exists(rec_gro):
            print(f"ERROR: Receptor GRO file not found: {rec_gro}", file=sys.stderr)
            return 1
        print(f"  Using specified GRO: {rec_gro}")
    elif config.rec_pdb:
        if not os.path.exists(config.rec_pdb):
            print(f"ERROR: Receptor PDB file not found: {config.rec_pdb}", file=sys.stderr)
            return 1
        prefix = os.path.splitext(os.path.basename(config.rec_pdb))[0]
        rec_gro = f"{prefix}.gro"
        print(f"  Converting PDB to GRO: {config.rec_pdb} -> {rec_gro}")
        n_atoms = BASE.pdb_to_gro(config.rec_pdb, rec_gro)
        print(f"  Converted {n_atoms} atoms")
    else:
        rec_gro, prefix = BASE.derive_receptor_gro_from_sdf(
            best_file,
            pattern=config.rec_gro_pattern,
            search_dir=config.rec_dir,
        )

        if not os.path.exists(rec_gro):
            print(f"ERROR: Receptor GRO file not found: {rec_gro}", file=sys.stderr)
            print(f"  Derived from SDF: {best_file}", file=sys.stderr)
            print(f"  Pattern used: {config.rec_gro_pattern}", file=sys.stderr)
            return 1

        print(f"  Auto-detected: {rec_gro}")

    print(f"  Prefix: {prefix}")

    print("\n" + "=" * 60)
    print("STEP 3: Converting SDF to ligand GRO...")
    print("=" * 60)

    BASE.sdf_pose_to_gro(
        itp_path=config.lig_itp,
        sdf_path=best_file,
        out_path=config.lig_gro,
        mol2_template_path=config.mol2_template,
        metric=config.metric,
        model_num=best_model_num,
    )

    print("\n" + "=" * 60)
    print("STEP 4: Combining receptor and ligand coordinates...")
    print("=" * 60)

    BASE.combine_coordinates(rec_gro, config.lig_gro, config.com_gro)

    print("\n" + "=" * 60)
    print("STEP 5: Extracting receptor topology...")
    print("=" * 60)

    BASE.extract_receptor_topology(config.rec_top, config.rec_itp)

    print("\n" + "=" * 60)
    print("STEP 6: Handling ligand ffbonded.itp (CHARMM CGenFF)...")
    print("=" * 60)

    ffbonded_src = BASE.find_ffbonded_file(config.lig_itp, config.lig_ffbonded_arg)

    if ffbonded_src:
        print(f"  Found ffbonded.itp: {ffbonded_src}")
        config.lig_ffbonded = BASE.copy_ffbonded_to_workdir(ffbonded_src, "lig_ffbonded.itp")
    else:
        print("  No ffbonded.itp found (may be needed for CHARMM CGenFF)")
        config.lig_ffbonded = None

    print("\n" + "=" * 60)
    print("STEP 7: Generating ligand position restraints...")
    print("=" * 60)

    BASE.generate_ligand_posre(config.lig_itp, "posre_lig.itp", fc=1000)
    BASE.modify_lig_itp_posre(config.lig_itp)

    print("\n" + "=" * 60)
    print("STEP 8: Creating system topology...")
    print("=" * 60)

    ff_path, water_itp, ions_itp = BASE.extract_ff_paths_from_top(config.rec_top)

    if config.ff_path is None:
        config.ff_path = ff_path
        print(f"  Auto-detected forcefield: {config.ff_path}")

    if config.water_itp is None:
        config.water_itp = water_itp if water_itp else ""
        if config.water_itp:
            print(f"  Auto-detected water model: {config.water_itp}")

    if config.ions_itp is None:
        config.ions_itp = ions_itp if ions_itp else ""
        if config.ions_itp:
            print(f"  Auto-detected ions ITP: {config.ions_itp}")

    if config.rec_name is None:
        config.rec_name = BASE.get_moleculetype_name(config.rec_top)
        print(f"  Auto-detected receptor name: {config.rec_name}")

    if config.lig_name is None:
        config.lig_name = BASE.get_moleculetype_name(config.lig_itp)
        print(f"  Auto-detected ligand name: {config.lig_name}")

    if config.sys_name is None:
        config.sys_name = f"{prefix}.pdb_ali_best"
        print(f"  Auto-generated system name: {config.sys_name}")

    BASE.create_system_topology(config)

    print("\n" + "=" * 60)
    print("SUMMARY: Files created")
    print("=" * 60)
    print(f"  Ligand GRO:    {config.lig_gro}")
    print(f"  Combined GRO:  {config.com_gro}")
    print(f"  Receptor ITP:  {config.rec_itp}")
    print(f"  System TOP:    {config.sys_top}")
    print("  Ligand posre:  posre_lig.itp")
    if config.lig_ffbonded:
        print(f"  Ligand FF:     {config.lig_ffbonded}")
    print("\nDock2com_2.2.1 completed successfully!")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
