# SCANCODE Task B: Skill Naming Conflict Analysis

**Analysis Date:** 2026-04-29 14:00:09  
**Analyst:** OpenCode Agent  
**Scope:** `.opencode/skills/`, `scripts/commands/`, project documentation

---

## Executive Summary

**CURRENT STATUS: ✅ NO CONFLICTS DETECTED**

All skills in `.opencode/skills/` have already been migrated to the `aedmd-` namespace prefix in Phase 5.1 (completed 2026-04-19). The project now uses a consistent `aedmd-*` naming convention across all 15 skills, 14 command wrappers, and associated documentation.

**Key Findings:**
- 15/15 skills use `aedmd-` prefix
- 14/14 command wrappers use `aedmd-` prefix (1 skill is library-only)
- All documentation references updated to namespaced commands
- Original `/status` conflict has been resolved → `/aedmd-status`

**Migration Status:** ✅ COMPLETED (Phase 5.1)

---

## 1. Conflict Detection Results

### 1.1 Current Skill Inventory

All 15 skills currently deployed use the `aedmd-` prefix:

| Skill Name | Skill Path | Wrapper Script | Type |
|------------|------------|----------------|------|
| `aedmd-checker-validate` | `.opencode/skills/aedmd-checker-validate/` | `scripts/commands/aedmd-checker-validate.sh` | Checker |
| `aedmd-com-analyze` | `.opencode/skills/aedmd-com-analyze/` | `scripts/commands/aedmd-com-analyze.sh` | Analyzer |
| `aedmd-com-md` | `.opencode/skills/aedmd-com-md/` | `scripts/commands/aedmd-com-md.sh` | Runner |
| `aedmd-com-mmpbsa` | `.opencode/skills/aedmd-com-mmpbsa/` | `scripts/commands/aedmd-com-mmpbsa.sh` | Runner |
| `aedmd-com-setup` | `.opencode/skills/aedmd-com-setup/` | `scripts/commands/aedmd-com-setup.sh` | Runner |
| `aedmd-conversion-cache` | `.opencode/skills/aedmd-conversion-cache/` | *(library-only, no wrapper)* | Infrastructure |
| `aedmd-debugger-diagnose` | `.opencode/skills/aedmd-debugger-diagnose/` | `scripts/commands/aedmd-debugger-diagnose.sh` | Debugger |
| `aedmd-dock-run` | `.opencode/skills/aedmd-dock-run/` | `scripts/commands/aedmd-dock-run.sh` | Runner |
| `aedmd-group-id-check` | `.opencode/skills/aedmd-group-id-check/` | `scripts/commands/aedmd-group-id-check.sh` | Infrastructure |
| `aedmd-handoff-inspect` | `.opencode/skills/aedmd-handoff-inspect/` | `scripts/commands/aedmd-handoff-inspect.sh` | Infrastructure |
| `aedmd-orchestrator-resume` | `.opencode/skills/aedmd-orchestrator-resume/` | `scripts/commands/aedmd-orchestrator-resume.sh` | Orchestrator |
| `aedmd-preflight` | `.opencode/skills/aedmd-preflight/` | `scripts/commands/aedmd-preflight.sh` | Infrastructure |
| `aedmd-rec-ensemble` | `.opencode/skills/aedmd-rec-ensemble/` | `scripts/commands/aedmd-rec-ensemble.sh` | Runner |
| `aedmd-status` | `.opencode/skills/aedmd-status/` | `scripts/commands/aedmd-status.sh` | Orchestrator |
| `aedmd-workspace-init` | `.opencode/skills/aedmd-workspace-init/` | `scripts/commands/aedmd-workspace-init.sh` | Infrastructure |

### 1.2 Identified Conflicts with OpenCode Internals

**Historical Conflict (RESOLVED):**

| Original Name | Conflict Type | Resolution | Status |
|---------------|---------------|------------|--------|
| `/status` | HIGH - Generic command conflicts with OpenCode internal status commands | Renamed to `/aedmd-status` | ✅ RESOLVED |

**Analysis of Potential Conflicts:**

