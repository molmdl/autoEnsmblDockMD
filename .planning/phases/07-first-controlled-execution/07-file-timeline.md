# Work/Test File Timeline - May 3, 2026

## Summary

| Category | Count | Date | Owner |
|----------|-------|------|-------|
| User files (inputs) | 306 | Mar 20 - Apr 6 | User |
| Phase execution files | 194 | May 3, 2026 | Phase 7 |

---

## User Files (Before May 3) - KEEP THESE

**Force Field Directory (289 files):**
```
work/test/amber19SB_OL21_OL3_lipid17.ff/
```
Created: Mar 20, 2026

**Ligand Files (16 files):**
```
work/test/dzp/dzp.gro
work/test/dzp/dzp.itp
work/test/dzp/dzp.mol2
work/test/dzp/dzp.pdb
work/test/dzp/dzp.pqr
work/test/dzp/dzp.top
work/test/dzp/dzp_raw.pdb

work/test/ibp/ibp.gro
work/test/ibp/ibp.itp
work/test/ibp/ibp.mol2
work/test/ibp/ibp.pdb
work/test/ibp/ibp.pqr
work/test/ibp/ibp.top
work/test/ibp/ibp_raw.pdb
```
Created: Apr 6, 2026

**Input Structures (3 files):**
```
work/test/rec.pdb     - Apr 6, 03:09
work/test/ref.pdb     - Apr 6, 03:09
work/test/2bxo.pdb    - Apr 6, 03:12 (also copied to work/test/rec/ on May 3)
```

---

## Phase Execution Files (May 3, 2026) - PHASE 7 GENERATED

### Time Breakdown

| Time | Stage | Files Created |
|------|-------|---------------|
| 09:39 | Workspace init | mdp/, config.ini.backup |
| 09:41 | Preflight | .handoffs/preflight_*.json |
| 16:44-16:48 | rec_prep (equil) | em.*, ion.*, pr_pos.*, pr_em.*, slurm-95280.out |
| 16:55 | rec_prod submit | pr_0-3.tpr, slurm/1_pr_rec.sbatch |
| 20:04-20:06 | rec_prod complete | pr_0-3.{xtc,log,edr,cpt,gro}, slurm-95281_*.out |
| 21:27-21:28 | Config fix | config_expanded.ini |
| 21:47-21:48 | rec_ana | apo_50ns_*.xtc, *.rmsd.xvg, *_rmsf.* |
| 21:51 | rec_cluster | clusters.xtc, rec0-27.gro, cluster.log, clust-*.xvg |
| 21:53 | rec_align | aligned/hsa0-9.gro, aligned/aln_rec0-9.pdb |
| 21:55 | dock_prep (partial) | dzp/run_gnina_dzp.sbatch, ibp/run_gnina_ibp.sbatch |

### Directories Created by Phase

```
work/test/.handoffs/           - 2 files
work/test/mdp/                 - 8 files (rec + com MDPs)
work/test/rec/                 - ~150 files (all MD outputs)
work/test/rec/aligned/         - 20 files (final ensemble)
work/test/rec/slurm/           - 2 files
work/test/dock/                - 20 files (receptor preps only, INCOMPLETE)
```

### Key Phase Outputs

**Valid Outputs (can keep):**
- work/test/rec/aligned/hsa0-9.gro - Final ensemble conformers
- work/test/rec/pr_0-3.xtc - Production trajectories
- work/test/rec/cluster.log - Clustering results

**Incomplete Outputs (may want to clean):**
- work/test/dock/ - Only receptor conversions, no actual docking
- work/test/rec/rec10-27.gro - Intermediate cluster representatives (not used)

---

## Cleanup Recommendation

If you want to reset and start fresh with replanned phase:

### Option 1: Archive and Clean
```bash
# Archive phase outputs
mv work/test work/test_phase7_deferred_20260503

# Reinitialize from input
cp -r work/input work/test
```

### Option 2: Clean Only Phase Files
```bash
# Remove phase-generated files, keep user inputs
rm -rf work/test/.handoffs
rm -rf work/test/mdp
rm -rf work/test/rec
rm -rf work/test/dock
rm -f work/test/config.ini
rm -f work/test/config.ini.backup
rm -f work/test/config_expanded.ini
```

### Option 3: Keep Everything
Just create new workspace for replanned phase:
```bash
# New workspace for fresh start
mkdir -p work/run_2026-05-XX
# Copy inputs from work/input
```

---

## Files by Category

### User Inputs (DO NOT DELETE)
- work/test/amber19SB_OL21_OL3_lipid17.ff/ (entire directory)
- work/test/dzp/ (all files)
- work/test/ibp/ (all files)
- work/test/rec.pdb
- work/test/ref.pdb
- work/test/2bxo.pdb (root level)

### Phase Outputs (CAN DELETE IF RESETTING)
- work/test/.handoffs/
- work/test/mdp/
- work/test/rec/ (entire directory including aligned/)
- work/test/dock/
- work/test/config.ini
- work/test/config.ini.backup
- work/test/config_expanded.ini
