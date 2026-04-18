# Agent Support — Experimental

> **Warning:** Agent-based features in this repository are experimental and may change between releases.

## Status

Agent support is available for integration testing and iterative workflow development, but it is not yet considered stable for all production scientific runs.

## What is experimental

- Agent-based workflow orchestration across pipeline stages.
- Slash command wrappers that dispatch into the Python agent CLI.
- Skill-based capability loading from `.opencode/skills/`.

## What is stable

- Phase 2 shell-script pipeline execution (`scripts/rec`, `scripts/dock`, `scripts/com`).
- Phase 1 configuration system and INI-driven parameter model.
- Manual workflow execution using scripts directly without agents.

## Known limitations

- Agents require OpenCode or a compatible agent runtime.
- Handoff schema and command/agent integration details may evolve.
- Skill documents currently follow agentskills.io v1 conventions, which may be revised.

## Use the project without agents

You can run the pipeline directly through script entrypoints and configuration files:

- Use `scripts/run_pipeline.sh` for staged orchestration.
- Or run stage scripts directly under `scripts/rec/`, `scripts/dock/`, and `scripts/com/`.
- Provide parameters via `config.ini` based on `scripts/config.ini.template`.

This path remains the recommended baseline for reproducible, human-driven execution.

## Feedback and issue reporting

If you observe agent-command integration failures, skill loading issues, or schema mismatches:

- Open an issue in this repository.
- Include the command used, relevant config snippet, and error output.
- Attach `.handoffs/*.json` and `.run_logs/*.log` when available.
