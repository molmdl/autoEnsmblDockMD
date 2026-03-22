# Domain Pitfalls

**Domain:** Automated Molecular Docking and MD Simulation Workflows  
**Project:** autoEnsmblDockMD  
**Researched:** 2026-03-23  
**Confidence:** MEDIUM-HIGH

## Executive Summary

This document catalogs critical, moderate, and minor pitfalls encountered in automated ensemble docking and MD simulation workflows using GROMACS, gnina, and gmx_MMPBSA. The findings are synthesized from domain knowledge of computational chemistry software, common error patterns in HPC environments, and known software limitations.

---

## Critical Pitfalls

Mistakes that cause complete workflow failures, corrupted outputs, or scientifically invalid results requiring full restarts.

### Pitfall 1: Force Field Incompatibility Between Protein and Ligand

**What Goes Wrong:** Using AMBER force fields for the protein while providing ligand parameters derived from a different force field (e.g., CGenFF, OPLS) causes parameter conflicts. Nonbonded interactions fail, simulations crash, or energetically nonsensical results emerge.

**Why It Happens:** Users often prepare proteins with AMBER99SB-ILDN, OL21 for lipids, but obtain ligand parameters from external servers (e.g., CGenFF) optimized for CHARMM or use inconsistent atom type definitions. The pipeline lacks validation that ligand force field types match the protein FF.

**Consequences:**
- GROMACS crashes with "Atom type XX not found" errors
- Simulations produce physically impossible energies
- MMPBSA binding free energy calculations fail or give garbage values

**Prevention:**
- Always use consistent force fields: either AMBER all the way (protein + ligand via antechamber/Acpype) or CHARMM all the way
- Validate ligand .itp files before running simulations — check that atom types in `[ atomtypes ]` match the protein FF
- Add explicit FF validation step in the pipeline before `gmx pdb2gmx` and before `gmx grompp`

**Detection:**
- GROMACS error logs mentioning missing atom types
- Warnings during `gmx grompp` about unspecified VDW parameters
- Check for FF name consistency in all input files

**Phase Mapping:** This must be addressed in **Phase 1: Receptor & Ligand Preparation** — validation of FF compatibility must occur before any simulation stage.

---

### Pitfall 2: Missing Hydrogen Atoms in Receptor/Ligand Structures

**What Goes Wrong:** Docking and MD simulations require properly protonated structures. Missing hydrogens lead to incorrect partial charges, failed charge assignment in MMPBSA, or docking failures.

**Why It Happens:** PDB files from RCSB may lack hydrogens (which are often omitted in crystal structures). Ligand SDF/PDB files may also lack explicit hydrogens. The pipeline does not verify protonation completeness before proceeding.

**Consequences:**
- gnina docking fails or produces invalid poses
- `gmx pdb2gmx` fails for receptor
- MMPBSA calculations crash with "Cannot determine atom charges"
- "Garbage in, garbage out" — scientifically invalid binding energies

**Prevention:**
- Add mandatory hydrogen addition step using OpenBabel or MolAdd (via RDKit) before any docking
- Validate hydrogen presence in pipeline: check for H atom count in PDB/SDF
- For receptor: ensure `gmx pdb2gmx` succeeds before proceeding
- For ligand: verify all expected hydrogens are present after protonation

**Detection:**
- Check output of `obabel -i pdb -o sdf --addhydrogens` for ligand
- Receptor: verify `gmx pdb2gmx` completes without hydrogen-related errors
- MMPBSA stage: check that AMBER topologies are generated successfully

**Phase Mapping:** **Phase 1: Receptor & Ligand Preparation** — hydrogen validation must be explicit in the pre-docking checks.

---

### Pitfall 3: Context Window Overflow in Long Multi-Stage Workflows

**What Goes Wrong:** Agentic workflows that process many ligands or run many simulation stages accumulate output in context. Eventually the context window overflows, the agent loses state, and cannot make informed decisions.

**Why It Happens:** Each docking run produces SDF output, logs, and summary statistics. Each MD stage produces trajectory files, energy logs, and frame outputs. Without checkpointing, the agent accumulates all this in working memory.

**Consequences:**
- Agent produces nonsensical commands after context overflow
- Pipeline continues without proper state awareness
- Agent makes wrong decisions (e.g., proceeding with failed jobs, skipping validation)

