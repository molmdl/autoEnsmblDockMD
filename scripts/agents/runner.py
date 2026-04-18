"""Runner agent implementation for structured script execution."""

from __future__ import annotations

import os
import re
import subprocess
import time
from pathlib import Path
from typing import Any, Dict, List

from scripts.agents.base import BaseAgent
from scripts.agents.schemas.handoff import HandoffStatus


class RunnerAgent(BaseAgent):
    """Agent responsible for stage script execution and result shaping."""

    def get_role(self) -> str:
        """Return role identifier for this agent."""
        return "runner"

    def execute(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Execute script for a workflow stage and return handoff payload."""
        stage = input_data.get("stage", "unknown")
        script = input_data["script"]
        params = input_data.get("params", {})
        env = input_data.get("env")

        result = self._run_script(script=script, params=params, env=env)
        metrics = self._extract_metrics(result)
        warnings = self._extract_warnings(result)

        status = HandoffStatus.SUCCESS if result["returncode"] == 0 else HandoffStatus.FAILURE
        errors = [] if result["returncode"] == 0 else [result["stderr"].strip() or "Script execution failed."]

        stage_state = {
            "script": script,
            "params": params,
            "returncode": result["returncode"],
            "command": result["command"],
            "duration_seconds": result["duration_seconds"],
            "metrics": metrics,
            "warnings": warnings,
        }
        self.save_checkpoint(str(stage), stage_state)

        return self.create_handoff(
            to_agent=input_data.get("next_agent", "orchestrator"),
            stage=str(stage),
            status=status,
            data={
                "stage": str(stage),
                "script_result": result,
                "metrics": metrics,
            },
            warnings=warnings,
            errors=errors,
        )

    def _run_script(
        self,
        script: str,
        params: Dict[str, Any],
        env: Dict[str, str] = None,
    ) -> Dict[str, Any]:
        """Run a script command and capture execution details."""
        command_list = self._build_command(script, params)
        command_str = " ".join(command_list)

        merged_env = os.environ.copy()
        if env:
            merged_env.update(env)

        started = time.time()
        proc = subprocess.run(
            command_list,
            cwd=self.workspace,
            capture_output=True,
            text=True,
            env=merged_env,
        )
        duration = time.time() - started

        return {
            "returncode": proc.returncode,
            "stdout": proc.stdout,
            "stderr": proc.stderr,
            "command": command_str,
            "duration_seconds": duration,
        }

    def _build_command(self, script: str, params: Dict[str, Any]) -> List[str]:
        """Build executable command from script path and CLI parameters."""
        script_path = Path(script)
        if script_path.suffix == ".sh":
            command: List[str] = ["bash", str(script_path)]
        elif script_path.suffix == ".py":
            command = ["python", str(script_path)]
        else:
            command = [str(script_path)]

        for key, value in (params or {}).items():
            flag = f"--{str(key).replace('_', '-')}"
            if isinstance(value, bool):
                if value:
                    command.append(flag)
                continue

            command.append(flag)
            command.append(str(value))

        return command

    def _extract_metrics(self, result: Dict[str, Any]) -> Dict[str, Any]:
        """Best-effort extraction of numeric metrics from stdout."""
        metrics: Dict[str, Any] = {}
        for line in result.get("stdout", "").splitlines():
            lowered = line.lower()
            if not any(token in lowered for token in ("rmsd", "energy", "score")):
                continue

            numeric = re.findall(r"[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?", line)
            key = lowered.split(":", 1)[0].strip()
            if not key:
                key = "metric"

            if numeric:
                metrics[key] = float(numeric[-1])
            else:
                metrics[key] = line.strip()

        return metrics

    def _extract_warnings(self, result: Dict[str, Any]) -> List[str]:
        """Extract warnings/errors from stderr and return code."""
        warnings: List[str] = []
        for line in result.get("stderr", "").splitlines():
            lowered = line.lower()
            if "warn" in lowered or "warning" in lowered or "error" in lowered:
                warnings.append(line.strip())

        if result.get("returncode", 0) != 0:
            warnings.append(f"Non-zero return code: {result['returncode']}")

        return warnings
