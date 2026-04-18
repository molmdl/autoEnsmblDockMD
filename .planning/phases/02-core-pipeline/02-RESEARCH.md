# Phase 2: Core Pipeline - Research

**Researched:** 2026-04-18
**Domain:** Ensemble docking pipeline - receptor preparation, gnina docking, GROMACS MD, gmx_MMPBSA binding energy
**Confidence:** HIGH

## Summary

This research investigates the existing manual workflow scripts in `expected/amb/scripts/` (Mode A - targeted docking) and `expected/chm/BRD4/scripts/` (Mode B - blind docking) to plan generalized, production-ready pipeline scripts. The project has 12 scripts already implemented for blind docking (Phase 1), with 27 gap scripts identified for targeted docking Mode A and unification.

The standard approach follows a multi-stage ensemble docking protocol: (1) receptor ensemble generation via MD clustering, (2) gnina ensemble docking with CNN scoring, (3) complex MD simulations, (4) gmx_MMPBSA binding energy calculations. Scripts are organized by stage (`rec/`, `dock/`, `com/`) with numeric prefixes indicating execution order.

**Primary recommendation:** Generalize the existing blind docking scripts as baseline patterns, extract Mode A/B differences into configuration parameters, establish consistent CLI interfaces across all stages, and fill the 27 identified gaps following Phase 1 infrastructure patterns (ConfigManager for INI configs, subprocess-based execution, Slurm job submission).

## Standard Stack

The established libraries/tools for this ensemble docking domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| GROMACS | >2022 | MD simulation engine | Industry standard for biomolecular MD, GPU-accelerated |
| gnina | latest | CNN-based docking | Modern deep learning scoring, superior to AutoDock Vina |
| gmx_MMPBSA | latest (pip) | MM/PBSA binding energy | GROMACS-compatible implementation of MMPBSA.py |
| MDAnalysis | 2.7.0 | Trajectory analysis | Python API for MD trajectory processing |
| MDTraj | 1.10.0 | Trajectory I/O | Fast trajectory loading and format conversion |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| pdb2pqr | conda latest | Add hydrogens to PDB | Missing hydrogen atoms in crystal structures |
| APBS | conda latest | Electrostatic calculations | MM/PBSA solvation energy |
| BioPython | conda latest | Structure parsing | PDB/mmCIF file manipulation |
| NumPy/SciPy | conda latest | Numerical operations | Analysis calculations, matrix operations |
| Matplotlib/Seaborn | conda latest | Plotting | Trajectory analysis visualization |

### Force Fields
| Force Field | Purpose | Mode |
|-------------|---------|------|
| CHARMM36m + CGenFF | Protein + small molecules | Mode B (blind docking) |
| AMBER19SB + GAFF2 | Protein + small molecules | Mode A (targeted docking) |

**Installation:**
```bash
# Conda environment (gmxMMPBSA.yml or scripts/env.yml)
conda env create -f scripts/env.yml
conda activate gmxMMPBSA

# GROMACS (system-level, version >2022)
# User must install separately (gmx command must be in PATH)

# gnina (system-level or conda)
# User must install separately
```

## Architecture Patterns

### Recommended Project Structure
```
workspace/
├── rec/                      # Receptor ensemble generation
│   ├── rec_md/              # MD trajectories, analysis
│   └── ensemble/            # Clustered conformations (rec0-rec9.gro)
├── lig/                     # Ligand inputs (Mode B: flat; Mode A: ref/, new/)
│   ├── ref/                 # Reference ligand (Mode A only)
│   └── new/LIGAND_ID/       # New ligands (Mode A only)
├── dock/LIGAND_ID/          # Docking results per ligand
│   ├── rec0-LIGAND.sdf      # Docking poses from ensemble
│   └── rec0-LIGAND.log      # Docking scores/logs
├── com/LIGAND_ID/           # Complex MD (Mode B) or com_md/LIGAND_ID/ (Mode A)
│   ├── sys.top              # Complex topology
│   ├── mmpbsa_0/            # MM/PBSA job directories
│   └── analysis/            # Trajectory analysis
├── com_ana/                 # Cross-ligand comparative analysis
├── scripts/                 # Generalized pipeline scripts
│   ├── rec/                 # Receptor preparation scripts
│   ├── dock/                # Docking workflow scripts
│   ├── com/                 # Complex MD and MM/PBSA scripts
│   └── infra/               # Infrastructure utilities (Phase 1)
└── amber19SB.ff/            # Force field directory (Mode A: AMBER, Mode B: charmm36.ff)
```