**Prevention:**
- Implement checkpoint-based workflow: at each stage boundary, write state to disk, clear agent context, resume from checkpoint
- Use explicit file-based state tracking (JSON/CSV) rather than in-memory state
- After each major stage (docking → MD prep → MD → MMPBSA), force human verification checkpoint
- Design workflow to be resumable from any stage using stored outputs

**Detection:**
- Agent begins repeating commands or producing inconsistent outputs
- Error messages about token limits
- Pipeline progress logs show gaps or inconsistencies

**Phase Mapping:** **All Phases** — checkpoint design should be part of the core workflow architecture from the start.

---

### Pitfall 4: Ignoring Checkpoint Files and Simulation Stability Before Proceeding

**What Goes Wrong:** The workflow proceeds from docking → MD preparation → production MD without verifying simulation stability. Unstable simulations produce meaningless MMPBSA results.

**Why It Happens:** Short or unstable MD simulations (due to bad contacts, poor energy minimization, inadequate equilibration) still produce trajectory files. The pipeline treats any trajectory as valid and proceeds to MMPBSA.

**Consequences:**
- Binding free energies from unstable trajectories are scientifically invalid
- RMSD/RMSF analysis shows trajectories blew up
- MMPBSA sees frames where ligand dissociated or protein denatured

**Prevention:**
- Add mandatory equilibration stability check: verify RMSD < 3Å after 1-2ns production
- Check for "blow up" in GROMACS logs — examine `.log` files for LINCS/RATTLE warnings
- Require minimum production simulation time (e.g., 10ns) before MMPBSA
- Add trajectory quality check script before MMPBSA stage

**Detection:**
- Check `gmx mdrun` log for "LINCS warning" or "blow up"
- RMSD plot shows sudden spikes > 5Å
- Ligand RMSD > 5Å indicates ligand dissociated from binding site

**Phase Mapping:** **Phase 4: Complex MD Simulation** — stability validation is critical before **Phase 5: MMPBSA** can proceed.

---

## Moderate Pitfalls

Mistakes that cause delays, incomplete outputs, or require rework but don't invalidate the entire pipeline.

### Pitfall 5: HPC vs Local Execution Path Incompatibilities

**What Goes Wrong:** Pipeline scripts work on local machine but fail on HPC due to path differences, missing environment modules, or scheduler-specific job submission syntax.

**Why It Happens:** Absolute paths in scripts break when transferred between environments. GROMACS modules load differently on different HPC systems. Slurm directives differ from PBS/LSF.

**Consequences:**
- Jobs fail silently or queue indefinitely
- Scripts require manual path edits between environments
- "Works on my machine" but fails on cluster

**Prevention:**
- Use relative paths from project root wherever possible
- Isolate environment setup in `setenv.sh` and source before all scripts
- Detect HPC environment and load appropriate modules (check `$SLURM_JOB_ID` or `$PBS_JOBID`)
- Make HPC job submission script templates with clear placeholder comments

**Detection:**
- `FileNotFoundError` for input files
- GROMACS command not found after running script on HPC
- Job stays queued forever due to wrong queue/partition names

**Phase Mapping:** **Phase 2: Docking** and **Phase 3: MD Preparation** must support both local and HPC execution modes.

---

### Pitfall 6: Parallel Multi-Ligand Execution Race Conditions

**What Goes Wrong:** Running multiple ligand docking jobs in parallel causes race conditions: shared output files overwrite each other, GPU memory gets exhausted, or file locking conflicts occur.

**Why It Happens:** Scripts assume sequential execution or share temporary file names. Multiple processes write to the same log file or output directory simultaneously. GPU memory isn't managed across parallel processes.

**Consequences:**
- Corrupted SDF output files (incomplete writes)
- Some ligands silently fail to dock
- CUDA out-of-memory errors crash jobs
- Inconsistent output file naming prevents downstream processing

**Prevention:**
- Use unique output directories per ligand (e.g., `dock/ligand_001/`, `dock/ligand_002/`)
- Implement GPU memory check before launching gnina: `nvidia-smi --query-gpu=memory.free` and only launch if sufficient memory available
- Use proper job arrays in Slurm (`--array`) instead of manual parallel loops
- Add file locking or check for file existence before proceeding to next stage

**Detection:**
- Output SDF files are truncated or show parsing errors
- GPU processes don't launch (CUDA errors in logs)
- Some ligands missing from final results without error messages

