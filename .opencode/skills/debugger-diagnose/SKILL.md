# Skill: debugger-diagnose
**Stage:** failure_diagnosis
**Agent:** debugger

## Capability
Diagnose failed or anomalous pipeline stages by correlating handoff status, logs, and tool/version behavior. Provide prioritized root-cause hypotheses and concrete remediation steps.

## Parameters
| Parameter | Config Key | Required | Description |
|-----------|------------|----------|-------------|
| Workspace root | `general.workdir` | Yes | Root workspace used to resolve stage outputs referenced in failures. |
| Receptor force field | `receptor.ff` | Conditional | Useful when diagnosing receptor-stage force-field/setup incompatibilities. |
| Docking mode | `docking.mode` | Conditional | Useful for diagnosing mode-specific gnina/autobox failures. |
| Complex mode | `complex.mode` | Conditional | Useful for diagnosing AMBER vs CHARMM complex preparation issues. |
| MM/PBSA force-field mode | `mmpbsa.ff` | Conditional | Useful for diagnosing topology-selection mismatches in MM/PBSA. |

## Scripts
| Script | Purpose |
|--------|---------|
| `scripts/commands/debugger-diagnose.sh` | Command entrypoint for debugger diagnosis workflow. |

## Success Criteria
- Diagnosis report identifies likely root causes with actionable, stage-specific recovery steps.
- Recommendations provide a clear next command path to re-run or unblock the failed stage.

## Usage Example
Slash command: `/debugger-diagnose --config config.ini`

Agent invocation: `python -m scripts.agents --agent debugger --input handoff.json`

## Workflow
1. Load failing handoff records and correlate with `.run_logs/` evidence.
2. Classify failure type (configuration, dependency/tooling, resource, or scientific/protocol mismatch).
3. Map symptoms to likely root causes, including version-sensitive known issues.
4. Propose ranked remediation actions with minimal-risk recovery order.
5. Provide explicit retry command(s) and validation checks after fix application.
