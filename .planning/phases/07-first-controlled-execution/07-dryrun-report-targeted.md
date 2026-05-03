# Dryrun Report: Targeted Docking Mode

**Generated:** 2026-05-03T09:46:22+0800  
**Config:** work/test/config.ini  
**Mode:** targeted  
**Status:** READY

---

## Summary

| Category | Status | Details |
|----------|--------|---------|
| Preflight Validation | unknown | All checks passed |
| File Readiness | 5/6 files found | Input files and directories |
| Config Sections | 8/8 sections found | Required configuration sections |
| Tool Availability | ⚠ Tools check pending | N/A |


## File/Config Readiness

### Files

✓ Config file: work/test/config.ini
✓ Input file: rec.pdb
✓ Input file: ref.pdb
✓ Ligand directory: dzp/
✓ Ligand directory: ibp/

### Configuration Sections

✓ [general]
✓ [docking]
✓ [receptor]
✓ [complex]
✓ [slurm]
✓ [production]
✓ [mmpbsa]
✓ [analysis]


## Tool Availability

| Tool | Status |
|------|--------|
| gmx | ✓ Available |
| gnina | ✓ Available |
| gmx_MMPBSA | ✓ Available |

## Command Preview

The following commands would execute during pipeline run:

<details>
<summary>Click to expand command list (15 commands)</summary>

```bash
[2026-05-03T09:46:22+0800] [INFO] Running pipeline dry-run...
[DRY-RUN] /share/home/nglokwan/autoEnsmblDockMD/scripts/rec/0_prep.sh --config work/test/config.ini
[DRY-RUN] /share/home/nglokwan/autoEnsmblDockMD/scripts/rec/1_pr_rec.sh --config work/test/config.ini
[DRY-RUN] /share/home/nglokwan/autoEnsmblDockMD/scripts/rec/3_ana.sh --config work/test/config.ini
[DRY-RUN] /share/home/nglokwan/autoEnsmblDockMD/scripts/rec/4_cluster.sh --config work/test/config.ini
[DRY-RUN] /share/home/nglokwan/autoEnsmblDockMD/scripts/rec/5_align.py --config work/test/config.ini
[DRY-RUN] /share/home/nglokwan/autoEnsmblDockMD/scripts/dock/0_gro2mol2.sh --config work/test/config.ini
[DRY-RUN] /share/home/nglokwan/autoEnsmblDockMD/scripts/dock/2_gnina.sh --config work/test/config.ini
[DRY-RUN] /share/home/nglokwan/autoEnsmblDockMD/scripts/dock/3_dock_report.sh --config work/test/config.ini
[DRY-RUN] /share/home/nglokwan/autoEnsmblDockMD/scripts/dock/4_dock2com.sh --config work/test/config.ini
[DRY-RUN] /share/home/nglokwan/autoEnsmblDockMD/scripts/com/0_prep.sh --config work/test/config.ini
[DRY-RUN] /share/home/nglokwan/autoEnsmblDockMD/scripts/com/1_pr_prod.sh --config work/test/config.ini
[DRY-RUN] /share/home/nglokwan/autoEnsmblDockMD/scripts/com/2_run_mmpbsa.sh --config work/test/config.ini
[DRY-RUN] /share/home/nglokwan/autoEnsmblDockMD/scripts/com/3_ana.sh --config work/test/config.ini
[DRY-RUN] /share/home/nglokwan/autoEnsmblDockMD/scripts/com/4_cal_fp.sh --config work/test/config.ini
[DRY-RUN] /share/home/nglokwan/autoEnsmblDockMD/scripts/com/5_arc_sel.sh --config work/test/config.ini
```

</details>


## Workflow Flowchart

┌──────────────────────────────────────────────────┐
│ WORKFLOW FLOWCHART: Targeted Docking (Mode A) │
├──────────────────────────────────────────────────┤
│                                                  │
  │  Stage 1: Receptor Preparation
  │  Prepare receptor system and submit equilibration
  │     └── rec/0_prep.sh
  │              │
  │              ▼
  │  Submit receptor production MD trials
  │     └── rec/1_pr_rec.sh
  │              │
  │              ▼
  │  Run receptor trajectory analysis
  │     └── rec/3_ana.sh
  │              │
  │              ▼
  │  Cluster receptor ensemble conformations
  │     └── rec/4_cluster.sh
  │              │
  │              ▼
  │  Align receptor ensemble to reference complex
  │     └── rec/5_align.py
  │              │
  │              ▼
  │  Stage 2: Docking
  │  Convert ligand inputs into docking formats
  │     └── dock/0_gro2mol2.sh
  │              │
  │              ▼
  │  Run gnina docking jobs
  │     └── dock/2_gnina.sh
  │              │
  │              ▼
  │  Generate ranked docking report
  │     └── dock/3_dock_report.sh
  │              │
  │              ▼
  │  Stage 3: Complex Setup
  │  Prepare complex system for MD
  │     └── com/0_prep.sh
  │              │
  │              ▼
  │  Stage 4: Complex MD Production
  │  Run complex production MD
  │     └── com/1_pr_prod.sh
  │              │
  │              ▼
  │  Stage 5: MM/PBSA
  │  Run MM/PBSA trajectory prep and submission
  │     └── com/2_run_mmpbsa.sh
  │              │
  │              ▼
  │  Stage 6: Complex Analysis
  │  Run complex trajectory analysis
  │     └── com/3_ana.sh
  │              │
  │              ▼
  │  Run fingerprint analysis (optional utility)
  │     └── com/4_cal_fp.sh
  │              │
  │              ▼
  │  Archive/rerun selection workflow (optional utility)
  │     └── com/5_arc_sel.sh
  │
  │  Targeted Mode Notes:
  │     • Uses reference_ligand for pocket definition
  │     • Autobox centered on reference ligand
  │     • Requires [docking] reference_ligand in config
│                                                  │
└──────────────────────────────────────────────────┘

---

## Manual Approval Gate


✓ **READY FOR EXECUTION** - All checks passed.

**Next Steps:**
1. Review this dryrun report
2. Verify the command preview shows expected workflow
3. Type "approved" to proceed with execution

**Safe to proceed** after your review.

---

*Report generated by scripts/phase7/07-dryrun-report.sh*  
*autoEnsmblDockMD Pipeline Validation*
