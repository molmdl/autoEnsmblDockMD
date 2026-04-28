#!/usr/bin/env python3
"""Preflight validation plugin - validates config, tools, and inputs before workflow execution."""

from __future__ import annotations

import argparse
import configparser
import json
import shutil
import sys
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[3]))

from scripts.agents.schemas.handoff import HandoffRecord, HandoffStatus


class PreflightValidator:
    """Validate configuration, tool availability, and workspace input readiness."""

    REQUIRED_SECTIONS = ("general", "docking", "receptor", "complex")
    SUPPORTED_MODES = {"targeted", "blind", "test"}
    REQUIRED_TOOLS = ("gmx", "gnina", "gmx_MMPBSA")

    def __init__(self, config_path: Path):
        self.config_path = config_path
        self.workspace_root = Path.cwd()
        self.config = configparser.ConfigParser(interpolation=configparser.ExtendedInterpolation())
        self.record = HandoffRecord(
            from_agent="preflight",
            to_agent="runner",
            stage="preflight_validation",
        )
        self.info_messages: list[str] = []

    def validate(self) -> HandoffRecord:
        """Run all preflight checks and assign final handoff status."""
        self.check_config_exists()
        if self.record.errors:
            return self._finalize_status()

        self.config.read(self.config_path)
        self.check_required_sections()
        self.check_mode_specific_requirements()
        self.check_tool_availability()
        self.check_input_files()
        return self._finalize_status()

    def check_config_exists(self):
        """ERROR if config file does not exist."""
        if not self.config_path.exists() or not self.config_path.is_file():
            self.record.errors.append(f"Config file not found: {self.config_path}")
            self.record.recommendations.append(
                "Provide a valid --config path (for example scripts/config.ini.template or workspace config.ini)."
            )

    def check_required_sections(self):
        """ERROR if any required INI section is missing."""
        missing = [section for section in self.REQUIRED_SECTIONS if section not in self.config]
        if missing:
            rendered = ", ".join(f"[{name}]" for name in missing)
            self.record.errors.append(f"Missing required config sections: {rendered}")
            self.record.recommendations.append(
                "Populate missing sections using scripts/config.ini.template as baseline."
            )

    def check_mode_specific_requirements(self):
        """Apply mode-aware docking validation rules."""
        if "docking" not in self.config:
            return

        mode_raw = self.config.get("docking", "mode", fallback="").strip().lower()
        if not mode_raw:
            self.record.errors.append("Missing required key [docking] mode")
            self.record.recommendations.append(
                "Set [docking] mode to one of: targeted, blind, test."
            )
            return

        if mode_raw not in self.SUPPORTED_MODES:
            self.record.errors.append(
                f"Invalid [docking] mode: '{mode_raw}' (expected targeted|blind|test)"
            )
            self.record.recommendations.append(
                "Correct [docking] mode to targeted, blind, or test."
            )
            return

        self.record.data["mode"] = mode_raw

        if mode_raw == "targeted":
            reference_ligand = self.config.get("docking", "reference_ligand", fallback="").strip()
            if not reference_ligand:
                self.record.errors.append(
                    "Mode targeted requires [docking] reference_ligand to be specified."
                )
                self.record.recommendations.append(
                    "Set [docking] reference_ligand to an existing reference ligand path."
                )
                return

            reference_path = Path(reference_ligand)
            if not reference_path.is_absolute():
                reference_path = (self.workspace_root / reference_path).resolve()

            if not reference_path.exists():
                self.record.warnings.append(
                    f"Targeted mode reference ligand file not found: {reference_path}"
                )
                self.record.recommendations.append(
                    "Verify [docking] reference_ligand path or place reference ligand in workspace."
                )

        if mode_raw == "blind":
            self.info_messages.append(
                "Blind docking mode detected: gnina autobox will be used without reference ligand constraint."
            )

    def check_tool_availability(self):
        """WARNING if expected executables are not available in current PATH."""
        missing_tools = [tool for tool in self.REQUIRED_TOOLS if shutil.which(tool) is None]
        if missing_tools:
            self.record.warnings.append(
                "Tools not found in PATH: " + ", ".join(missing_tools)
            )
            self.record.recommendations.append(
                "Source scripts/setenv.sh or install missing tools in the active conda environment."
            )
        self.record.data["tools_checked"] = list(self.REQUIRED_TOOLS)

    def check_input_files(self):
        """WARNING if workspace input directory is missing/empty or receptor.pdb is absent."""
        input_dir = self.workspace_root / "work" / "input"

        if not input_dir.exists() or not input_dir.is_dir():
            self.record.warnings.append(f"Input directory not found: {input_dir}")
            self.record.recommendations.append(
                "Create work/input and populate required receptor/ligand files before running stages."
            )
            return

        has_any_input = any(input_dir.iterdir())
        if not has_any_input:
            self.record.warnings.append(f"Input directory is empty: {input_dir}")
            self.record.recommendations.append("Add required workflow inputs under work/input.")

        receptor_path = input_dir / "receptor.pdb"
        if not receptor_path.exists():
            self.record.warnings.append(f"Required receptor input missing: {receptor_path}")
            self.record.recommendations.append(
                "Add receptor.pdb into work/input (or align workflow inputs before execution)."
            )

    def _finalize_status(self) -> HandoffRecord:
        """Map collected findings to final handoff status and metadata."""
        if self.record.errors:
            self.record.status = HandoffStatus.FAILURE
        elif self.record.warnings:
            self.record.status = HandoffStatus.NEEDS_REVIEW
        else:
            self.record.status = HandoffStatus.SUCCESS

        self.record.data["config_path"] = str(self.config_path.resolve())
        self.record.data["workspace_root"] = str(self.workspace_root.resolve())
        self.record.data["info"] = self.info_messages
        return self.record


def main() -> int:
    """CLI entrypoint for preflight validation plugin."""
    parser = argparse.ArgumentParser(
        description="Run preflight validation before workflow execution."
    )
    parser.add_argument("--config", required=True, help="Path to config.ini file")
    parser.add_argument(
        "--workspace",
        default=str(Path.cwd()),
        help="Workspace root (default: current working directory)",
    )
    args = parser.parse_args()

    validator = PreflightValidator(config_path=Path(args.config))
    validator.workspace_root = Path(args.workspace).resolve()
    record = validator.validate()

    print(json.dumps(record.to_dict(), indent=2))
    if record.status in {HandoffStatus.SUCCESS, HandoffStatus.NEEDS_REVIEW}:
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
