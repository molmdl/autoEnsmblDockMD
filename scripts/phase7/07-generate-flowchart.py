#!/usr/bin/env python3
"""
Text-based workflow flowchart generator for autoEnsmblDockMD pipeline.

Generates ASCII art flowchart showing stages, sub-steps, and scripts called
for both blind and targeted docking modes.

Usage:
    python scripts/phase7/07-generate-flowchart.py --mode <blind|targeted> [--output <path>]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple


class FlowchartGenerator:
    """Generate ASCII art workflow flowchart from pipeline stage registry."""

    def __init__(self, mode: str):
        self.mode = mode.lower()
        if self.mode not in ("blind", "targeted"):
            raise ValueError(f"Invalid mode: {mode} (expected: blind or targeted)")

        # Stage information extracted from run_pipeline.sh
        self.stages: Dict[str, Dict[str, str]] = {}
        self.stage_order: List[str] = []

    def parse_pipeline_script(self) -> None:
        """Extract stage information from scripts/run_pipeline.sh."""
        script_dir = Path(__file__).parent.parent
        pipeline_script = script_dir / "run_pipeline.sh"

        if not pipeline_script.exists():
            raise FileNotFoundError(f"Pipeline script not found: {pipeline_script}")

        content = pipeline_script.read_text()

        # Parse STAGE_DESC entries
        desc_pattern = r'STAGE_DESC\[(\w+)\]="([^"]+)"'
        for match in re.finditer(desc_pattern, content):
            stage = match.group(1)
            desc = match.group(2)
            if stage not in self.stages:
                self.stages[stage] = {}
            self.stages[stage]["desc"] = desc

        # Parse STAGE_CMD entries
        cmd_pattern = r'STAGE_CMD\[(\w+)\]="\$\{SCRIPT_DIR\}/([^"]+)"'
        for match in re.finditer(cmd_pattern, content):
            stage = match.group(1)
            script = match.group(2)
            if stage not in self.stages:
                self.stages[stage] = {}
            self.stages[stage]["script"] = script

        # Parse ALL_STAGES array
        # Fixed: Use negated character class to avoid nested quantifiers (CWE-1333)
        stages_pattern = r'ALL_STAGES=\(\s*([^)]+)\)'
        match = re.search(stages_pattern, content)
        if match:
            stages_str = match.group(1)
            self.stage_order = stages_str.split()

    def categorize_stages(self) -> Dict[str, List[str]]:
        """Group stages by category (receptor, docking, complex)."""
        categories = {
            "Stage 0: Preflight Validation": [],
            "Stage 1: Receptor Preparation": [],
            "Stage 2: Docking": [],
            "Stage 3: Complex Setup": [],
            "Stage 4: Complex MD Production": [],
            "Stage 5: MM/PBSA": [],
            "Stage 6: Complex Analysis": [],
        }

        # Map stages to categories
        for stage in self.stage_order:
            if stage == "preflight":
                categories["Stage 0: Preflight Validation"].append(stage)
            elif stage.startswith("rec_"):
                if stage == "rec_prep":
                    categories["Stage 1: Receptor Preparation"].append(stage)
                else:
                    # Add to receptor category (rec_prod, rec_ana, rec_cluster, rec_align)
                    if not categories["Stage 1: Receptor Preparation"]:
                        categories["Stage 1: Receptor Preparation"].append(stage)
                    else:
                        # Extend the receptor stage
                        pass
            elif stage.startswith("dock_"):
                categories["Stage 2: Docking"].append(stage)
            elif stage.startswith("com_"):
                if stage == "com_prep":
                    categories["Stage 3: Complex Setup"].append(stage)
                elif stage == "com_prod":
                    categories["Stage 4: Complex MD Production"].append(stage)
                elif stage == "com_mmpbsa":
                    categories["Stage 5: MM/PBSA"].append(stage)
                elif stage == "com_ana":
                    categories["Stage 6: Complex Analysis"].append(stage)
                else:
                    # Other complex stages (com_fp, com_archive) go to analysis
                    categories["Stage 6: Complex Analysis"].append(stage)

        # Reorganize to match expected stage order
        organized = {
            "Stage 0: Preflight Validation": ["preflight"] if "preflight" in self.stages else [],
            "Stage 1: Receptor Preparation": [s for s in self.stage_order if s.startswith("rec_")],
            "Stage 2: Docking": [s for s in self.stage_order if s.startswith("dock_")],
            "Stage 3: Complex Setup": [s for s in self.stage_order if s == "com_prep"],
            "Stage 4: Complex MD Production": [s for s in self.stage_order if s == "com_prod"],
            "Stage 5: MM/PBSA": [s for s in self.stage_order if s == "com_mmpbsa"],
            "Stage 6: Complex Analysis": [s for s in self.stage_order if s in ("com_ana", "com_fp", "com_archive")],
        }

        return organized

    def generate_stage_box(self, stage: str, info: Dict[str, str]) -> List[str]:
        """Generate ASCII box for a single stage."""
        lines = []
        desc = info.get("desc", "No description")
        script = info.get("script", "Unknown script")

        # Truncate long descriptions to 70 chars
        if len(desc) > 70:
            desc = desc[:67] + "..."

        lines.append(f"  │  {desc}")
        lines.append(f"  │     └── {script}")

        return lines

    def generate_flowchart(self) -> str:
        """Generate complete ASCII flowchart."""
        lines = []

        # Header
        mode_title = f"{self.mode.capitalize()} Docking"
        if self.mode == "targeted":
            mode_title += " (Mode A)"
        else:
            mode_title += " (Mode B)"

        box_width = max(51, len(mode_title) + 27)

        lines.append("┌" + "─" * (box_width - 2) + "┐")
        lines.append(f"│ WORKFLOW FLOWCHART: {mode_title:<{box_width - 24 - len(mode_title)}} │")
        lines.append("├" + "─" * (box_width - 2) + "┤")
        lines.append("│" + " " * (box_width - 2) + "│")

        # Get categorized stages
        categories = self.categorize_stages()

        # Generate flow for each category
        first_category = True
        for category_name, stages in categories.items():
            if not stages:
                continue

            if not first_category:
                lines.append("  │              │")
                lines.append("  │              ▼")

            # Category header
            lines.append(f"  │  {category_name}")

            # Stage details
            for i, stage in enumerate(stages):
                if stage in self.stages:
                    info = self.stages[stage]
                    stage_lines = self.generate_stage_box(stage, info)
                    lines.extend(stage_lines)

                    if i < len(stages) - 1:
                        lines.append("  │              │")
                        lines.append("  │              ▼")

            first_category = False

        # Mode-specific notes
        lines.append("  │")
        if self.mode == "targeted":
            lines.append("  │  Targeted Mode Notes:")
            lines.append("  │     • Uses reference_ligand for pocket definition")
            lines.append("  │     • Autobox centered on reference ligand")
            lines.append("  │     • Requires [docking] reference_ligand in config")
        else:
            lines.append("  │  Blind Mode Notes:")
            lines.append("  │     • No reference ligand required")
            lines.append("  │     • Autobox covers entire receptor")
            lines.append("  │     • Larger search space")

        # Footer
        lines.append("│" + " " * (box_width - 2) + "│")
        lines.append("└" + "─" * (box_width - 2) + "┘")

        return "\n".join(lines)


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Generate ASCII workflow flowchart for autoEnsmblDockMD pipeline"
    )
    parser.add_argument(
        "--mode",
        required=True,
        choices=["blind", "targeted"],
        help="Docking mode (blind or targeted)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="Output file path (default: stdout)",
    )

    args = parser.parse_args()

    try:
        generator = FlowchartGenerator(args.mode)
        generator.parse_pipeline_script()
        flowchart = generator.generate_flowchart()

        if args.output:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(flowchart + "\n")
            print(f"Flowchart written to: {args.output}")
        else:
            print(flowchart)

        return 0

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