**Phase Mapping:** **Phase 2: Docking** — multi-ligand parallel execution needs explicit handling.

---

### Pitfall 7: File Format Conversion Loses Coordinate Information

**What Goes Wrong:** Converting between PDB, SDF, GRO formats loses critical information: crystal waters, alternative atom positions, chain IDs, or residue insertion codes.

**Why It Happens:** Different formats have different capabilities. PDB has 6-digit precision (may lose sub-Angstrom precision), SDF format variations. Tools like OpenBabel may silently drop records they don't understand.

**Consequences:**
- Receptor binding pocket changes after conversion
- MMPBSA calculations fail due to missing atoms
- Docking box center shifts unexpectedly
- Coordinates no longer align with reference structure

**Prevention:**
- Preserve reference crystal structure as PDB format only, avoid round-trip conversions
- Validate coordinate integrity after conversion: compare atom counts, check if all residues present
- Use RDKit or OpenBabel with explicit format options to preserve important fields
- For MMPBSA, always regenerate topologies from the same structure used for MD

**Detection:**
- Atom count differs between input and output (use `grep "^ATOM" | wc -l`)
- Residue numbers show gaps or duplicates after conversion
- MMPBSA complains about missing atoms

**Phase Mapping:** **Phase 1: Receptor & Ligand Preparation** and **Phase 3: MD Preparation** — file format validation is needed after every conversion step.

---

### Pitfall 8: MMPBSA Topology Generation Mismatch with MD Structure

**What Goes Wrong:** The AMBER topology generated for MMPBSA doesn't match the GROMACS structure used in MD — atoms are missing, residue numbers don't align, or ligand parameters are incomplete.

**Why It Happens:** Ligand parameters are derived separately from the receptor, then combined. When generating the complex structure for MMPBSA, atom ordering may differ from what the parameter files expect. Waters/ions may be mismatched.

**Consequences:**
- MMPBSA calculation crashes with "Bond/Angle/Dihedral parameter not found"
- Binding energies are computed with incorrect atom assignments
- Silent parameter mismatches produce wrong energies without error messages

**Prevention:**
- Always regenerate complete AMBER topology from the exact same structure used in GROMACS
- Verify ligand parameter files are complete (check `[ dihedrals ]` and `[ dihedral_types ]` are present)
- Run `gmx_MMPBSA --rewrite-output` with `-np 1` first to debug topology issues before parallel production runs
- Compare atom counts between GRO and generated PRMTOP/INPCRD

**Detection:**
- "Cannot find dihedral parameters for atom types X-Y-Z" errors
- MMPBSA runs complete but energies are suspiciously round numbers (indicates default parameters used)
- Warning messages in gmx_MMPBSA log about missing parameters

**Phase Mapping:** **Phase 5: MMPBSA Binding Free Energy** — topology validation must occur before production MMPBSA runs.

---

## Minor Pitfalls

Mistakes that cause annoyance or minor rework but are easily fixable.

### Pitfall 9: Random Seed Not Fixed Produces Non-Reproducible Docking Results

**What Goes Wrong:** gnina docking uses random seeds by default. Running the same ligand-receptor pair twice produces different poses and scoring results.

**Why It Happens:** Monte Carlo sampling in docking uses random initialization. Without explicit seed setting, results are stochastic.

**Consequences:**
- Inconsistent docking results between pipeline runs
- Difficulty reproducing benchmark results
- Ranking of ligands changes between runs

**Prevention:**
- Always set explicit random seed in gnina: `--seed <integer>`
- Store the seed value in metadata alongside output for reproducibility
- Document seed in output log for debugging

**Phase Mapping:** **Phase 2: Docking** — seed setting should be default in docking scripts.

---

### Pitfall 10: Incorrect Box Size or Center Definition for Docking