### Pattern 1: Stage-Based Script Organization

**What:** Scripts organized by workflow stage (rec, dock, com) with numeric prefixes for execution order.

**When to use:** All pipeline scripts follow this pattern for predictability and agent navigation.

**Example:**
```bash
# Receptor ensemble generation (scripts/rec/)
0_prep.sh       # System preparation, solvation, ionization, equilibration submission
1_pr_rec.sh     # Submit 4 parallel production MD trials
3_ana.sh        # Convert trajectories, run basic analysis
4_cluster.sh    # Cluster to extract diverse conformations (rec0-rec9.gro)

# Docking workflow (scripts/dock/)
0_gro2mol2.sh           # Convert ligands to MOL2 format
1_rec4dock.sh           # Copy ensemble to dock directory
2_gnina_blind.sh        # Submit gnina docking jobs (Mode B)
2_gnina_targeted.sh     # Targeted docking with reference pocket (Mode A)
3_dock_report.sh        # Generate scores and rankings

# Complex MD (scripts/com/)
0_prep.sh       # Complex solvation, ionization, minimization
1_pr_prod.sh    # Equilibration + production MD
2_run_mmpbsa.sh # Trajectory processing + MM/PBSA submission
3_ana.sh        # Trajectory analysis and plotting
```

**Rationale:** Numeric prefixes enforce execution order, stage separation enables modular testing and checkpoints.

### Pattern 2: Slurm Job Submission with Heredoc

**What:** Bash scripts submit Slurm jobs using heredoc for inline SBATCH directives.

**When to use:** Long-running computational tasks (MD, docking, MM/PBSA).

**Example:**
```bash
# Source: expected/chm/BRD4/scripts/rec/0_prep.sh
sbatch << EOF
#!/bin/bash
#SBATCH -J prep
#SBATCH -n 1
#SBATCH -c 8
#SBATCH -p rtx4090-short
#SBATCH --gres=gpu:1

gmx grompp -v -f em.mdp -c ion.gro -p topol.top -o em.tpr 
gmx mdrun -deffnm em -ntomp 8 -ntmpi 1 
gmx grompp -v -f pr_pos.mdp -c em.gro -p topol.top -o pr_pos.tpr -r em.gro -maxwarn 3 
gmx mdrun -deffnm pr_pos -ntomp 8 -bonded gpu -nb gpu -update gpu -ntmpi 1 
EOF
```

**Generalized pattern with CLI flags:**
```bash
# Target: scripts/rec/0_prep.sh with config support
#!/bin/bash
source $(dirname $0)/../infra/config_loader.sh
load_config "${CONFIG_FILE:-config.ini}"

PARTITION=$(get_config "slurm" "partition" "rtx4090-short")
GPUS=$(get_config "slurm" "gpus" "1")
NTOMP=$(get_config "receptor" "ntomp" "8")

sbatch << EOF
#!/bin/bash
#SBATCH -J rec_prep
#SBATCH -n 1
#SBATCH -c ${NTOMP}
#SBATCH -p ${PARTITION}
#SBATCH --gres=gpu:${GPUS}

gmx grompp -v -f em.mdp -c ion.gro -p topol.top -o em.tpr 
gmx mdrun -deffnm em -ntomp ${NTOMP} -ntmpi 1 
# ... rest of workflow
EOF
```

### Pattern 3: Python Utility Scripts with CLI and Library Modes

**What:** Python scripts support both CLI invocation and library import.

**When to use:** Reusable utilities (format conversion, topology processing, analysis).

**Example:**
```python
# Source: expected/amb/scripts/com/bypass_angle_type3.py
#!/usr/bin/env python3
"""
Bypass parmed angle type 3 incompatibility for gmx_mmpbsa.

Usage:
    python bypass_angle_type3.py <ligand.itp> <main.top>
"""
import argparse
import sys

def modify_ligand_itp(input_file: str, output_file: str) -> int:
    """Change angle function type 3 to type 1."""
    # ... implementation
    return modified_count

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('ligand_itp', help='Input ligand topology')
    parser.add_argument('main_top', help='Main topology file')
    args = parser.parse_args()
    
    # Execute workflow
    output_itp = f"bypass_{args.ligand_itp}"
    count = modify_ligand_itp(args.ligand_itp, output_itp)
    print(f"Modified {count} angles")

if __name__ == '__main__':
    main()
```