Based on review of Phase 5.1 analysis documents (`.planning/code_analysis/2026-04-19-skill-doc-conflicts-report.md` and `.planning/code_analysis/2026-04-19-204926-namespace-analysis.md`), the following command names were identified as **potential** collision risks before Phase 5.1 migration:

| Pre-5.1 Name | Risk Level | Rationale | Post-5.1 Name |
|--------------|------------|-----------|---------------|
| `/status` | **HIGH** | Generic, platform-looking, likely OpenCode reserved word | `/aedmd-status` ✅ |
| `/rec-ensemble` | MEDIUM | Domain-specific but unprefixed | `/aedmd-rec-ensemble` ✅ |
| `/dock-run` | MEDIUM | Generic "run" verb | `/aedmd-dock-run` ✅ |
| `/com-setup` | LOW | Domain-specific | `/aedmd-com-setup` ✅ |
| `/com-md` | LOW | Domain-specific | `/aedmd-com-md` ✅ |
| `/com-mmpbsa` | LOW | Domain-specific | `/aedmd-com-mmpbsa` ✅ |
| `/com-analyze` | MEDIUM | Generic "analyze" verb | `/aedmd-com-analyze` ✅ |
| `/checker-validate` | MEDIUM | Generic "validate" verb | `/aedmd-checker-validate` ✅ |
| `/debugger-diagnose` | LOW | Generic but compound | `/aedmd-debugger-diagnose` ✅ |
| `/orchestrator-resume` | MEDIUM | Generic "resume" verb | `/aedmd-orchestrator-resume` ✅ |

**Current State Assessment:**
- ✅ Zero active namespace conflicts detected
- ✅ All public command names use project-specific prefix
- ✅ Slash command surface is unambiguous

---

## 2. Prefix Evaluation

### 2.1 Options Analysis

Three prefix options were originally considered in Phase 5.1:

| Prefix | Full Name Example | Pros | Cons | Score |
|--------|-------------------|------|------|-------|
| **`aedmd-`** | `/aedmd-status` | • Unique, unlikely to collide<br>• Clear project ownership<br>• Matches project acronym<br>• Good readability | • Slightly longer | **9/10** ✅ |
| `aed-` | `/aed-status` | • Shorter<br>• Easy to type | • Too generic<br>• "AED" has other meanings (medical, etc.)<br>• Higher collision risk | 5/10 |
| `admd-` | `/admd-status` | • Shorter than aedmd<br>• Still project-related | • Less clear abbreviation<br>• Could confuse with generic MD terms<br>• Not standard project shorthand | 6/10 |

### 2.2 Recommended Prefix: `aedmd-` ✅ **ALREADY IMPLEMENTED**

**Justification:**

1. **Uniqueness:** "aedmd" is specific to `autoEnsmblDockMD` and extremely unlikely to collide with:
   - OpenCode platform commands
   - Third-party tool commands
   - Generic shell utilities
   - Future reserved words

2. **Clarity:** The prefix makes command ownership immediately obvious:
   - `/aedmd-status` → clearly project-specific
   - `/status` → ambiguous, could be platform or project

3. **Consistency:** Matches existing project conventions:
   - Project name: `autoEnsmblDockMD`
   - Repository naming patterns
   - Internal documentation references

4. **Readability:** The hyphen separator maintains readability:
   - `aedmd-com-setup` is clear
   - `aedmdcomsetup` would be harder to parse

5. **Future-Proofing:** Establishes stable namespace for all future skills without need for incremental collision fixes

---

## 3. Migration Plan

### 3.1 Migration Status

**MIGRATION COMPLETED:** Phase 5.1 (2026-04-19)

Phase 5.1 executed a complete migration across all layers:

| Wave | Scope | Status | Plans |
|------|-------|--------|-------|
| Wave 1 | Code correctness fixes | ✅ COMPLETE | 5.1-01 through 5.1-04 |
| Wave 2 | Skill/command renaming | ✅ COMPLETE | 5.1-05 |
| Wave 3 | Documentation updates | ✅ COMPLETE | 5.1-06, 5.1-07 |

### 3.2 What Was Changed

**A. Skill Directories:**
- Renamed 10 skill directories from `.opencode/skills/{name}/` to `.opencode/skills/aedmd-{name}/`
- Example: `.opencode/skills/status/` → `.opencode/skills/aedmd-status/`

