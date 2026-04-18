"""Debugger agent for environment-aware diagnosis and reproducibility reporting."""

from __future__ import annotations

import os
import platform
import re
import socket
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Tuple

from scripts.agents.base import BaseAgent
from scripts.agents.schemas.handoff import HandoffRecord, HandoffStatus


class DebuggerAgent(BaseAgent):
    """Diagnoses failures, captures environment, and persists debug reports."""

    KNOWN_ERROR_PATTERNS: Dict[str, Tuple[str, List[str], List[str]]] = {
        r"fatal error": (
            "gromacs_fatal",
            [
                "Invalid or mismatched topology/input files.",
                "Inconsistent force-field assumptions across inputs.",
            ],
            [
                "Validate topology includes and coordinate consistency.",
                "Rebuild inputs with consistent force-field configuration.",
            ],
        ),
        r"segmentation fault": (
            "segmentation_fault",
            [
                "Memory pressure during simulation or analysis.",
                "Corrupted input structure or trajectory files.",
            ],
            [
                "Reduce system size/workload or increase memory allocation.",
                "Re-validate all input files and rerun preprocessing.",
            ],
        ),
        r"command not found": (
            "environment_path_issue",
            [
                "Required executable missing from PATH.",
                "Environment not initialized (e.g., setenv not sourced).",
            ],
            [
                "Confirm tool installation and PATH export.",
                "Source scripts/setenv.sh before execution.",
            ],
        ),
        r"no such file or directory": (
            "missing_file",
            [
                "Referenced input/output path does not exist.",
                "Relative path resolved from unexpected working directory.",
            ],
            [
                "Confirm required files exist and paths are correct.",
                "Use absolute paths or enforce expected working directory.",
            ],
        ),
    }

    def get_role(self) -> str:
        """Return role identifier for this agent."""
        return "debugger"

    def execute(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Capture environment, analyze error context, and emit debug handoff."""
        stage = str(input_data.get("stage", "unknown"))

        environment = self._capture_environment()
        error_analysis = self._analyze_error(input_data)
        report = self._generate_report(environment, error_analysis, input_data)

        report_dir = self.workspace / ".debug_reports"
        report_dir.mkdir(parents=True, exist_ok=True)
        timestamp = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
        report_path = report_dir / f"{stage}_{timestamp}.json"

        handoff = HandoffRecord(
            from_agent=self.get_role(),
            to_agent=input_data.get("next_agent", "orchestrator"),
            status=HandoffStatus.NEEDS_REVIEW,
            stage=stage,
            data={
                "environment": environment,
                "error_analysis": error_analysis,
                "debug_report": report,
                "debug_report_path": str(report_path),
            },
            warnings=input_data.get("warnings", []),
            errors=error_analysis.get("error_messages", []),
            recommendations=error_analysis.get("suggested_fixes", []),
        )
        handoff.save(report_path)

        self.save_checkpoint(
            stage,
            {
                "debug_report_path": str(report_path),
                "error_type": error_analysis.get("error_type"),
            },
        )

        return handoff.to_dict()

    def _capture_environment(self) -> Dict[str, Any]:
        """Capture reproducibility-focused environment and tool versions."""
        gmx_version = self._get_tool_version(["gmx", "--version"])
        gnina_version = self._get_tool_version(["gnina", "--version"])
        gmx_mmpbsa_version = self._get_tool_version(["gmx_MMPBSA", "--version"])

        return {
            "python_version": platform.python_version(),
            "gromacs_version": gmx_version,
            "gnina_version": gnina_version,
            "gmx_mmpbsa_version": gmx_mmpbsa_version,
            "conda_env": os.environ.get("CONDA_DEFAULT_ENV", "not_available"),
            "hostname": socket.gethostname(),
            "working_directory": str(Path.cwd()),
            "path": os.environ.get("PATH", ""),
        }

    def _analyze_error(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Classify errors and generate likely causes and fixes."""
        collected_messages: List[str] = []

        raw_errors = input_data.get("errors", [])
        if isinstance(raw_errors, str):
            collected_messages.append(raw_errors)
        elif isinstance(raw_errors, list):
            collected_messages.extend(str(item) for item in raw_errors if item is not None)

        for field in ("stderr", "stdout", "message"):
            value = input_data.get(field)
            if isinstance(value, str) and value.strip():
                collected_messages.append(value)

        combined_text = "\n".join(collected_messages)
        lower_text = combined_text.lower()

        for pattern, (error_type, possible_causes, suggested_fixes) in self.KNOWN_ERROR_PATTERNS.items():
            if re.search(pattern, lower_text):
                return {
                    "error_type": error_type,
                    "error_messages": collected_messages or ["No explicit error messages provided."],
                    "possible_causes": possible_causes,
                    "suggested_fixes": suggested_fixes,
                }

        return {
            "error_type": "unknown",
            "error_messages": collected_messages or ["No explicit error messages provided."],
            "possible_causes": [
                "Insufficient context in handoff data.",
                "Error pattern not yet registered in KNOWN_ERROR_PATTERNS.",
            ],
            "suggested_fixes": [
                "Include stderr/stdout and command history in debugger input.",
                "Add this signature to KNOWN_ERROR_PATTERNS after root-cause is confirmed.",
            ],
        }

    def _generate_report(
        self,
        environment: Dict[str, Any],
        error_analysis: Dict[str, Any],
        input_data: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Build structured debug report payload."""
        timestamp = datetime.utcnow().isoformat() + "Z"
        stage = str(input_data.get("stage", "unknown"))
        command_history = input_data.get("command_history", [])

        return {
            "timestamp": timestamp,
            "stage": stage,
            "environment": environment,
            "error_analysis": error_analysis,
            "input_context": self._sanitize_input(input_data),
            "command_history": command_history if isinstance(command_history, list) else [],
        }

    def _sanitize_input(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Return sanitized input context with large/noisy values trimmed."""
        redacted_keys = {"path", "env", "environment", "token", "secret", "password", "api_key"}
        sanitized: Dict[str, Any] = {}

        for key, value in input_data.items():
            lowered_key = str(key).lower()
            if any(term in lowered_key for term in redacted_keys):
                sanitized[key] = "[redacted]"
                continue

            if isinstance(value, str) and len(value) > 4000:
                sanitized[key] = value[:4000] + "... [truncated]"
            else:
                sanitized[key] = value

        return sanitized

    def _get_tool_version(self, command: List[str]) -> str:
        """Safely run version command and return parsed first-line output."""
        try:
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                cwd=self.workspace,
                timeout=15,
            )
        except (subprocess.SubprocessError, FileNotFoundError, OSError):
            return "not_available"

        if result.returncode != 0:
            return "not_available"

        output = (result.stdout or result.stderr or "").strip()
        if not output:
            return "not_available"

        first_line = output.splitlines()[0].strip()
        return first_line or "not_available"