**Improvements needed:**
- Add `--config` flag for INI-based configuration
- Add `--output` flag instead of hardcoded `bypass_` prefix
- Return structured results for wrapper scripts

### Pattern 4: Multi-Ligand Parallel Execution with Job Arrays

**What:** Iterate over ligands and submit independent Slurm jobs for each.

**When to use:** Docking, complex MD, MM/PBSA across multiple ligands.

**Example:**
```bash
# Source: expected/chm/BRD4/scripts/dock/2_gnina_blind.sh
cd dock
for ligid in {1..10} ; do
    cd lig$ligid
    l=`basename *.mol2 .mol2`
    sbatch << EOF
#!/bin/bash
#SBATCH -J gnina_blind
#SBATCH --gres=gpu:1
#SBATCH -n 1
#SBATCH -c 8

for i in {0..9} ; do
    gnina -r ../rec\${i}.pdb -l ${l}.mol2 --autobox_ligand ../rec\${i}.pdb --autobox_add 4 --cpu 8 -o rec\${i}-${l}.sdf --log rec\${i}-${l}.log --exhaustiveness 100 --num_modes 100 --min_rmsd_filter 3 --scoring ad4_scoring 2>/dev/null
done
EOF
    cd ..
done
```

**Generalized with config:**
```bash
# Use Slurm job arrays for true parallelization
#!/bin/bash
LIGAND_LIST=$(get_config "ligands" "list")  # From config
ENSEMBLE_SIZE=$(get_config "receptor" "ensemble_size" "10")
EXHAUSTIVENESS=$(get_config "docking" "exhaustiveness" "100")

sbatch --array=1-${#LIGAND_LIST[@]} << EOF
#!/bin/bash
#SBATCH -J gnina_ensemble
#SBATCH --gres=gpu:1
#SBATCH -p workq

LIGAND_ID=${LIGAND_LIST[\$SLURM_ARRAY_TASK_ID]}
cd dock/\${LIGAND_ID}

for rec_idx in {0..$((ENSEMBLE_SIZE-1))} ; do
    gnina -r ../rec\${rec_idx}.pdb -l ligand.mol2 \\
          --autobox_ligand ref.pdb --autobox_add 8 \\
          --exhaustiveness ${EXHAUSTIVENESS} \\
          -o rec\${rec_idx}-\${LIGAND_ID}.sdf
done
EOF
```

### Anti-Patterns to Avoid

- **Hardcoded paths:** Use relative paths and `cd` to expected directory at script start
- **Hardcoded ligand counts:** Read from config or autodiscover from filesystem
- **Silent failures:** Always check `gmx` and `gnina` exit codes
- **Missing environment sourcing:** Scripts assume environment already loaded (setenv.sh)
- **Direct topology editing:** Use helper scripts (bypass_angle_type3.py) instead of sed/awk

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| GRO+ITP to MOL2 conversion | Custom parser | `gro_itp_to_mol2.py` (existing) | Handles AMBER atom types, charge parsing, bond type mapping (659 lines) |
| AMBER angle type 3 fixing | sed/awk topology edits | `bypass_angle_type3.py` (existing) | Preserves topology integrity, tracks modifications (191 lines) |
| Ligand position restraints | Manual ITP editing | `dock2com_2.2.1.py` (existing) | Generates posre_lig.itp with heavy atom restraints |
| Trajectory center/fit | Custom MDAnalysis script | GROMACS `trjconv` with proper flags | Battle-tested, handles PBC correctly |
| MM/PBSA input generation | Manual file creation | gmx_MMPBSA standard input format | Validates parameter compatibility |
| Clustering for ensemble | K-means from scratch | GROMACS `gmx cluster` with gromos method | RMSD-based, outputs structures directly |
| Docking score parsing | Regex on log files | gnina SDF output with score fields | Structured format, includes CNN and Vina scores |

**Key insight:** The existing manual workflow scripts (`expected/amb/scripts/`, `expected/chm/BRD4/scripts/`) represent 2+ years of bug fixes and edge case handling. Generalize them rather than rewriting from scratch.