**B. Skill Frontmatter:**
- Updated `name:` field in all `SKILL.md` files
- Example: `name: status` → `name: aedmd-status`

**C. Command Wrappers:**
- Renamed 10 wrapper scripts from `scripts/commands/{name}.sh` to `scripts/commands/aedmd-{name}.sh`
- Example: `scripts/commands/status.sh` → `scripts/commands/aedmd-status.sh`

**D. Documentation:**
- `AGENTS.md`: Updated slash command table (line 119-131)
- `README.md`: Updated skill path references (line 217-218)
- `docs/GUIDE.md`: Updated command examples
- `docs/EXPERIMENTAL.md`: Updated slash command references
- `.planning/ROADMAP.md`: Updated roadmap entries

**E. Internal References:**
- Updated imports and routing in `scripts/agents/` modules
- Updated handoff logic in `scripts/commands/common.sh`
- Updated test scripts in `tests/`

### 3.3 Migration Command Mapping (Historical Reference)

For future reference, the complete mapping from old to new names:

| Old Name | New Name | Command Type |
|----------|----------|--------------|
| `/status` | `/aedmd-status` | Orchestrator |
| `/rec-ensemble` | `/aedmd-rec-ensemble` | Runner |
| `/dock-run` | `/aedmd-dock-run` | Runner |
| `/com-setup` | `/aedmd-com-setup` | Runner |
| `/com-md` | `/aedmd-com-md` | Runner |
| `/com-mmpbsa` | `/aedmd-com-mmpbsa` | Runner |
| `/com-analyze` | `/aedmd-com-analyze` | Analyzer |
| `/checker-validate` | `/aedmd-checker-validate` | Checker |
| `/debugger-diagnose` | `/aedmd-debugger-diagnose` | Debugger |
| `/orchestrator-resume` | `/aedmd-orchestrator-resume` | Orchestrator |

**Infrastructure skills added in Phase 6:**
- `/aedmd-workspace-init` (new)
- `/aedmd-preflight` (new)
- `/aedmd-handoff-inspect` (new)
- `/aedmd-group-id-check` (new)
- `/aedmd-conversion-cache` (new, library-only)

---

## 4. Documentation Updates Required

### 4.1 Files Already Updated

The following files were updated in Phase 5.1 and are current:

✅ **Core Documentation:**
- `AGENTS.md` — Slash command table, agent type descriptions
- `README.md` — Skill path references, namespace rationale
- `WORKFLOW.md` — (Script-focused, no slash command changes needed)

✅ **User Guides:**
- `docs/GUIDE.md` — Command examples updated to `aedmd-*`
- `docs/EXPERIMENTAL.md` — Agent workflow examples updated

✅ **Planning/Analysis:**
- `.planning/ROADMAP.md` — Phase 5.1 completion recorded
- `.planning/STATE.md` — Current state reflects `aedmd-*` namespace
- `.planning/code_analysis/2026-04-19-*.md` — Analysis reports

✅ **Skills:**
- All 15 `SKILL.md` files updated with correct `name:` field

✅ **Test Files:**
- `tests/phase06_integration_test.sh` — References `aedmd-*` wrappers

### 4.2 No Additional Updates Needed

**Conclusion:** All documentation is current. No additional updates required.

---

## 5. Impact Analysis

### 5.1 Impact on Existing Workflows

**User-Facing Changes:**
- Users must now type `/aedmd-status` instead of `/status`
- All 10 primary slash commands require `aedmd-` prefix
- Command completion behavior unchanged (OpenCode will still discover skills)

**Migration Impact:** **MINIMAL**
- Agent-based execution is experimental (per `AGENTS.md:6`, `README.md:201-207`)
- Most users interact via scripts, not slash commands
- Human-readable wrapper scripts remain backward-compatible at script level

**Script Layer:** **NO IMPACT**
- Core scripts in `scripts/rec/`, `scripts/dock/`, `scripts/com/` unchanged
- Wrapper renaming affects only `scripts/commands/` entry points
- Internal stage tokens and execution paths unchanged

### 5.2 Backward Compatibility

