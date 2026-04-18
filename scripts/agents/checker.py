"""Checker agent for workflow stage validation and quality gating."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional

from scripts.agents.base import BaseAgent
from scripts.agents.schemas.handoff import HandoffStatus


@dataclass
class CheckResult:
    """Validation result returned by an individual check."""

    level: str
    message: str
    recommendation: Optional[str] = None


def check_output_exists(data: Dict[str, Any]) -> CheckResult:
    """Verify output directory exists and contains files."""
    output_dir_value = data.get("output_dir")
    if not output_dir_value:
        return CheckResult(
            level="warning",
            message="output_dir not provided for validation.",
            recommendation="Provide output_dir in handoff data for stronger validation coverage.",
        )

    output_dir = Path(output_dir_value)
    if not output_dir.exists() or not output_dir.is_dir():
        return CheckResult(
            level="error",
            message=f"Output directory does not exist: {output_dir}",
            recommendation="Ensure stage writes outputs to configured directory before checker runs.",
        )

    if not any(output_dir.iterdir()):
        return CheckResult(
            level="error",
            message=f"Output directory is empty: {output_dir}",
            recommendation="Confirm script generated expected artifacts and output path is correct.",
        )

    return CheckResult(level="info", message="Output directory exists and contains files.")


def check_return_code(data: Dict[str, Any]) -> CheckResult:
    """Verify stage return code indicates success."""
    returncode = data.get("returncode")
    if returncode is None:
        return CheckResult(
            level="warning",
            message="returncode not provided for validation.",
            recommendation="Include returncode from runner output for deterministic pass/fail checks.",
        )

    if int(returncode) != 0:
        return CheckResult(
            level="error",
            message=f"Stage returned non-zero exit code: {returncode}",
            recommendation="Review stderr and logs, then rerun stage after fixing root cause.",
        )

    return CheckResult(level="info", message="Return code indicates success.")


def check_log_errors(data: Dict[str, Any]) -> CheckResult:
    """Scan log file for fatal/error patterns."""
    log_file_value = data.get("log_file")
    if not log_file_value:
        return CheckResult(
            level="warning",
            message="log_file not provided for error scanning.",
            recommendation="Provide log_file path so checker can detect hidden runtime errors.",
        )

    log_file = Path(log_file_value)
    if not log_file.exists() or not log_file.is_file():
        return CheckResult(
            level="warning",
            message=f"Log file not found: {log_file}",
            recommendation="Ensure stage captures logs and passes log_file to checker.",
        )

    content = log_file.read_text(encoding="utf-8", errors="ignore")
    lower_content = content.lower()
    if "error" in lower_content or "fatal" in lower_content:
        return CheckResult(
            level="error",
            message=f"Detected ERROR/FATAL patterns in log file: {log_file}",
            recommendation="Inspect failing command and resolve reported log errors before continuing.",
        )

    return CheckResult(level="info", message="No ERROR/FATAL patterns found in log file.")


def check_file_sizes(data: Dict[str, Any]) -> CheckResult:
    """Verify reported output files are non-empty."""
    files = data.get("output_files") or []
    if not files:
        return CheckResult(
            level="warning",
            message="No output_files provided for file-size validation.",
            recommendation="Include output_files in handoff data to validate generated artifacts.",
        )

    empty_files: List[str] = []
    missing_files: List[str] = []
    for file_path in files:
        path = Path(file_path)
        if not path.exists() or not path.is_file():
            missing_files.append(str(path))
            continue
        if path.stat().st_size == 0:
            empty_files.append(str(path))

    if missing_files:
        return CheckResult(
            level="error",
            message=f"Expected output files missing: {', '.join(missing_files)}",
            recommendation="Validate output path mapping and rerun stage to regenerate missing files.",
        )

    if empty_files:
        return CheckResult(
            level="warning",
            message=f"Output files are empty: {', '.join(empty_files)}",
            recommendation="Check stage completeness; empty files may indicate partial or failed processing.",
        )

    return CheckResult(level="info", message="All reported output files are non-empty.")


DEFAULT_CHECKS: List[Callable[[Dict[str, Any]], CheckResult]] = [
    check_output_exists,
    check_return_code,
    check_log_errors,
    check_file_sizes,
]


class CheckerAgent(BaseAgent):
    """Validates stage outputs and produces warnings/errors/recommendations."""

    STAGE_CHECKS: Dict[str, List[Callable[[Dict[str, Any]], CheckResult]]] = {}

    def get_role(self) -> str:
        """Return role identifier for this agent."""
        return "checker"

    def execute(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Run checks for a stage and return quality-gate handoff output."""
        stage = str(input_data.get("stage", "unknown"))
        data = input_data.get("data", {}) or {}
        auto_escalate = bool(input_data.get("auto_escalate", False))

        checks = self._get_checks_for_stage(stage)

        warnings: List[str] = []
        errors: List[str] = []
        recommendations: List[str] = []
        check_details: List[Dict[str, Any]] = []

        for check in checks:
            result = check(data)
            check_details.append(
                {
                    "check": check.__name__,
                    "level": result.level,
                    "message": result.message,
                    "recommendation": result.recommendation,
                }
            )

            if result.level == "error":
                errors.append(result.message)
            elif result.level == "warning":
                warnings.append(result.message)

            if result.recommendation:
                recommendations.append(result.recommendation)

        status = HandoffStatus.SUCCESS
        if errors:
            status = HandoffStatus.FAILURE
        elif warnings:
            status = HandoffStatus.NEEDS_REVIEW

        if errors and auto_escalate:
            recommendations.append(
                "Escalate to debugger agent with captured errors and stderr for root-cause diagnosis."
            )

        checkpoint_state = {
            "stage": stage,
            "status": status.value,
            "check_details": check_details,
            "warnings": warnings,
            "errors": errors,
            "recommendations": recommendations,
        }
        self.save_checkpoint(stage, checkpoint_state)

        return self.create_handoff(
            to_agent=input_data.get("next_agent", "orchestrator"),
            stage=stage,
            status=status,
            data={
                "validation_passed": len(errors) == 0,
                "check_details": check_details,
            },
            warnings=warnings,
            errors=errors,
            recommendations=recommendations,
        )

    def _get_checks_for_stage(self, stage: str) -> List[Callable[[Dict[str, Any]], CheckResult]]:
        """Resolve stage checks from registry with default fallback."""
        return self.STAGE_CHECKS.get(stage, DEFAULT_CHECKS)