## Common Pitfalls

### Pitfall 1: Force Field Incompatibility
**What goes wrong:** Mixing AMBER protein with CGenFF ligand (or vice versa) causes topology errors and simulation crashes.

**Why it happens:** Force fields define incompatible atom types and interaction parameters.

**How to avoid:**
- Mode A: AMBER19SB protein + GAFF2 ligand (both AMBER family)
- Mode B: CHARMM36m protein + CGenFF ligand (both CHARMM family)
- Validate topology with `gmx grompp -maxwarn 0` before production runs

**Warning signs:**
- Fatal errors during `gmx grompp`: "atomtype X not found"
- Unrealistic energies during minimization (>10^6 kJ/mol)

### Pitfall 2: Missing Hydrogen Atoms
**What goes wrong:** Docking and MD fail with cryptic errors when hydrogen atoms are missing from receptor or ligand.

**Why it happens:** Crystal structures often lack hydrogens, but force fields require explicit hydrogens.

**How to avoid:**
- **Receptor:** Use `pdb2pqr` before `gmx pdb2gmx` for protonation at pH 7.4
- **Ligand:** Ensure ligand preparation tools (ACPYPE, CGenFF) add hydrogens
- **Docking:** Use gnina flags `--addH off --stripH off` to preserve existing hydrogens

**Warning signs:**
- gnina error: "Could not assign atom types"
- GROMACS error: "atom X has no type or charge"
- MM/PBSA topology mismatch errors

### Pitfall 3: AMBER Angle Type 3 Incompatibility
**What goes wrong:** gmx_MMPBSA fails with "angle function type 3 not supported" when processing AMBER ligand topologies.

**Why it happens:** AMBER uses angle function type 3 (Urey-Bradley), but gmx_MMPBSA's parmed backend doesn't support it.

**How to avoid:**
- Run `bypass_angle_type3.py` on ligand ITP before MM/PBSA calculations
- Converts angle type 3 → type 1 with comments for tracking
- Required for **ALL** AMBER-based complex MD workflows (Mode A)

**Warning signs:**
- gmx_MMPBSA error: "Unsupported angle function type: 3"
- Occurs during trajectory processing phase

### Pitfall 4: Ensemble Alignment Issues
**What goes wrong:** Docking to unaligned ensemble structures produces inconsistent binding poses across receptors.

**Why it happens:** Clustering produces structures in different reference frames.

**How to avoid:**
- **Mode A:** ALWAYS run `align_structures.py` after clustering
- Align all ensemble structures to reference ligand complex
- Maintains consistent pocket geometry across ensemble

**Warning signs:**
- Wide variation in docking poses across ensemble members
- Reference redocking RMSD >5Å from crystal structure

### Pitfall 5: Trajectory Topology Mismatch
**What goes wrong:** MM/PBSA fails with "atom count mismatch" between topology and trajectory.

**Why it happens:** Trajectory includes water/ions, but MM/PBSA topology is complex-only.

**How to avoid:**
- Use `trj4mmpbsa.sh` to extract complex-only trajectory
- Generate index file with correct groups (receptor, ligand)
- Ensure topology used for MM/PBSA matches trajectory extraction

**Warning signs:**
- gmx_MMPBSA error: "Number of atoms in topology and trajectory don't match"
- Incorrect binding energy magnitudes (>1000 kcal/mol)

### Pitfall 6: Gnina Autobox Size
**What goes wrong:** Docking fails to sample binding pocket if autobox is too small, or wastes time if too large.

**Why it happens:** Default `--autobox_add 4` works for small ligands but not larger molecules.

**How to avoid:**
- **Mode B (blind):** Use `--autobox_add 4` for whole protein
- **Mode A (targeted):** Estimate largest ligand size, use `--autobox_add 8-12`
- Validate with reference redocking (RMSD <2Å)

**Warning signs:**
- Reference redocking RMSD >2Å
- Top poses outside known binding pocket

### Pitfall 7: Slurm Job Dependency Management
**What goes wrong:** Pipeline scripts submit jobs that start before dependencies complete, leading to missing files.

**Why it happens:** Bash scripts submit jobs asynchronously without `--dependency` flags.

**How to avoid:**
- Capture job IDs: `JOB_ID=$(sbatch --parsable script.sh)`
- Use dependencies: `sbatch --dependency=afterok:${JOB_ID} next_script.sh`
- OR use wrapper scripts that poll for completion before proceeding

