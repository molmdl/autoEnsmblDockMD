# Phase 6: Automation Infrastructure - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement automation hooks and plugins to reduce token usage during repeated workflow-support operations. Plugins are workflow-native steps (not external add-ons) that intercept common operations (setup, validation, inspection, caching, verification) to provide machine-readable outputs that agents can consume without loading large context. Phase 6 targets the 5 highest-priority automation opportunities from quick-003 analysis.

</domain>

<decisions>
## Implementation Decisions

### Plugin Architecture & Integration

- **Plugin discovery:** Research how OpenCode detects/loads plugins before architecture decisions. Plugins must work within conda environment only — no new tool installations.
- **Plugin usage pattern:** Plugins are workflow steps, not generic extensions. Design for agent use within workflow to reduce LLM context overhead, not general-purpose extensibility.
- **Plugin output consistency:** Plugins inherit existing codebase patterns (examine current handoff/status behavior) and must produce outputs compatible with workflow artifacts. Minimal contract: align with existing exit codes and data structures.
- **Plugin ordering:** Research current stage execution order before deciding on dependencies. Plugins should integrate naturally into existing workflow stages without adding external orchestration complexity.

### Workspace Initialization Scope

- **Workspace creation template:** Follow current workflow patterns (see WORKFLOW.md + agent skills). Research current initialization approach to ensure consistency.
- **Input handling strategy:** Use question tool to prompt for missing inputs rather than failing silently or warning. Ask user to correct input directory path before proceeding — don't create workspace with incomplete inputs.
- **Workspace-init output:** Report initialization status to a location consistent with workflow artifacts (see existing checkpoint/handoff structure). Research where init should persist results for runner/checker inspection.
- **Existing workspace handling:** Ask user before overwriting existing workspace. Do not silently overwrite or fail; prompt for user decision.

### Preflight Validation Strictness

- **Validation severity tiers:** Examine current validation behavior before choosing severity levels. Balance blocking failures vs advisory warnings based on existing patterns.
- **Validation scope:** Determine comprehensiveness (all systems vs focused path vs delegated to stages) by checking current behavior first. Aim for consistency with existing validation approach.
- **Validation rule configuration:** If no existing configuration mechanism, research and decide with reasoning. Can be hardcoded, config-driven, or pluggable — choose based on current codebase patterns.
- **Validation output format:** Check current behavior for consistency (likely JSON + structured text). Ensure downstream agents/checkers can parse outputs deterministically.

### Handoff Inspector Output

- **Handoff normalization:** Research current handoff record structure and normalization needs. Normalize status vocabulary and enrich with context only if current codebase supports it.
- **Inspector output format:** Check current behavior for machine-readable vs human-readable balance. Likely both JSON (for agents) + text (for humans).
- **Workflow history depth:** Research before deciding. Show only what's actionable — likely latest handoff + summary or latest + breadcrumb trail, not full history dump.
- **Next-action guidance:** If current behavior exists, match it. Otherwise, research and decide: suggest specific next command, list blockers, or show all valid options. Decision should minimize user confusion about what to do next.

### Cache Invalidation Strategy

- **Stale detection method:** Check current behavior for cache detection patterns. Timestamp-based (mtime) is simpler; content-hash is more robust. Choose based on existing patterns.
- **Cache expiry policy:** If no current pattern, decide with reasoning. Recommend: no automatic expiry (rely on stale detection), but allow per-workspace isolation and manual clearing.
- **Cache location:** Research current artifact/workspace structure before choosing. Likely local filesystem per-workspace (not global shared cache) to preserve workspace isolation.
- **Cache usage control:** Check for existing --cache/--no-cache patterns. Recommend: opt-in via flag (explicit, auditable, safe by default) rather than automatic use.

### Integration Point — Lifecycle Hooks

Based on quick-003 analysis (high-priority automation opportunities ranked by token savings):

| Lifecycle Point | Plugin | Est. Token Savings/Run | Priority |
|---|---|---:|---|
| Before wrapper dispatch | Preflight validation hook | 2,000–4,000 | High |
| Workspace creation | workspace-init plugin | 1,500–3,000 | High |
| After each handoff write | Handoff inspector hook | 1,200–2,500 | High |
| Before MM/PBSA stage | Group ID consistency checker | 900–1,800 | High |
| File transform operations | Conversion cache manager | 1,000–2,000 | High |

**Aggregate estimated savings:** 6,600–13,300 tokens per run-support cycle

</decisions>

<specifics>
## Specific Ideas

- **Workspace pattern:** Follow the copy-from-template approach documented in WORKFLOW.md (inputs in `work/input/` → isolated run workspace in `work/test/` or `work/run_YYYY-MM-DD/`).
- **Preflight as first gate:** Preflight validation should run before any stage execution to fail fast on configuration/file issues.
- **Handoff inspector for debugging:** The handoff inspector hook is critical for checkpoint/resume/debug workflows — it normalizes status and prevents repeated JSON parsing by agents.
- **Cache for high-reuse conversions:** Focus cache on file transformations (SDF↔GRO, GRO↔MOL2) that are deterministic and commonly repeated. Index-file lookups and group-ID checks are good candidates for caching.
- **Constraint reminder:** All plugins must work within existing conda environment. Research should check how OpenCode handles plugin discovery and ensure no external tool installations are required.

</specifics>

<deferred>
## Deferred Ideas

- **Scheduler monitoring agent** (Slurm state monitor + summarizer) — Ranked #6 in automation opportunities (800–1,600 tokens/run savings). Addresses async workflow monitoring but deferred to Phase 7 or backlog pending Phase 6 validation.
- **Error-signature diagnosis router** — Ranked #7 (700–1,500 tokens/run savings). Requires rich error pattern registry and debugger integration. Defer to post-Phase-7 optimization.
- **Config derivation assistant** — Ranked #8 (600–1,400 tokens/run savings). Useful but lower priority. Defer to backlog for future phases.

</deferred>

---

*Phase: 06-automation-infrastructure*
*Context gathered: 2026-04-28*
