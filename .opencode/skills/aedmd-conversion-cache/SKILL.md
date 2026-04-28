---
name: aedmd-conversion-cache
description: Manage file conversion cache with staleness detection
license: MIT
compatibility: Requires python 3.10+, conda environment
metadata:
  author: autoEnsmblDockMD
  version: "1.0"
  agent: none
  stage: conversion_cache
  token_savings: "1000-2000"
---

# Conversion Cache Management

This skill manages deterministic conversion-cache operations (lookup/store/clear) with staleness checks to avoid redundant conversions while preserving per-workspace isolation.

## When to use this skill
- Before repeating deterministic file conversions (for example SDF→GRO, GRO→MOL2).
- During conversion-heavy workflows to reduce repeated compute and context overhead.
- When clearing stale cache entries after input updates or troubleshooting.

## Prerequisites
- Workspace path is known and writable for `.cache/` operations.
- Source/result paths used in cache operations are valid.
- Conda/project environment is active (`source ./scripts/setenv.sh`).

## Usage
- OpenCode plugin (primary):
  - `.opencode/plugins/conversion-cache.js`
  - Plugin name: `aedmd-conversion-cache`
- Library integration note:
  - This is a library-style plugin (no dedicated `scripts/commands/aedmd-conversion-cache.sh` wrapper in current architecture).
  - It is consumed by conversion scripts/plugins through programmatic calls.

## Parameters
| Parameter | Required | Default | Description |
|---|---|---|---|
| `workspace` | Yes | None | Workspace root containing per-workspace `.cache/` data. |
| `operation` | Yes | None | Cache operation: `get`, `put`, or `clear`. |
| `sourceFile` | Conditional | None | Source file path for `get`/`put` (optional for full `clear`). |
| `targetFormat` | Conditional | None | Target conversion format used in cache keying for `get`/`put`. |
| `resultFile` | Conditional | None | Result file path to store during `put`. |

## Expected Output
- Plugin-normalized result payload: `{ success, data, warnings, errors }`.
- `data` includes operation-specific fields such as:
  - `cached_path` (for `get`)
  - `cached: true` (for `put`)
  - `cleared: true` (for `clear`)
- Cache state reflects staleness-aware behavior (hit/miss/stale) based on source freshness checks.

## Troubleshooting
- **Cache miss when expecting hit**
  - Check whether source file mtime/content changed and invalidated entry.
- **put operation fails**
  - Verify `resultFile` exists and workspace cache directory is writable.
- **clear did not affect expected entries**
  - Confirm `sourceFile` path matches keying inputs used during `put`.

## Related Automation Links
- OpenCode plugin: `.opencode/plugins/conversion-cache.js`
- Backing Python module: `scripts/infra/plugins/conversion_cache.py`
- Adjacent conversion commands: `scripts/dock/0_sdf2gro.sh`, `scripts/dock/0_gro2mol2.sh`