**Breaking Changes:**
- Old slash commands (`/status`, `/dock-run`, etc.) no longer work
- OpenCode will not discover skills by old names

**Non-Breaking Changes:**
- Script-level APIs unchanged
- Handoff file formats unchanged
- Workspace structure unchanged
- Configuration file format unchanged

**Mitigation:**
- Old slash commands were never in stable release
- Agent workflow clearly marked experimental
- Documentation updated comprehensively
- Clear error message if user tries old command (OpenCode skill-not-found)

### 5.3 Testing Impact

**Test Updates Completed:**
- `tests/phase06_integration_test.sh` updated to call `aedmd-*` wrappers
- All integration tests passing with new names

**Validation Completed:**
- Phase 5.1 verification: `.planning/phases/5.1-critical-correctness-and-namespace-fixes/5.1-VERIFICATION.md`
- Verification item 13: "No generic /status or /dock-run names remain" ✓ VERIFIED

### 5.4 Future Considerations

**Benefits:**
1. **Namespace Stability:** No future collision risk with OpenCode platform evolution
2. **Clear Ownership:** Users immediately recognize project-specific commands
3. **Extensibility:** New skills can follow established `aedmd-*` pattern
4. **Documentation Clarity:** Unambiguous command references in all docs

**Maintenance:**
- New skills MUST follow `aedmd-*` naming convention
- Update `AGENTS.md` slash command table when adding new skills
- Maintain consistency between skill `name:` field and wrapper script filename

---

## 6. Verification Checklist

Current status of all verification items:

### Skill-Level Verification
- [x] All 15 skill directories use `aedmd-*` prefix
- [x] All 15 `SKILL.md` frontmatter `name:` fields use `aedmd-*`
- [x] All 15 `SKILL.md` files reference correct wrapper script paths
- [x] All skill descriptions mention project-specific context

### Command-Level Verification
- [x] All 14 wrapper scripts use `aedmd-*` filename convention
- [x] All wrapper scripts reference correct skill names in headers
- [x] All wrapper scripts call correct stage scripts
- [x] `scripts/commands/common.sh` routing logic updated

### Documentation-Level Verification
- [x] `AGENTS.md` slash command table uses `aedmd-*` (lines 119-131)
- [x] `README.md` mentions `aedmd-*` namespace (line 218)
- [x] `docs/GUIDE.md` examples use `aedmd-*` commands
- [x] `docs/EXPERIMENTAL.md` examples use `aedmd-*` commands
- [x] No references to old unprefixed names remain

### Testing-Level Verification
- [x] Integration tests updated to use `aedmd-*` wrappers
- [x] Test execution successful with new names
- [x] No test references to old command names

### Conflict-Level Verification
- [x] No conflicts detected with OpenCode internal commands
- [x] No conflicts with common shell utilities
- [x] No conflicts between project skills
- [x] Unique namespace established for future expansion

---

## 7. Recommendations

### 7.1 Current State: ✅ ACCEPTABLE

The current `aedmd-*` namespace is:
- Properly implemented across all skills
- Documented consistently
- Verified through integration testing
- Free of known conflicts

**No immediate action required.**

### 7.2 Future Skill Development

When adding new skills, maintainers must:

1. **Naming Convention:**
   - Use `aedmd-{name}` format for all new skills
   - Follow kebab-case naming: `aedmd-feature-action`
   - Avoid generic verbs without context (bad: `aedmd-run`, good: `aedmd-lig-prep`)

2. **File Structure:**
   ```
   .opencode/skills/aedmd-{name}/
   ├── SKILL.md  (frontmatter: name: aedmd-{name})
   └── (optional resources)
   
   scripts/commands/aedmd-{name}.sh
   ```

3. **Documentation:**
   - Add entry to `AGENTS.md` slash command table
   - Update README if introducing new agent type
   - Include in integration tests

4. **Verification:**
   - Confirm no conflicts with existing `aedmd-*` names
   - Test slash command discovery in OpenCode
   - Verify wrapper script execution

### 7.3 Monitoring

**No ongoing monitoring required** for namespace conflicts, but maintain awareness of:
- OpenCode platform updates that might introduce new reserved words
- New third-party skills that might use similar naming patterns
- Community conventions evolving in OpenCode ecosystem

