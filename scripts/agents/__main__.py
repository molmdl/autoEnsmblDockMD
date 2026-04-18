"""CLI entrypoint for invoking workflow agents."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Dict

from scripts.agents import AGENT_REGISTRY, get_agent
from scripts.infra.config import ConfigManager


def parse_args() -> argparse.Namespace:
    """Parse CLI arguments for agent invocation."""
    parser = argparse.ArgumentParser(
        description="Invoke an autoEnsmblDockMD workflow agent",
    )
    parser.add_argument(
        "--agent",
        required=True,
        choices=sorted(AGENT_REGISTRY.keys()),
        help="Agent role to execute",
    )
    parser.add_argument(
        "--workspace",
        required=True,
        help="Workspace directory used by the agent",
    )
    parser.add_argument(
        "--config",
        help="Path to INI configuration file",
    )
    parser.add_argument(
        "--input",
        help="Path to JSON handoff input file",
    )
    parser.add_argument(
        "--output",
        help="Path to write JSON handoff output (defaults to stdout)",
    )
    return parser.parse_args()


def load_config(config_path: str | None) -> Dict[str, Any]:
    """Load optional INI config as dictionary-of-sections."""
    if not config_path:
        return {}

    manager = ConfigManager(config_path)
    config_data: Dict[str, Any] = {}

    for section in manager.parser.sections():
        config_data[section] = manager.get_section(section)

    if manager.parser.defaults():
        config_data["DEFAULT"] = dict(manager.parser.defaults())

    return config_data


def load_input(input_path: str | None) -> Dict[str, Any]:
    """Load optional JSON input payload."""
    if not input_path:
        return {}

    payload_path = Path(input_path)
    with payload_path.open("r", encoding="utf-8") as fh:
        data = json.load(fh)

    if not isinstance(data, dict):
        raise ValueError("Input JSON must be an object/dictionary.")

    return data


def write_output(output_data: Dict[str, Any], output_path: str | None) -> None:
    """Write output JSON to file or stdout."""
    serialized = json.dumps(output_data, indent=2)
    if output_path:
        destination = Path(output_path)
        with destination.open("w", encoding="utf-8") as fh:
            fh.write(serialized)
            fh.write("\n")
        return

    print(serialized)


def main() -> int:
    """Run CLI invocation lifecycle."""
    try:
        args = parse_args()
        workspace = Path(args.workspace)
        config = load_config(args.config)
        input_data = load_input(args.input)

        agent = get_agent(role=args.agent, workspace=workspace, config=config)
        result = agent.execute(input_data)

        write_output(result, args.output)
        return 0
    except FileNotFoundError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 2
    except (ValueError, json.JSONDecodeError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1
    except Exception as exc:  # pragma: no cover - defensive boundary
        print(f"Unexpected error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
