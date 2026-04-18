"""Analyzer agent for standard and custom stage analyses."""

from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Any, Dict, List, Optional

from scripts.agents.base import BaseAgent
from scripts.agents.schemas.handoff import HandoffStatus


class AnalyzerAgent(BaseAgent):
    """Runs built-in and custom analysis scripts for workflow stages."""

    STAGE_ANALYSIS_MAP: Dict[str, List[str]] = {
        "complex_analysis": ["scripts/com/3_ana.sh"],
        "receptor_cluster": ["scripts/rec/3_ana.sh"],
    }

    def get_role(self) -> str:
        """Return role identifier for this agent."""
        return "analyzer"

    def execute(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Execute stage analysis and return a structured handoff payload."""
        stage = str(input_data.get("stage", "unknown"))
        analysis_type = str(input_data.get("analysis_type", "standard"))
        data = input_data.get("data", {}) or {}

        scripts = self.STAGE_ANALYSIS_MAP.get(stage, [])
        analysis_outputs: Dict[str, Dict[str, Any]] = {}
        warnings: List[str] = []
        errors: List[str] = []

        for script in scripts:
            result = self._run_analysis(script=script, params=data)
            analysis_outputs[script] = result
            if result.get("returncode", 1) != 0:
                errors.append(f"Analysis script failed: {script}")
                if result.get("stderr"):
                    warnings.append(result["stderr"].strip())

        custom_outputs: List[Dict[str, Any]] = []
        if analysis_type in {"custom", "all", "standard+custom", "standard_and_custom"}:
            custom_outputs = self._run_custom_hooks(stage=stage, data=data)
            for hook_result in custom_outputs:
                if hook_result.get("returncode", 1) != 0:
                    errors.append(f"Custom analysis hook failed: {hook_result.get('script', 'unknown')}")

        output_files: List[str] = []
        for result in analysis_outputs.values():
            output_files.extend(result.get("output_files", []))
        for hook_result in custom_outputs:
            output_files.extend(hook_result.get("output_files", []))

        output_files = sorted(set(output_files))
        status = HandoffStatus.FAILURE if errors else HandoffStatus.SUCCESS

        checkpoint_state = {
            "stage": stage,
            "analysis_type": analysis_type,
            "scripts": scripts,
            "analysis_outputs": analysis_outputs,
            "custom_outputs": custom_outputs,
            "output_files": output_files,
        }
        self.save_checkpoint(stage, checkpoint_state)

        return self.create_handoff(
            to_agent=input_data.get("next_agent", "orchestrator"),
            stage=stage,
            status=status,
            data={
                "analysis_outputs": analysis_outputs,
                "custom_outputs": custom_outputs,
                "output_files": output_files,
            },
            warnings=warnings,
            errors=errors,
            recommendations=[
                "Review failed analysis scripts and rerun once inputs are corrected."
            ]
            if errors
            else [],
        )

    def _run_analysis(self, script: str, params: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a standard analysis script and return execution metadata."""
        script_path = Path(script)
        if not script_path.is_absolute():
            script_path = self.workspace / script_path

        if not script_path.exists():
            return {
                "returncode": 127,
                "stdout": "",
                "stderr": f"Analysis script not found: {script_path}",
                "output_files": [],
            }

        command = self._build_command(script_path, params)
        result = subprocess.run(
            command,
            cwd=self.workspace,
            capture_output=True,
            text=True,
        )

        output_dir = self._resolve_output_dir(params)
        output_files = self._collect_output_files(output_dir)

        return {
            "returncode": result.returncode,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "output_files": output_files,
        }

    def _run_custom_hooks(self, stage: str, data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Execute custom hook scripts from workspace/custom_analysis/<stage>."""
        hooks_dir = self.workspace / "custom_analysis" / stage
        if not hooks_dir.exists() or not hooks_dir.is_dir():
            return []

        results: List[Dict[str, Any]] = []
        hook_scripts = sorted(
            [
                path
                for path in hooks_dir.iterdir()
                if path.is_file() and path.suffix in {".py", ".sh"}
            ]
        )

        for hook_script in hook_scripts:
            command = self._build_command(hook_script, data)
            proc = subprocess.run(
                command,
                cwd=self.workspace,
                capture_output=True,
                text=True,
            )
            output_files = self._collect_output_files(hooks_dir)
            results.append(
                {
                    "script": str(hook_script),
                    "returncode": proc.returncode,
                    "stdout": proc.stdout,
                    "stderr": proc.stderr,
                    "output_files": output_files,
                }
            )

        return results

    def _collect_output_files(
        self,
        output_dir: Path,
        patterns: Optional[List[str]] = None,
    ) -> List[str]:
        """Collect analysis output files from directory using glob patterns."""
        if not output_dir.exists() or not output_dir.is_dir():
            return []

        search_patterns = patterns or ["*.xvg", "*.csv", "*.png", "*.dat"]
        files: List[str] = []
        for pattern in search_patterns:
            files.extend(str(path) for path in output_dir.glob(pattern) if path.is_file())
        return sorted(set(files))

    def _build_command(self, script_path: Path, params: Dict[str, Any]) -> List[str]:
        """Build command for script execution based on file extension."""
        if script_path.suffix == ".sh":
            command: List[str] = ["bash", str(script_path)]
        elif script_path.suffix == ".py":
            command = ["python", str(script_path)]
        else:
            command = [str(script_path)]

        for key, value in (params or {}).items():
            if isinstance(value, (dict, list)):
                continue

            flag = f"--{str(key).replace('_', '-')}"
            if isinstance(value, bool):
                if value:
                    command.append(flag)
                continue

            if value is None:
                continue

            command.extend([flag, str(value)])

        return command

    def _resolve_output_dir(self, params: Dict[str, Any]) -> Path:
        """Resolve output directory from params with workspace fallback."""
        output_dir = params.get("output_dir") if isinstance(params, dict) else None
        if output_dir:
            output_path = Path(output_dir)
            return output_path if output_path.is_absolute() else self.workspace / output_path
        return self.workspace