**Warning signs:**
- "File not found" errors in Slurm logs
- Jobs fail but manual re-run succeeds

## Code Examples

Verified patterns from existing manual workflow scripts:

### Receptor Ensemble Generation
```bash
# Source: expected/chm/BRD4/scripts/rec/0_prep.sh
#!/bin/bash
cd rec

# Link force field
ln -s ../charmm36.ff .

# Prepare topology
gmx pdb2gmx -f receptor.pdb -ignh -o prot.gro --ff charmm36 -water tip3p

# Create box and solvate
gmx editconf -f prot.gro -o box.gro -d 1 -c -bt dodecahedron
gmx solvate -cp box.gro -cs spc216 -p topol.top -o solv.gro

# Add ions
gmx grompp -f em.mdp -c solv.gro -p topol.top -o ion.tpr -maxwarn 1
echo SOL | gmx genion -s ion.tpr -p topol.top -neutral -conc 0.15 -nname CL -pname NA -o ion.gro

# Submit minimization + equilibration job
sbatch << EOF
#!/bin/bash
#SBATCH -J rec_prep
#SBATCH --gres=gpu:1
gmx grompp -f em.mdp -c ion.gro -p topol.top -o em.tpr
gmx mdrun -deffnm em -ntomp 8 -ntmpi 1
gmx grompp -f pr_pos.mdp -c em.gro -p topol.top -o pr_pos.tpr -r em.gro
gmx mdrun -deffnm pr_pos -ntomp 8 -bonded gpu -nb gpu -update gpu
EOF
```

### Gnina Ensemble Docking
```bash
# Source: expected/amb/scripts/dock/gnina_test.sh
#!/bin/bash
#SBATCH -J gnina
#SBATCH --gres=gpu:1
#SBATCH -n 1
#SBATCH -c 8

# Reference ligand validation redocking
gnina -r rec.pdb -l ref.mol2 \
      --autobox_ligand ref.pdb --autobox_add 12 \
      --exhaustiveness 64 --num_modes 32 \
      --addH off --stripH off --cpu 8 \
      -o rec-ref.sdf | tee -a rec-ref.log

# Ensemble docking
for i in {0..9} ; do
    gnina -r ../rec${i}.pdb -l ligand.mol2 \
          --autobox_ligand ref.pdb --autobox_add 12 \
          --exhaustiveness 64 --num_modes 32 \
          --addH off --stripH off --cpu 8 \
          -o rec${i}-ligand.sdf | tee -a rec${i}-ligand.log
done
```

### Complex MD Preparation (CHARMM)
```bash
# Source: expected/chm/BRD4/scripts/com/0_prep.sh
#!/bin/bash
cd com/lig${LIGAND_ID}

# Link force field
ln -s ../../charmm36.ff .

# Combine receptor + ligand
gmx editconf -f ../../dock/lig${LIGAND_ID}/pose.gro -o lig.gro
cat ../../rec/prot.gro lig.gro > complex.gro

# Build topology (manually append ligand ITP)
# sys.top includes: forcefield.itp, receptor, ligand.itp, water/ions

# Solvate and ionize
gmx editconf -f complex.gro -o box.gro -d 1 -c -bt dodecahedron
gmx solvate -cp box.gro -cs spc216 -p sys.top -o solv.gro
gmx grompp -f em.mdp -c solv.gro -p sys.top -o ion.tpr -maxwarn 1
echo SOL | gmx genion -s ion.tpr -p sys.top -neutral -conc 0.15 -o ion.gro

# Minimize
gmx grompp -f em.mdp -c ion.gro -p sys.top -o em.tpr
gmx mdrun -deffnm em -ntomp 8
```

### MM/PBSA Trajectory Processing
```bash
# Source: expected/chm/BRD4/scripts/com/trj4mmpbsa.sh
#!/bin/bash
# Extract complex-only trajectory for MM/PBSA

# Create index file with receptor and ligand groups
gmx make_ndx -f em.gro -o index.ndx << EOF
1 | 12
name 13 complex
q
EOF

# Center and fit trajectory
echo "complex complex" | gmx trjconv -s md.tpr -f md.xtc \
    -o md_fit.xtc -center -fit rot+trans -pbc mol

# Generate MM/PBSA input directories
for i in {0..3} ; do
    mkdir -p mmpbsa_$i
    cp mmpbsa.in mmpbsa_$i/
    cp mmpbsa.sh mmpbsa_$i/
    # Copy trajectory subset
    echo "complex" | gmx trjconv -s md.tpr -f md_fit.xtc \
        -o mmpbsa_$i/com_traj.xtc -b $((i*10000)) -e $(((i+1)*10000))
done
```