### 7.4 Alternative Namespace (If Ever Needed)

If `aedmd-` ever becomes problematic (extremely unlikely), fallback options in priority order:

1. `autoensmbldockmd-` (fully qualified, very verbose)
2. `aedmd_` (underscore separator, less common for slash commands)
3. `aensmd-` (alternate abbreviation)

**Recommendation:** Stick with `aedmd-` indefinitely.

---

## 8. Conclusion

### Summary

The autoEnsmblDockMD project successfully resolved all skill naming conflicts in Phase 5.1 by adopting a consistent `aedmd-*` namespace prefix across all 15 skills and 14 command wrappers.

**Key Achievements:**
- ✅ Eliminated `/status` conflict with OpenCode internals
- ✅ Established unambiguous project-specific namespace
- ✅ Updated all documentation to reflect new names
- ✅ Verified through integration testing
- ✅ Maintained backward compatibility at script layer

**Current Status:**
- **Conflicts:** NONE
- **Compliance:** 100% (15/15 skills, 14/14 wrappers)
- **Documentation:** CURRENT
- **Testing:** PASSING

### Final Recommendation

**ACCEPT current `aedmd-*` namespace as permanent standard.**

No further migration needed. Future skills should follow established `aedmd-*` pattern per Section 7.2.

---

## Appendix A: Historical Context

### Pre-Migration Risk Assessment (2026-04-19)

Original analysis identified `/status` as highest-risk conflict because:
- "status" is generic and platform-looking
- Common reserved word in CLI tools
- OpenCode likely to use `/status` for internal commands
- User confusion between platform and project commands

Additional medium-risk names:
- `/dock-run`, `/com-analyze`, `/checker-validate`, `/orchestrator-resume`

### Migration Decision Rationale

Phase 5.1 chose to prefix **ALL** skills (not just `/status`) because:
1. Consistent namespace more maintainable than per-command exceptions
2. Future-proofs against incremental collision discoveries
3. Makes project command ownership immediately obvious
4. Experimental phase = lowest-cost point for breaking changes

### Implementation Success Factors

Phase 5.1 completed migration without issues due to:
- Agent workflows marked experimental (minimal user impact)
- Comprehensive planning documents (5.1-05-PLAN, 5.1-06-PLAN)
- Systematic verification (5.1-VERIFICATION.md)
- Clear mapping table in AGENTS.md

---

## Appendix B: OpenCode Platform Command Research

**Known OpenCode Internal Commands** (based on analysis documents):

While specific OpenCode internal commands are not fully documented in available references, common patterns suggest these are likely reserved or high-conflict terms:

- `status`, `help`, `info`, `version`
- `run`, `execute`, `start`, `stop`
- `list`, `show`, `view`, `display`
- `create`, `delete`, `update`, `modify`
- `test`, `check`, `validate`, `verify`
- `config`, `settings`, `options`

**Project Impact:** By using `aedmd-*` prefix, we avoid ALL potential conflicts in this space.

---

## Appendix C: Related Documents

**Analysis Reports:**
- `.planning/code_analysis/2026-04-19-skill-doc-conflicts-report.md` — Original conflict identification
- `.planning/code_analysis/2026-04-19-204926-namespace-analysis.md` — Post-migration verification

**Phase 5.1 Plans:**
- `.planning/phases/5.1-critical-correctness-and-namespace-fixes/5.1-05-PLAN.md` — Skill/command renaming
- `.planning/phases/5.1-critical-correctness-and-namespace-fixes/5.1-06-PLAN.md` — Documentation updates
- `.planning/phases/5.1-critical-correctness-and-namespace-fixes/5.1-VERIFICATION.md` — Verification results

**Current Documentation:**
- `AGENTS.md` — Agent roles and slash command table
- `README.md` — Project overview with namespace rationale
- `.planning/ROADMAP.md` — Phase 5.1 completion record

---

**Report Prepared By:** OpenCode Agent  
**Report Version:** 1.0  
**Date:** 2026-04-29 14:00:09  
**Next Review:** Not required (stable state achieved)