**What Goes Wrong:** The docking box is either too small (ligand can't fit), too large (exhaustiveness wasted), or incorrectly centered (binding site excluded).

**Why It Happens:** Using the wrong autobox ligand or manual coordinates that don't match the actual binding pocket. Not accounting for ligand flexibility.

**Consequences:**
- No poses generated or all poses have clashes
- Docking exhaustiveness wastes time in wrong region
- Ligand gets cut off at box boundaries

**Prevention:**
- Always use a known binder ligand to define binding site (not just reference ligand)
- Add buffer: `--autobox_add 4` or more for flexible ligands
- Visualize the box in PyMOL before docking to verify coverage
- For whole-protein docking, use receptor center of mass

**Phase Mapping:** **Phase 2: Docking** — box definition should be validated visually or programmatically before running docking.

---

### Pitfall 11: Ion Concentration Not Matching MMPBSA Conditions

**What Goes Wrong:** MD simulation runs with physiological ion concentration (150mM NaCl), but MMPBSA calculations use default 0mM (implicit solvent) or mismatched ionic strength.

**Why It Happens:** MMPBSA calculations default to zero ionic strength unless explicitly specified. The binding free energy includes or excludes ionic strength effects inconsistently.

**Consequences:**
- Binding energies offset by ~1-2 kcal/mol from expected values
- Inconsistent comparison across ligands

**Prevention:**
- Use explicit `--saltcon` flag in gmx_MMPBSA matching the MD ionic strength
- Document ionic strength in metadata alongside energies
- For rigorous calculations, run both with and without ions

**Phase Mapping:** **Phase 5: MMPBSA** — ionic strength parameters should be explicit in config files.

---

### Pitfall 12: Insufficient Equilibration Time Before Production MD

**What Goes Wrong:** Production MD starts before the system is fully equilibrated. Initial frames show systematic drift rather than true sampling.

**Why It Happens:** Pressure equilibration (NPT) and temperature equilibration (NVT) are too short. Protein hasn't settled into stable conformation. Ligand position hasn't equilibrated.

**Consequences:**
- RMSD shows systematic increase rather than plateau
- Binding energies computed from unequilibrated frames are biased
- Results show false sensitivity to initial state

**Prevention:**
- Follow best practices: minimum 100ps NVT + 100ps NPT equilibration
- Check equilibration by plotting RMSD over time — require plateau before production
- For protein-ligand complexes, verify ligand RMSD reaches equilibrium
- Useberendsen or velocity-rescaling thermostat, Parrinello-Rahman barostat for stability

**Phase Mapping:** **Phase 4: Complex MD** — equilibration protocol must be validated in scripts.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| **Phase 1: Receptor/Ligand Prep** | FF incompatibility, missing hydrogens | Validate FF consistency, require hydrogen addition step |
| **Phase 2: Docking** | Wrong box definition, random non-reproducibility | Use autobox from known binder, set --seed |
| **Phase 3: MD Prep** | Path issues, format conversion errors | Validate structure integrity, use relative paths |
| **Phase 4: MD Simulation** | Insufficient equilibration, no stability check | Require RMSD plot verification before proceeding |
| **Phase 5: MMPBSA** | Topology mismatch, ion mismatch | Regenerate topology from MD structure, match saltcon |
| **Multi-stage workflow** | Context overflow, checkpoint loss | Implement file-based state tracking, mandatory checkpoints |

---

## Recommendations for Roadmap

1. **Phase 1 Must Include:** Force field validation, hydrogen addition verification, FF compatibility check
2. **Phase 2 Must Include:** Reproducibility (seed), box visualization/validation, unique output directories per ligand
3. **Phase 3 Must Include:** Path abstraction layer for HPC/local, structure integrity validation after conversions
4. **Phase 4 Must Include:** Equilibration stability check (RMSD), explicit equilibration time requirements
5. **Phase 5 Must Include:** Topology validation, ionic strength matching, debug run before production
6. **Cross-Cutting:** Checkpoint system design from Day 1; file-based state tracking; human verification gates between stages

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Force field pitfalls | HIGH | Domain knowledge from GROMACS/AMBER FF documentation |
| File format issues | HIGH | Standard format conversion problems well-documented |
| HPC differences | MEDIUM | Based on typical HPC environment patterns |
| Agent context overflow | HIGH | General LLM context window limitations |
| MMPBSA issues | MEDIUM | Based on gmx_MMPBSA documentation and known issues |
| Multi-ligand execution | MEDIUM | Based on typical parallel job patterns |

---

## Sources

- GROMACS documentation: Common errors and troubleshooting
- gnina GitHub: Issue discussions on docking failures
- gmx_MMPBSA documentation: Known topology issues
- Domain knowledge: Computational chemistry community best practices
- HPC workflow automation patterns: CommonSlurm/PBS differences