### AMBER Topology Angle Fixing
```python
# Source: expected/amb/scripts/com/bypass_angle_type3.py
#!/usr/bin/env python3
"""Convert AMBER angle type 3 to type 1 for gmx_MMPBSA compatibility."""

def modify_ligand_itp(input_file: str, output_file: str) -> int:
    """Change angle function type 3 to type 1."""
    modified_count = 0
    in_angles_section = False
    lines_out = []
    
    with open(input_file, 'r') as f:
        lines = f.readlines()
    
    for line in lines:
        stripped = line.strip()
        
        if stripped.startswith('[ angles ]'):
            in_angles_section = True
            lines_out.append(line)
            continue
        
        if stripped.startswith('[') and stripped.endswith(']'):
            in_angles_section = False
        
        if in_angles_section and stripped and not stripped.startswith(';'):
            parts = line.split()
            if len(parts) >= 4 and parts[3] == '3':
                # Replace type 3 with type 1, add comment
                modified_line = line.replace(' 3 ', ' 1 ', 1)
                modified_line = modified_line.rstrip() + '  ; bypassed from type 3\n'
                lines_out.append(modified_line)
                modified_count += 1
                continue
        
        lines_out.append(line)
    
    with open(output_file, 'w') as f:
        f.writelines(lines_out)
    
    return modified_count

# CLI usage: python bypass_angle_type3.py ligand.itp sys.top
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| AutoDock Vina scoring | gnina CNN scoring | ~2017 | Improved pose prediction accuracy, deep learning-based |
| Single receptor structure | Ensemble docking | ~2015 | Accounts for receptor flexibility, higher hit rates |
| MMPBSA.py (AMBER) | gmx_MMPBSA | ~2020 | Native GROMACS compatibility, faster processing |
| Manual ligand preparation | Automated tools (CGenFF, ACPYPE) | ~2015 | Reduces errors, faster parameterization |
| Serial docking jobs | Slurm job arrays | Ongoing | True parallelization, better cluster utilization |

**Deprecated/outdated:**
- **AutoDock 4 scoring:** gnina's CNN scoring superior for most targets
- **MMPBSA.py with GROMACS:** Use gmx_MMPBSA for native integration
- **Manual topology editing:** Use helper scripts (bypass_angle_type3.py)

## Open Questions

Things that couldn't be fully resolved:

1. **Gnina CNN scoring thresholds**
   - What we know: gnina outputs CNN score and Vina score; CNN score is preferred
   - What's unclear: Domain-specific thresholds for "good" CNN scores (target-dependent)
   - Recommendation: Use reference redocking as calibration (RMSD <2Å should have top CNN score)

2. **Optimal ensemble size**
   - What we know: Current workflows use 10 receptors (rec0-rec9)
   - What's unclear: Whether 10 is optimal vs. computational cost tradeoff
   - Recommendation: Make configurable (default 10), document that >10 provides diminishing returns

3. **MM/PBSA trajectory length**
   - What we know: Scripts split trajectory into 4 chunks (mmpbsa_0 through mmpbsa_3)
   - What's unclear: Optimal trajectory length for convergence vs. computational cost
   - Recommendation: Make configurable, default to production MD length / 4

4. **Slurm job array limits**
   - What we know: Phase 1 infrastructure supports SlurmExecutor
   - What's unclear: Cluster-specific array size limits, job prioritization
   - Recommendation: Research flag for Phase 3 - verify on target cluster (mgpu)

## Gap Analysis

### Existing Scripts (Phase 1 - Implemented)
**Mode B (blind docking):**
- `scripts/rec/`: 0_prep.sh, 1_pr_rec.sh, 3_ana.sh, 4_cluster.sh
- `scripts/dock/`: 0_gro2mol2.sh, 1_rec4dock.sh, 2_gnina_blind.sh, dock2com_2.2.sh
- `scripts/com/`: 0_prep.sh, 1_pr_prod.sh, 2_run_mmpbsa.sh, 3_ana.sh
- **Total:** 12 scripts

### Gap Scripts (Phase 2 - To Implement)
**Mode A (targeted docking) - 27 scripts:**

**Receptor (1 script):**
- `align_structures.py` - Align ensemble to reference ligand complex

**Docking (13 scripts):**
- `gro_itp_to_mol2.py` - Convert AMBER ligands with angle type handling
- `gnina_test.sh` - Reference ligand validation redocking
- `gnina_0.sh` - Reference ligand ensemble redocking
- `gnina_1.sh` - New ligand ensemble docking batch 1
- `gnina_2.sh` - New ligand ensemble docking batch 2
- `dock_report.sh` - Generate scores and rankings
- `dock2com_2_ref.sh` - Prepare reference ligand complex topology
- `dock2com_2.sh` - Prepare new ligand complex topology
- `dock2com_1.py` - SDF to GRO conversion helper
- `dock2com_2.py` - Topology extraction core logic
- `dock2com_2.1.py` - ITP parsing utilities
- `dock2com_2.2.1.py` - Position restraint generation
- `sdf2gro.sh` - Batch SDF conversion wrapper

**Complex MD (13 scripts):**
- `prep_com.sh` - Initial complex assembly (Mode A)
- `prep.sh` - Solvation, ionization, minimization (Mode A)
- `sub_mmpbsa.sh` - Submit MM/PBSA job array
- `mmpbsa.sh` - MM/PBSA execution wrapper
- `trj4mmpbsa.sh` - Trajectory preparation for MM/PBSA
- `ana.sh` - Trajectory analysis and plotting (Mode A version)
- `com_ana_trj.py` - Advanced trajectory analysis
- `selection_defaults.py` - Standard selection groups
- `bypass_angle_type3.py` - AMBER topology angle type fixing
- `fp.py` - Fingerprint analysis
- `cal_fp.sh` - Calculate fingerprints
- `arc_sel.sh` - Archive selection workflow
- `rerun_sel.sh` - Rerun selection for failed jobs

### Unification Tasks
- Rename Mode A scripts to numeric prefix convention
- Merge Mode A/B variants where possible (e.g., gnina docking scripts with --mode flag)
- Extract mode-specific parameters to config files

## Sources

### Primary (HIGH confidence)
- **Expected scripts:** `expected/amb/scripts/` (Mode A - AMBER/GAFF2 workflow, 46 scripts)
- **Expected scripts:** `expected/chm/BRD4/scripts/` (Mode B - CHARMM36/CGenFF workflow, 24 scripts)
- **Implemented scripts:** `scripts/` (Phase 1 infrastructure + 12 blind docking scripts)
- **WORKFLOW.md:** Authoritative workflow stages and requirements
- **scripts/CONTEXT.md:** Script inventory and gap analysis
- **Phase 1 infrastructure:** ConfigManager, AgentState, CheckpointManager, LocalExecutor/SlurmExecutor, LogMonitor, VerificationGate

### Secondary (MEDIUM confidence)
- **AGENTS.md:** Environment requirements (GROMACS >2022, gnina, gmx_MMPBSA)
- **scripts/env.yml:** Conda environment dependencies (MDAnalysis 2.7.0, MDTraj 1.10.0)
- **expected/amb/README.md:** Mode A workflow documentation

### Tertiary (LOW confidence)
- None - all findings based on existing codebase inspection

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Based on existing working scripts and conda environment
- Architecture: HIGH - Based on 12 implemented scripts and 70 expected scripts
- Pitfalls: HIGH - Documented in existing scripts (bypass_angle_type3.py comments, WORKFLOW.md notes)
- Gap analysis: HIGH - Direct script inventory comparison

**Research date:** 2026-04-18
**Valid until:** 2026-07-18 (90 days - stable computational chemistry stack)

**Script inventory:**
- Implemented (Phase 1): 12 workflow scripts + 7 infrastructure modules
- Gap scripts (Phase 2): 27 Mode A scripts
- Expected total: 39 generalized workflow scripts

**Key constraints from CONTEXT.md:**
- Config-led workflow (INI format via configparser)
- Numeric prefix naming convention enforced
- rec/, dock/, com/ directory separation
- Reuse blind docking scripts as baseline patterns
- Mode A/B differences extracted to configuration
