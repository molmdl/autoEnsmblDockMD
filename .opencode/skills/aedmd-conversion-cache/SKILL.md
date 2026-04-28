---
name: aedmd-conversion-cache
description: Use when deterministic conversions (for example SDF→GRO or GRO→MOL2) are repeated and you need per-workspace cache lookup with staleness detection to avoid redundant recompute, cache misses, or stale artifacts.
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

## Overview

Core principle: cache only deterministic conversions and scope cache state to each workspace. Use staleness checks to avoid both wasted recomputation and stale outputs.

## When to Use
- Conversion-heavy workflows repeatedly run SDF→GRO or GRO→MOL2 transforms.
- You observe cache miss/recompute churn for unchanged inputs.
- Input updates require stale cache invalidation or targeted cache clearing.

## Prerequisites
- Workspace path is known and writable for `.cache/` operations.
- Source/result paths used in cache operations are valid.
- Conda/project environment is active (`source ./scripts/setenv.sh`).

## Quick Reference
- Plugin: `.opencode/plugins/conversion-cache.js` (`aedmd-conversion-cache`)
- Backing module: `scripts/infra/plugins/conversion_cache.py`
- Operations: `get`, `put`, `clear`
- Scope: per-workspace `.cache/` isolation (no global shared cache)

## Parameters
| Parameter | Required | Default | Description |
|---|---|---|---|
| `workspace` | Yes | None | Workspace root containing per-workspace `.cache/` data. |
| `operation` | Yes | None | Cache operation: `get`, `put`, or `clear`. |
| `sourceFile` | Conditional | None | Source file path for `get`/`put` (optional for full `clear`). |
| `targetFormat` | Conditional | None | Target conversion format used in cache keying for `get`/`put`. |
| `resultFile` | Conditional | None | Result file path to store during `put`. |

## Implementation
- Use plugin programmatically (no dedicated shell wrapper by design).
- Return normalized payload: `{ success, data, warnings, errors }`.
- Expect operation-specific fields:
  - `cached_path` for `get`
  - `cached: true` for `put`
  - `cleared: true` for `clear`
- Ensure staleness checks respect source freshness before reusing cached outputs.

## Common Mistakes
- **Expecting cross-workspace reuse**
  - Cache is intentionally workspace-local to protect reproducibility.
- **Assuming misses are always bugs**
  - Misses are expected when source mtime/content indicates staleness.
- **Calling `put` with missing result file**
  - Confirm `resultFile` exists before storing.
- **Clearing with mismatched source path**
  - Use the same source path conventions used during key generation.

## Related Automation Links
- OpenCode plugin: `.opencode/plugins/conversion-cache.js`
- Backing Python module: `scripts/infra/plugins/conversion_cache.py`
- Adjacent conversion commands: `scripts/dock/0_sdf2gro.sh`, `scripts/dock/0_gro2mol2.sh`
