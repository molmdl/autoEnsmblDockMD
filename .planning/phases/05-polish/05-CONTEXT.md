# Phase 5: Polish - Context

**Gathered:** 2026-04-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Finalize all documentation (README, WORKFLOW, AGENTS) and perform end-to-end validation of the complete system. This phase focuses on clarity, structure, and ensuring the integrated system (from Phase 4) is documented for both human users and agents. Ligand preparation (SCRIPT-02) remains explicitly deferred to v2.

</domain>

<decisions>
## Implementation Decisions

### README Structure & Audience
- Quick start first: one-liner + why it matters + quick install (not full context)
- Full pipeline walkthrough example: receptor prep → docking → MD → MMPBSA (not modular examples)
- Human-optimized primary audience; agents link to detailed docs elsewhere
- Linear narrative flow: What, Why, Quick Install, Usage (full pipeline), Configuration, Troubleshooting

### Agent Documentation Format
- Optimization priority: agents first, but no duplication; single format readable by both
- Metadata fields to include: capability summary, parameter reference, success criteria, usage examples
- Distribution: one file per skill in `.opencode/skills/` (distributed by skill, not centralized)
- Format: YAML-optimized with Markdown readability (hybrid YAML/Markdown structure)

### End-to-End Validation
- Full pipeline execution: receptor prep → docking → MD → MMPBSA → analysis (complete test, not subset)
- Test data: use existing files from `work/input` (check AGENTS.md for file locations, ask user if missing)
- Success criteria: structure correct + values acceptable (not exact match, allows tolerance)
- Validation reporting: clear, concise, minimal but sufficient in main context; detailed report stored in phase directory

### AGENTS.md Restructure & Expansion
- Restructure + expand: reorganize by agent type with cross-references to skills
- New sections: agent type workflows, file-based handoff patterns, skill authoring guide, troubleshooting deferred to agent-specific docs
- Focus: AGENTS.md as human-readable overview + reference; distributed skill files provide implementation details
- Experimental status clearly marked (Phase 4 requirement maintained)

### OpenCode's Discretion
- Exact agent documentation file format within YAML/Markdown hybrid (structure locked, format details flexible)
- Validation report visual presentation and artifact organization
- AGENTS.md section ordering and cross-reference structure
- README visual design and code block styling

</decisions>

<specifics>
## Specific Ideas

- README full pipeline walkthrough should be concrete: show actual commands, config snippets, expected output structure
- Agent docs should be loadable at runtime: metadata parseable without human interpretation
- E2E validation should catch both crashes and structural problems (not just "runs without error")
- AGENTS.md should feel like a "getting started for agent developers" guide, not just feature list

</specifics>

<deferred>
## Deferred Ideas

- SCRIPT-02 (ligand preparation automation) — Phase v2
- API documentation or interactive skill explorer — future enhancement
- Auto-generation of agent docs from code annotations — future automation

</deferred>

---

*Phase: 05-polish*
*Context gathered: 2026-04-19*
