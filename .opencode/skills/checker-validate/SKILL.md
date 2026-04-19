# Skill: checker-validate
**Stage:** quality_validation
**Agent:** checker

## Capability
Validate outputs from completed workflow stages by inspecting handoff records, artifacts, and consistency signals. Return clear pass/warn/fail findings with actionable next-step recommendations.

## Parameters
| Parameter | Config Key | Required | Description |
|-----------|------------|----------|-------------|
| Workspace root | `general.workdir` | Yes | Root workspace containing stage outputs to validate. |
| Receptor workdir | `receptor.workdir` | Conditional | Used when validating receptor ensemble outputs. |
| Docking workdir | `docking.dock_dir` | Conditional | Used when validating docking artifacts and reports. |
| Complex workdir | `complex.workdir` | Conditional | Used when validating complex setup/MD/MMPBSA artifacts. |
| Analysis output subdir | `analysis.output_subdir` | Conditional | Used when validating analysis result locations and completeness. |

## Scripts
| Script | Purpose |
|--------|---------|
| `scripts/commands/checker-validate.sh` | Command entrypoint for checker validation workflow. |

## Success Criteria
- Validation report is produced with explicit pass/warn/fail assessments and evidence.
- Follow-up recommendations identify safe continuation path or required remediation.

## Usage Example
Slash command: `/checker-validate --config config.ini`

Agent invocation: `python -m scripts.agents --agent checker --input handoff.json`

## Workflow
1. Load latest relevant handoff records and identify stage(s) requiring validation.
2. Verify expected output files exist in stage-specific workspace directories.
3. Check consistency/quality indicators and collect anomalies.
4. Produce structured validation summary with severity and recommendations.
5. If data is missing, request rerun or targeted diagnosis before continuation.
