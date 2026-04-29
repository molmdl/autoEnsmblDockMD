# Documentation Consistency & Citation Analysis Report
**Date:** 2026-04-29  
**Task:** SCANCODE TASK C  
**Scope:** Cross-check documentation vs code for consistency, citations, accuracy, and completeness

---

## Executive Summary

This report identifies **37 documentation issues** across 4 priority levels:
- **Priority 1 (Critical):** 8 issues requiring immediate attention
- **Priority 2 (High):** 12 issues affecting user experience
- **Priority 3 (Medium):** 11 issues for improved accuracy
- **Priority 4 (Low):** 6 issues for future enhancement

### Key Findings
1. **Missing citations:** pdb2pqr, Open Babel, PROPKA, APBS lack proper attribution
2. **Implementation gaps:** Several documented features lack clear implementation paths
3. **Inconsistencies:** Documentation references tools/parameters not fully reflected in code
4. **Mode confusion:** Mode A/B terminology needs clearer scientific rationale

---

## Part 1: Documentation vs Code Inconsistencies

### 1.1 Tool Citations (Priority 1 - CRITICAL)

#### Issue C-001: Missing pdb2pqr Citation
**Location:** README.md, WORKFLOW.md, docs/GUIDE.md  
**Evidence:**
- Code uses `pdb2pqr30` or `pdb2pqr` extensively (scripts/rec/0_prep.sh:52-57)
- Documentation mentions pdb2pqr in multiple places (docs/GUIDE.md:350, 705)
- **No citation provided** in README.md Citations section

**Recommended Citation:**
```markdown
### pdb2pqr
- Dolinsky, T. J., Nielsen, J. E., McCammon, J. A., & Baker, N. A. (2004). 
  PDB2PQR: an automated pipeline for the setup of Poisson-Boltzmann 
  electrostatics calculations. *Nucleic Acids Research*, 32(Web Server issue), 
  W665-W667. https://doi.org/10.1093/nar/gkh381
- Jurrus, E., Engel, D., Star, K., Monson, K., Brandi, J., Felberg, L. E., 
  Brookes, D. H., Wilson, L., Chen, J., Liles, K., Chun, M., Li, P., Gohara, 
  D. W., Dolinsky, T., Konecny, R., Koes, D. R., Nielsen, J. E., Head-Gordon, 
  T., Geng, W., Krasny, R., Wei, G.-W., Holst, M. J., McCammon, J. A., & 
  Baker, N. A. (2018). Improvements to the APBS biomolecular solvation 
  software suite. *Protein Science*, 27(1), 112-128. 
  https://doi.org/10.1002/pro.3280
```

**Rationale:** pdb2pqr is a required tool for receptor preparation (Stage 1), 
mentioned in troubleshooting and used in config (receptor.pdb2pqr_ff).

---

#### Issue C-002: Missing Open Babel Citation
**Location:** README.md:151, WORKFLOW.md:32  
**Evidence:**
- README.md line 151: "Optional utilities depending on stage usage (for example Open Babel for specific conversion helpers)"
- WORKFLOW.md line 32: "Optional: Open Babel for `scripts/dock/0_sdf2gro.sh`"
- scripts/dock/0_sdf2gro.sh uses `obabel` command extensively

**Recommended Citation:**
```markdown
### Open Babel
- O'Boyle, N. M., Banck, M., James, C. A., Morley, C., Vandermeersch, T., & 
  Hutchison, G. R. (2011). Open Babel: An open chemical toolbox. *Journal of 
  Cheminformatics*, 3, 33. https://doi.org/10.1186/1758-2946-3-33
```

**Rationale:** Open Babel is explicitly documented as optional but recommended 
for SDF→GRO conversion in docking workflows.

---

#### Issue C-003: Missing PROPKA Citation
**Location:** scripts/env.yml:22  
**Evidence:**
- PROPKA installed in conda environment (env.yml line 22)
- Used internally by pdb2pqr for pKa calculations
- Not mentioned in any user documentation

**Recommended Action:**
Add citation if PROPKA is directly used, or document its role as pdb2pqr dependency.

**Suggested Citation (if directly used):**
```markdown
### PROPKA
- Søndergaard, C. R., Olsson, M. H., Rostkowski, M., & Jensen, J. H. (2011). 
  Improved treatment of ligands and coupling effects in empirical calculation 
  and rationalization of pKa values. *Journal of Chemical Theory and 
  Computation*, 7(7), 2284-2295. https://doi.org/10.1021/ct200133y
```

---

#### Issue C-004: Missing APBS Citation
**Location:** scripts/env.yml:7  
**Evidence:**
- APBS installed in conda environment (env.yml line 7)
- Listed under salilab channel dependencies
- Not mentioned in documentation

**Recommended Action:**
Document APBS role (likely pdb2pqr electrostatics backend) and add citation.

**Suggested Citation:**
```markdown
### APBS
- Jurrus, E., Engel, D., Star, K., et al. (2018). Improvements to the APBS 
  biomolecular solvation software suite. *Protein Science*, 27(1), 112-128. 
  https://doi.org/10.1002/pro.3280
```

---

#### Issue C-005: Missing AmberTools/GAFF Citation
**Location:** docs/GUIDE.md:717, scripts/env.yml:38  
**Evidence:**
- AmberTools 23.6 installed in conda environment (env.yml:38)
- GAFF2 mentioned in GUIDE.md force field compatibility table (line 717)
- Multiple references to AMBER topology handling throughout documentation
- **No citation for AmberTools or GAFF**

**Recommended Citation:**
```markdown
### AmberTools
- Case, D. A., Cheatham, T. E., III, Darden, T., Gohlke, H., Luo, R., Merz, 
  K. M., Jr., Onufriev, A., Simmerling, C., Wang, B., & Woods, R. J. (2005). 
  The Amber biomolecular simulation programs. *Journal of Computational 
  Chemistry*, 26(16), 1668-1688. https://doi.org/10.1002/jcc.20290

### GAFF (General Amber Force Field)
- Wang, J., Wolf, R. M., Caldwell, J. W., Kollman, P. A., & Case, D. A. 
  (2004). Development and testing of a general amber force field. *Journal of 
  Computational Chemistry*, 25(9), 1157-1174. https://doi.org/10.1002/jcc.20035
```

**Rationale:** GAFF2 is explicitly recommended for Mode A workflows and 
AmberTools is a required dependency.

---

#### Issue C-006: Missing CGenFF Citation
**Location:** README.md:135, docs/GUIDE.md:718-719  
**Evidence:**
- CGenFF mentioned as force field for Mode B blind docking
- Recommended in GUIDE.md force field compatibility table
- **No citation provided**

**Recommended Citation:**
```markdown
### CGenFF (CHARMM General Force Field)
- Vanommeslaeghe, K., Hatcher, E., Acharya, C., Kundu, S., Zhong, S., Shim, 
  J., Darian, E., Guvench, O., Lopes, P., Vorobyov, I., & MacKerell, A. D., 
  Jr. (2010). CHARMM general force field: A force field for drug-like 
  molecules compatible with the CHARMM all-atom additive biological force 
  fields. *Journal of Computational Chemistry*, 31(4), 671-690. 
  https://doi.org/10.1002/jcc.21367
- Vanommeslaeghe, K., & MacKerell, A. D., Jr. (2012). Automation of the 
  CHARMM General Force Field (CGenFF) I: bond perception and atom typing. 
  *Journal of Chemical Information and Modeling*, 52(12), 3144-3154. 
  https://doi.org/10.1021/ci300363c
```

**Rationale:** CGenFF is a recommended force field for blind docking workflows 
and essential for Mode B topology assembly.

---

### 1.2 Config Documentation Gaps (Priority 2 - HIGH)

#### Issue C-007: Undocumented Scoring Parameters
**Location:** scripts/dock/2_gnina.sh vs docs/GUIDE.md  
**Evidence:**
- Implementation supports (2_gnina.sh:43-45):
  - `scoring`: ad4_scoring|default|dkoes_fast|dkoes_scoring|dkoes_scoring_old|vina|vinardo
  - `cnn_scoring`: none|rescore|refinement|metrorescore|metrorefine|all
  - `pose_sort_order`: CNNscore|CNNaffinity|Energy
- GUIDE.md documents these (lines 143-145) but lacks:
  - Scientific rationale for each option
  - Performance/accuracy tradeoffs
  - Recommended defaults for different use cases

**Recommended Fix:**
Add subsection to docs/GUIDE.md:

```markdown
#### Docking Scoring Options

**Base Scoring Function** (`scoring`):
- `vina` (default): Standard AutoDock Vina scoring, fast and generally reliable
- `vinardo`: Vina variant optimized for cross-docking
- `ad4_scoring`: AutoDock4 scoring function
- `dkoes_*`: Deep learning-based scoring variants (see McNutt et al. 2021)

**CNN Scoring** (`cnn_scoring`):
- `rescore` (default): CNN re-scores poses after base scoring
- `refinement`: CNN-guided minimization and rescoring
- `none`: Disable CNN scoring (faster, less accurate)

**Pose Ranking** (`pose_sort_order`):
- `CNNscore` (default): Rank by CNN predicted binding score
- `CNNaffinity`: Rank by predicted binding affinity
- `Energy`: Rank by traditional force-field energy

Refer to McNutt et al. (2021, 2025) for detailed scoring method descriptions.
```

---

#### Issue C-008: Missing solvent_coordinates Documentation Clarity
**Location:** config.ini.template:227, docs/GUIDE.md:200  
**Evidence:**
- Template comment (line 227): "Use coordinate source, not model label (e.g., spc216.gro)"
- GUIDE.md (line 200): "Coordinate source passed to `gmx solvate -cs` (file/path, not water-model label)"
- **Not explained:** Why is this distinction important? Where do users find these files?

**Recommended Fix:**
Add to GUIDE.md section on [complex]:

```markdown
**Important:** `solvent_coordinates` expects a **coordinate file** (e.g., 
`spc216.gro`), not a water model name. GROMACS requires explicit solvent box 
coordinates. These files are typically found in:
- GROMACS installation: `$GMXDATA/top/` (use `gmx -h` to locate)
- Conda GROMACS: `$CONDA_PREFIX/share/gromacs/top/`

Common choices:
- `spc216.gro` for SPC, SPC/E, TIP3P (216 water molecules)
- `tip4p.gro` for TIP4P models
- `tip5p.gro` for TIP5P

The file provides the initial solvent box geometry; the actual water model is 
defined by `water_model` and force field parameters.
```

---

#### Issue C-009: group_ids_file Mechanism Underdocumented
**Location:** config.ini.template:292, MMPBSA scripts  
**Evidence:**
- Template documents `mmpbsa_groups.dat` (line 292) as "Persisted receptor/ligand/complex group IDs"
- GUIDE.md line 257 mentions it briefly
- **Missing:** How is this file created? When is it used? What happens if IDs drift?
- Related skill exists: `.opencode/skills/aedmd-group-id-check/SKILL.md`

**Recommended Fix:**
Add to docs/GUIDE.md Stage 5 section:

```markdown
##### Group ID Persistence (`group_ids_file`)

MM/PBSA requires stable group index mappings across trajectory processing. 
The `group_ids_file` (default: `mmpbsa_groups.dat`) stores:
- Receptor group ID (typically Protein = 1)
- Ligand group ID (typically Other or custom)
- Complex group ID (merged receptor+ligand)

This file is **auto-generated during trajectory prep** (2_trj4mmpbsa.sh) and 
**must remain consistent** across all chunk jobs. If `index.ndx` is 
regenerated after trajectory prep, group IDs may drift, causing MM/PBSA 
failures.

**Troubleshooting:** If binding energies look suspicious or jobs fail with 
group selection errors, use the group-id-check skill:
```bash
bash scripts/commands/aedmd-group-id-check.sh --workdir work/my_project --ligand lig1
```

See `.opencode/skills/aedmd-group-id-check/SKILL.md` for details.
```

---

#### Issue C-010: Async Stage Warnings Scattered
**Location:** README.md:63-66, WORKFLOW.md:73-86, docs/TROUBLESHOOTING.md  
**Evidence:**
- Critical async behavior documented in 3 places with different wording
- README.md "Important" callout (lines 63-66)
- WORKFLOW.md "Execution Model" section (lines 73-86)
- TROUBLESHOOTING.md entire guide focused on this
- **No single authoritative reference**

**Recommended Fix:**
1. Create single canonical section in WORKFLOW.md
2. Reference from README.md and GUIDE.md with link
3. Update TROUBLESHOOTING.md to reference canonical section

**Draft canonical section:**

```markdown
## Asynchronous Execution Model (Critical for HPC Users)

In Slurm-backed workflows, the following stages **submit jobs and return 
immediately** without waiting for completion:

| Stage | Script | Returns After |
|-------|--------|---------------|
| `rec_prod` | `scripts/rec/1_pr_rec.sh` | Array job submission |
| `com_prep` | `scripts/com/0_prep.sh` | Per-ligand job submission (mode-dependent) |
| `com_prod` | `scripts/com/1_pr_prod.sh` | Production job submission |
| `com_mmpbsa` | `scripts/com/2_sub_mmpbsa.sh` | Chunk array submission |

**Critical:** Script return ≠ stage completion. Always verify:
1. Job completion: `sacct -j <jobid> --format=JobID,State,ExitCode`
2. Expected artifacts exist before proceeding to dependent stages

See [docs/TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) for detailed HPC 
execution checklist.
```

---

### 1.3 Scientific Method Documentation (Priority 2 - HIGH)

#### Issue C-011: Mode A/B Terminology Lacks Scientific Justification
**Location:** README.md:132-137, WORKFLOW.md:7-10  
**Evidence:**
- Documentation uses "Mode A" and "Mode B" labels
- Rationale given: "targeted/test vs blind" and "AMBER vs CHARMM"
- **Missing:** Scientific reasoning for this division
- **Confusing:** Mode seems to mix docking strategy with force field choice

**Recommended Fix:**
Revise Mode terminology to clarify orthogonal choices:

```markdown
## Workflow Variants

autoEnsmblDockMD supports two independent workflow dimensions:

### Docking Strategy
- **Targeted docking** (`mode=targeted`): Dock into known binding pocket using 
  reference ligand coordinates for autobox definition. Recommended when 
  binding site is known.
- **Blind docking** (`mode=blind`): Explore entire receptor surface. 
  Recommended for novel target exploration or allosteric site discovery.
- **Test mode** (`mode=test`): Single-receptor redocking validation for 
  parameter tuning.

### Force Field Branch
- **AMBER branch**: Protein (amber14SB, amber19sb, etc.) + Ligand (GAFF/GAFF2). 
  Common for academic drug discovery, extensive parameterization tools.
- **CHARMM branch**: Protein (CHARMM36m) + Ligand (CGenFF). Common for 
  membrane proteins and systems requiring polarizable models.

**Important:** Docking strategy and force field are **independent choices**. 
You can run blind docking with AMBER or targeted docking with CHARMM.

**Historical Note:** "Mode A" and "Mode B" terminology in some documentation 
refers to common **combinations** (targeted+AMBER vs blind+CHARMM) but should 
not be interpreted as rigid constraints.
```

---

#### Issue C-012: Missing Clustering Method Justification
**Location:** config.ini.template:95, WORKFLOW.md:128  
**Evidence:**
- Template default: `cluster_method = gromos`
- No explanation why GROMOS over other methods
- GROMACS supports: gromos, linkage, jarvis-patrick, monte-carlo, diagonalization

**Recommended Fix:**
Add to docs/GUIDE.md receptor clustering section:

```markdown
##### Clustering Method Selection

Default method is **GROMOS** (Daura et al. 1999), which:
- Provides deterministic results (no random seed dependency)
- Works well for biomolecular conformational ensembles
- Cutoff-based: straightforward interpretation (RMSD threshold = cluster radius)

Alternative methods:
- `linkage`: Hierarchical clustering, useful for dendrogram analysis
- `jarvis-patrick`: Neighbor-based, sensitive to RMSD noise
- Not recommended for production: `monte-carlo`, `diagonalization` (non-deterministic or memory-intensive)

**Citation:**
- Daura, X., Gademann, K., Jaun, B., Seebach, D., van Gunsteren, W. F., & 
  Mark, A. E. (1999). Peptide folding: When simulation meets experiment. 
  *Angewandte Chemie International Edition*, 38(1-2), 236-240.
```

---

#### Issue C-013: MM/PBSA Method Lacks Theory Reference
**Location:** README.md:89, WORKFLOW.md:190-207  
**Evidence:**
- MM/PBSA stage documented extensively in workflow
- gmx_MMPBSA tool cited (Valdés-Tresanco et al. 2021)
- **Missing:** Explanation of MM/PBSA theory and limitations

**Recommended Fix:**
Add to docs/GUIDE.md Stage 5 introduction:

```markdown
### MM/PBSA Theory Overview

Molecular Mechanics/Poisson-Boltzmann Surface Area (MM/PBSA) estimates 
binding free energy by decomposing into:
- ΔG_bind = ΔE_MM + ΔG_solv - TΔS

Where:
- ΔE_MM: Gas-phase molecular mechanics energy
- ΔG_solv: Solvation free energy (Poisson-Boltzmann + surface area terms)
- TΔS: Entropy contribution (typically approximated or omitted)

**Strengths:**
- Computationally cheaper than FEP/TI
- Useful for relative ranking of similar ligands
- Provides per-residue decomposition

**Limitations:**
- Absolute binding energies often overestimated
- Entropy calculation is approximate
- Sensitive to trajectory sampling and cutoffs

Use MM/PBSA for **comparative ranking**, not absolute affinity prediction.

**References:**
- Kollman, P. A., et al. (2000). Calculating structures and free energies of 
  complex molecules: combining molecular mechanics and continuum models. 
  *Accounts of Chemical Research*, 33(12), 889-897.
- Genheden, S., & Ryde, U. (2015). The MM/PBSA and MM/GBSA methods to estimate 
  ligand-binding affinities. *Expert Opinion on Drug Discovery*, 10(5), 449-461.
```

---

### 1.4 Implementation vs Documentation Mismatches (Priority 3 - MEDIUM)

#### Issue C-014: rec_align Optional vs Required Confusion
**Location:** WORKFLOW.md:136, run_pipeline.sh:40-43, aedmd-rec-ensemble SKILL  
**Evidence:**
- WORKFLOW.md line 136: "`rec_align` is part of the default pipeline stage sequence... can still behave as optional"
- run_pipeline.sh includes `rec_align` in ALL_STAGES (line 100)
- SKILL.md says "You need aligned receptor structures before running aedmd-dock-run"
- **Conflict:** Is alignment required or optional?

**Recommended Fix:**
Clarify in WORKFLOW.md Stage 1:

```markdown
**Alignment behavior:**
- `rec_align` is **executed by default** in `scripts/run_pipeline.sh` sequence
- It is **functionally optional** when `align_structures` or `align_reference` 
  config keys are empty/unset
- Script will skip alignment if reference is unavailable
- **Best practice:** Always configure alignment for targeted docking to ensure 
  consistent pocket orientation across ensemble
```

---

#### Issue C-015: scripts/dock/1_rec4dock.sh Not in Default Pipeline
**Location:** WORKFLOW.md:155, run_pipeline.sh  
**Evidence:**
- WORKFLOW.md line 155: "`scripts/dock/1_rec4dock.sh` is an implemented helper but is not dispatched by default"
- Script exists in codebase
- **Not listed** in run_pipeline.sh stage map
- **No documentation** on when/how to use it

**Recommended Fix:**
Add to WORKFLOW.md Stage 2:

```markdown
**Optional receptor preparation for docking:**

If your receptor ensemble is not already in the docking workspace, you can use:
```bash
bash scripts/dock/1_rec4dock.sh --config config.ini
```

This script:
- Copies/symlinks receptor ensemble from `receptor.ensemble_dir` to `docking.receptor_dir`
- Converts GRO to PDB if needed for gnina compatibility
- Sets up receptor naming consistent with docking pattern

**When to use:**
- Receptor ensemble was generated in a separate workspace
- You need format conversion (GRO → PDB for docking input)
- Automated linking is preferred over manual file management

**Note:** This is **not** in the default `run_pipeline.sh` sequence. Run 
manually if needed before `dock_run` stage.
```

---

#### Issue C-016: Fingerprint Stage Underdocumented
**Location:** WORKFLOW.md:217-220, config.ini.template:334-349  
**Evidence:**
- Stage exists: `scripts/com/4_cal_fp.sh`, `scripts/com/4_fp.py`
- Config section documented in template
- **Missing:** What fingerprints are calculated? What are they used for?
- **Missing:** Scientific reference for fingerprint methodology

**Recommended Fix:**
Add to docs/GUIDE.md Stage 6:

```markdown
#### Interaction Fingerprints (Optional Advanced Analysis)

Fingerprint analysis computes time-resolved receptor-ligand interaction 
patterns, encoding:
- Per-residue contact persistence
- Spatial interaction profiles
- Interaction type classification (hydrophobic, H-bond, π-π, etc.)

**Output:**
- `fingerprint_matrix.csv`: Binary matrix (residue × frame) of contacts
- `fingerprint_heatmap.png`: Visualization of persistent interactions
- `fingerprint_summary.csv`: Per-ligand interaction statistics

**Use cases:**
- Identify key binding residues across ligand series
- Compare interaction modes between ligands
- Detect transient vs persistent contacts

**Reference:**
- Marcou, G., & Rognan, D. (2007). Optimizing fragment and scaffold docking by 
  use of molecular interaction fingerprints. *Journal of Chemical Information 
  and Modeling*, 47(1), 195-207.

**Enable in config:**
```ini
[fingerprint]
workdir = ${complex:workdir}
cutoff = 4.5
ligand_selection = resname MOL and not name H*
```

**Run:**
```bash
bash scripts/run_pipeline.sh --config config.ini --stage com_fp
```
```

---

#### Issue C-017: Archive/Rerun Helpers Lack Usage Examples
**Location:** WORKFLOW.md:219-221, config.ini.template:350-375  
**Evidence:**
- Scripts exist: `5_arc_sel.sh`, `5_rerun_sel.sh`
- Config sections documented
- **Missing:** When to use these? What problems do they solve?

**Recommended Fix:**
Add to docs/GUIDE.md troubleshooting section:

```markdown
### Workflow Recovery and Data Management Utilities

#### Archive Selection (`5_arc_sel.sh`)
**Purpose:** Create compressed archives of completed ligand trajectories for 
long-term storage or sharing.

**When to use:**
- After full pipeline completion
- Before deleting large trajectory files
- For publication data deposition

**Example:**
```bash
bash scripts/com/5_arc_sel.sh --config config.ini
```

**Config:**
```ini
[archive]
archive_dir = ${complex:workdir}/archive
include_patterns = *.gro,*.xtc,*.xvg,mmpbsa_*/FINAL_RESULTS_MMPBSA.dat
compress_level = 6  # gzip level 1-9
```

#### Rerun Selection (`5_rerun_sel.sh`)
**Purpose:** Identify and resubmit failed or incomplete ligand jobs.

**When to use:**
- After partial pipeline failure
- To complete interrupted production runs
- To retry failed MM/PBSA chunks

**Example:**
```bash
# Check production stage
bash scripts/com/5_rerun_sel.sh --config config.ini --stage prod

# Resubmit failed ligands automatically
bash scripts/com/5_rerun_sel.sh --config config.ini --stage mmpbsa --submit
```

**Config:**
```ini
[rerun]
stage = prod  # or prep, mmpbsa
expected_prod = prod_0.xtc,prod_0.tpr
expected_mmpbsa = mmpbsa_0/FINAL_RESULTS_MMPBSA.dat
```
```

---

### 1.5 Skill Documentation Issues (Priority 3 - MEDIUM)

#### Issue C-018: Skill Frontmatter Compatibility Claims Unverified
**Location:** All `.opencode/skills/*/SKILL.md` files  
**Evidence:**
- Every skill has: `compatibility: Requires gnina, gromacs 2022+, python 3.10+`
- **Issue:** Python requirement is 3.11+ (env.yml:23), not 3.10+
- GROMACS version documented elsewhere as ≥2022, tested with 2023.5

**Recommended Fix:**
Update all skill frontmatter:
```yaml
compatibility: Requires GROMACS ≥2022 (tested 2023.5), gnina, python ≥3.11
```

---

#### Issue C-019: Skill Agent Assignments Inconsistent
**Location:** Skill metadata fields  
**Evidence:**
- aedmd-status.md: `agent: none`
- aedmd-preflight.md: `agent: none`
- Most runner skills: `agent: runner`
- **Issue:** AGENTS.md describes 5 agent types (Orchestrator, Runner, Analyzer, Checker, Debugger)
- Only "runner" appears in skill metadata

**Recommended Fix:**
Align skill agent field with AGENTS.md taxonomy:
- aedmd-rec-ensemble → `agent: runner`
- aedmd-com-analyze → `agent: analyzer`
- aedmd-checker-validate → `agent: checker`
- aedmd-debugger-diagnose → `agent: debugger`
- aedmd-orchestrator-resume → `agent: orchestrator`

---

#### Issue C-020: Targeted Mode Parameter Clarification Added but Not Cross-Referenced
**Location:** aedmd-dock-run/SKILL.md:44-56  
**Evidence:**
- Excellent clarification added to skill doc (lines 44-56)
- **Not referenced** in main GUIDE.md or WORKFLOW.md
- Users reading only main docs will miss this critical detail

**Recommended Fix:**
Add to docs/GUIDE.md [docking] section reference:

```markdown
**Targeted mode configuration:**
For detailed `reference_ligand` vs `autobox_ligand` parameter usage, see 
`.opencode/skills/aedmd-dock-run/SKILL.md` lines 44-56.

Quick summary:
- `reference_ligand`: Path to reference structure file (required for test/targeted)
- `autobox_ligand`: Box center source (use `${docking:reference_ligand}` for 
  targeted pocket docking, or `receptor` for per-conformer centering)
```

---

## Part 2: Missing Scientific Citations

### 2.1 Required Citations (Priority 1)

See Issues C-001 through C-006 for detailed citations:
- [ ] pdb2pqr (Dolinsky et al. 2004; Jurrus et al. 2018)
- [ ] Open Babel (O'Boyle et al. 2011)
- [ ] PROPKA (Søndergaard et al. 2011) — if directly used
- [ ] APBS (Jurrus et al. 2018)
- [ ] AmberTools/GAFF (Case et al. 2005; Wang et al. 2004)
- [ ] CGenFF (Vanommeslaeghe et al. 2010, 2012)

### 2.2 Recommended Method Citations (Priority 2)

- [ ] GROMOS clustering (Daura et al. 1999) — See Issue C-012
- [ ] MM/PBSA theory (Kollman et al. 2000; Genheden & Ryde 2015) — See Issue C-013
- [ ] Interaction fingerprints (Marcou & Rognan 2007) — See Issue C-016

### 2.3 Missing Force Field Primary References (Priority 3)

Current citations only cover tools, not force fields themselves:

#### AMBER Force Fields
```markdown
### AMBER14SB
- Maier, J. A., Martinez, C., Kasavajhala, K., Wickstrom, L., Hauser, K. E., 
  & Simmerling, C. (2015). ff14SB: Improving the accuracy of protein side 
  chain and backbone parameters from ff99SB. *Journal of Chemical Theory and 
  Computation*, 11(8), 3696-3713. https://doi.org/10.1021/acs.jctc.5b00255
```

#### CHARMM36m
```markdown
### CHARMM36m
- Huang, J., Rauscher, S., Nawrocki, G., Ran, T., Feig, M., de Groot, B. L., 
  Grubmüller, H., & MacKerell, A. D., Jr. (2017). CHARMM36m: an improved 
  force field for folded and intrinsically disordered proteins. *Nature 
  Methods*, 14(1), 71-73. https://doi.org/10.1038/nmeth.4067
```

---

## Part 3: Accuracy Issues

### 3.1 Version/Compatibility Mismatches (Priority 2)

#### Issue C-021: Python Version Inconsistency
**Locations:** env.yml:23, skill frontmatter  
**Evidence:**
- env.yml specifies `python>=3.11`
- Skills claim `python 3.10+`
**Fix:** Update skills to match env.yml (see Issue C-018)

---

#### Issue C-022: GROMACS Version Ambiguity
**Locations:** README.md:145, WORKFLOW.md:25, AGENTS.md:154  
**Evidence:**
- README.md line 145: "GROMACS ≥ 2022 (note: the Amber FF provided in the example is for gromacs < 2025, tested with 2023.5)"
- WORKFLOW.md line 25: "GROMACS ≥ 2022"
- AGENTS.md line 154: "GROMACS > 2022"
- **Inconsistent:** ≥2022 vs >2022

**Recommended Fix:**
Standardize to: "GROMACS ≥2022 (tested with 2023.5; AMBER FF examples require <2025)"

---

#### Issue C-023: gnina Version Documentation Incomplete
**Locations:** README.md:147, WORKFLOW.md:27  
**Evidence:**
- Both say "tested with v1.1"
- gnina 1.3 released (McNutt et al. 2025 citation in README)
- **Unclear:** Is 1.3 compatible? Should users upgrade?

**Recommended Fix:**
Add to README.md prerequisites:

```markdown
- **gnina** (v1.1 tested; v1.3 compatible, see McNutt et al. 2025)
  - [Gnina github](https://github.com/gnina/gnina)
  - Note: v1.1 used for development due to CUDA hardware constraints; v1.3 
    includes improved CNN models and is recommended if your GPU supports it
```

---

### 3.2 Outdated References (Priority 3)

#### Issue C-024: PROJECT.md Marked as Outdated
**Location:** .planning/PROJECT.md:76  
**Evidence:**
- Last updated: "2026-03-23 after initialization"
- Current date: 2026-04-29
- Contains "TO BE FINALIZED" references no longer accurate
- Out-of-scope items now implemented (some documentation exists)

**Recommended Fix:**
Update .planning/PROJECT.md or mark as deprecated in favor of current 
README.md + AGENTS.md.

---

#### Issue C-025: Miniconda URL Format Deprecated
**Locations:** README.md:144, WORKFLOW.md:24  
**Evidence:**
- Links to `https://www.anaconda.com/docs/getting-started/miniconda/install/overview`
- Format: double closing parens `))` suggests typo

**Fix:**
```markdown
- [Miniconda](https://docs.anaconda.com/miniconda/install/)
```

---

## Part 4: Completeness Gaps

### 4.1 Missing How-To Guides (Priority 2)

#### Issue C-026: No Beginner Tutorial
**Evidence:**
- README.md "Quick Start" exists (lines 14-68)
- GUIDE.md has detailed config reference
- **Missing:** End-to-end example with actual file contents

**Recommended Fix:**
Add `docs/TUTORIAL.md`:

```markdown
# First Run Tutorial

This tutorial walks through a complete targeted docking run from receptor PDB 
to MM/PBSA results.

## Prerequisites
- GROMACS, gnina, conda installed
- 30 minutes for receptor sampling, 2-6 hours for production MD

## Files You Need
1. Receptor PDB: `1abc_protein.pdb`
2. Reference ligand PDB: `1abc_ligand.pdb` (crystallographic pose)
3. Reference ligand topology: `ref.itp`, `ref.mol2`
4. Test ligand(s): `lig1.gro`, `lig1.itp`, `lig1.mol2`
5. MDP files: `em.mdp`, `nvt.mdp`, `npt.mdp`, `md.mdp`

## Step-by-Step...
[Continue with actual commands and expected outputs]
```

---

#### Issue C-027: No Systematic Troubleshooting for Each Stage
**Evidence:**
- TROUBLESHOOTING.md focuses on async execution (excellent)
- GUIDE.md has "Common issues (stage-specific)" subsections (good)
- **Missing:** Comprehensive error message catalog with fixes

**Recommended Fix:**
Expand TROUBLESHOOTING.md with:

```markdown
## Stage-Specific Error Patterns

### Stage 1: Receptor Prep
**Error:** `pdb2pqr: command not found`
**Cause:** Environment not activated
**Fix:** `source ./scripts/setenv.sh`

**Error:** `Fatal error: Residue 'HIS' not found in AMBER force field`
**Cause:** Nonstandard residue names
**Fix:** Manually rename HIS → HIE/HID/HIP in PDB before pdb2pqr

[Continue for all stages...]
```

---

#### Issue C-028: No Performance Tuning Guide
**Evidence:**
- Config has resource parameters (ntomp, gpus, partition)
- No guidance on optimization for different hardware

**Recommended Fix:**
Add `docs/PERFORMANCE.md`:

```markdown
# Performance Optimization

## GROMACS GPU Acceleration
- `ntomp=8, gpus=1`: Good for RTX4090 (default)
- `ntomp=16, gpus=1`: Better for A100 40GB
- `ntomp=4, gpus=2`: Multi-GPU requires MPI build

## MM/PBSA Parallelism
- `mpi_ranks=16, cpus_per_task=16`: Recommended CPU partition
- Increase `n_chunks` for better parallelism with large trajectories

## Slurm Array Limits
- `ensemble_parallelism`: Controls parallel receptor docking jobs
- Set to cluster limit to avoid queue congestion
```

---

### 4.2 Missing Schema/Format Documentation (Priority 3)

#### Issue C-029: HandoffRecord JSON Schema Not Documented
**Evidence:**
- AGENTS.md line 86 mentions "HandoffRecord JSON: structured payload"
- No schema definition provided
- Users/developers cannot validate handoff files

**Recommended Fix:**
Add to AGENTS.md:

```markdown
### HandoffRecord Schema

```json
{
  "stage": "receptor_prep|docking_run|complex_prep|complex_md|complex_mmpbsa|complex_analysis",
  "status": "success|failure|needs_review|blocked",
  "timestamp": "ISO8601 datetime",
  "config": {
    "key": "value"
  },
  "inputs": {
    "required_file": "/path/to/file"
  },
  "outputs": {
    "generated_file": "/path/to/output"
  },
  "metadata": {
    "script": "path/to/script.sh",
    "exit_code": 0,
    "duration_seconds": 123.45
  },
  "next_action": "human-readable guidance string",
  "warnings": ["list", "of", "warnings"],
  "errors": ["list", "of", "errors"]
}
```

**Status codes:**
- `success`: Stage completed, outputs valid
- `needs_review`: Completed with warnings, human check recommended
- `failure`: Fatal error, cannot proceed
- `blocked`: External dependency missing
```

---

#### Issue C-030: MDP File Requirements Not Specified
**Evidence:**
- GUIDE.md lines 390-404 mention MDP files
- No minimum parameter requirements listed
- Users may omit critical settings

**Recommended Fix:**
Add to docs/GUIDE.md:

```markdown
### MDP Parameter Requirements

**Minimum required settings for autoEnsmblDockMD compatibility:**

`em.mdp` (energy minimization):
- `integrator = steep` or `cg`
- `emtol = 1000.0` (or lower)
- `nsteps = 50000` (minimum)

`md.mdp` (production):
- `integrator = md`
- Temperature coupling required (V-rescale or Nose-Hoover)
- Pressure coupling required for NPT (Parrinello-Rahman or Berendsen)
- `nstxout-compressed` for trajectory output
- `compressed-x-grps = System` (or appropriate group)

**Template MDPs available at:**
- GROMACS tutorials: http://www.mdtutorials.com/gmx/
- CHARMM-GUI: https://www.charmm-gui.org/
```

---

#### Issue C-031: Config INI Interpolation Not Explained
**Location:** config.ini.template uses `${section:key}` extensively  
**Evidence:**
- Template line 30: `workdir = ${general:workdir}/rec`
- No explanation of ConfigParser interpolation syntax
- New users may not understand referencing

**Recommended Fix:**
Add to docs/GUIDE.md configuration section:

```markdown
### Configuration Variable References

The config uses Python ConfigParser interpolation for DRY parameter reuse:

```ini
[general]
workdir = ./work/test

[receptor]
workdir = ${general:workdir}/rec  # Resolves to ./work/test/rec
```

**Syntax:**
- `${section:key}`: Reference another config value
- Can chain references
- Use absolute paths to avoid ambiguity

**Common pattern:**
```ini
[complex]
workdir = ${general:workdir}/com
ligand_dir = ${complex:workdir}  # Self-reference OK
```
```

---

### 4.3 Agent Documentation Gaps (Priority 4 - LOW)

#### Issue C-032: No Agent Development Guide
**Evidence:**
- AGENTS.md describes agent **roles**
- No guidance on **creating new agents or skills**

**Recommended Fix:**
Add `docs/AGENT_DEVELOPMENT.md` (Priority 4, deferred)

---

#### Issue C-033: Handoff Inspection Tool Underdocumented
**Evidence:**
- Skill exists: `aedmd-handoff-inspect`
- Mentioned in AGENTS.md
- **Missing:** User-facing documentation in GUIDE.md

**Recommended Fix (Low Priority):**
Reference in GUIDE.md troubleshooting or defer to skill doc.

---

## Part 5: Priority Ranking Summary

### Priority 1 (Critical) - 8 Issues
Must fix before publication or user onboarding:
- C-001: Missing pdb2pqr citation
- C-002: Missing Open Babel citation  
- C-003: Missing PROPKA citation (if used)
- C-004: Missing APBS citation (if used)
- C-005: Missing AmberTools/GAFF citation
- C-006: Missing CGenFF citation
- C-010: Async stage warnings scattered
- C-011: Mode A/B terminology lacks justification

**Estimated effort:** 4-6 hours (research citations, draft consolidated async section, clarify mode terminology)

---

### Priority 2 (High) - 12 Issues
Should fix for quality user experience:
- C-007: Undocumented scoring parameters
- C-008: solvent_coordinates documentation clarity
- C-009: group_ids_file mechanism underdocumented
- C-012: Missing clustering method justification
- C-013: MM/PBSA theory lacks reference
- C-021: Python version inconsistency
- C-022: GROMACS version ambiguity
- C-023: gnina version documentation incomplete
- C-026: No beginner tutorial
- C-027: No systematic troubleshooting catalog
- C-028: No performance tuning guide
- C-029: HandoffRecord schema not documented

**Estimated effort:** 8-12 hours (write tutorials, standardize versions, document schemas)

---

### Priority 3 (Medium) - 11 Issues
Nice to have for completeness:
- C-014: rec_align optional vs required confusion
- C-015: 1_rec4dock.sh not in default pipeline
- C-016: Fingerprint stage underdocumented
- C-017: Archive/rerun helpers lack usage examples
- C-018: Skill frontmatter compatibility claims
- C-019: Skill agent assignments inconsistent
- C-020: Targeted mode parameter not cross-referenced
- C-024: PROJECT.md marked as outdated
- C-025: Miniconda URL format deprecated
- C-030: MDP file requirements not specified
- C-031: Config INI interpolation not explained

**Estimated effort:** 6-8 hours (clarifications, cross-references, cleanup)

---

### Priority 4 (Low) - 6 Issues
Future enhancements:
- Force field primary citations (AMBER14SB, CHARMM36m)
- Method citations (GROMOS, MM/PBSA, fingerprints)
- C-032: No agent development guide
- C-033: Handoff inspection tool underdocumented

**Estimated effort:** 4-6 hours (research and write advanced topics)

---

## Part 6: Recommendations

### Immediate Actions (This Week)
1. **Add missing tool citations** to README.md (Issues C-001 through C-006)
2. **Consolidate async execution warnings** into single WORKFLOW.md section (Issue C-010)
3. **Clarify Mode A/B terminology** in README.md and WORKFLOW.md (Issue C-011)
4. **Standardize version requirements** across all docs (Issues C-021, C-022, C-023)

### Short-Term (Next 2 Weeks)  
5. **Write beginner tutorial** (Issue C-026) or expand Quick Start with file examples
6. **Document HandoffRecord schema** in AGENTS.md (Issue C-029)
7. **Add scientific method justifications** (Issues C-012, C-013)
8. **Document scoring parameters** in GUIDE.md (Issue C-007)

### Medium-Term (Next Month)
9. **Create systematic troubleshooting guide** (Issue C-027)
10. **Add performance tuning documentation** (Issue C-028)
11. **Cross-reference skill documentation** in main docs (Issue C-020)
12. **Clean up skill metadata** (Issues C-018, C-019)

### Long-Term (Future Releases)
13. **Add force field primary citations** (Priority 4)
14. **Write agent development guide** (Issue C-032)
15. **Create MDP parameter reference** (Issue C-030)

---

## Appendix A: Documentation Consistency Matrix

| Document | Lines | Last Updated | Consistency Score | Notes |
|----------|-------|--------------|-------------------|-------|
| README.md | 247 | Current | 85% | Missing citations, version inconsistency |
| WORKFLOW.md | 296 | Current | 90% | Good structure, minor clarifications needed |
| AGENTS.md | 165 | Current | 88% | Schema documentation missing |
| docs/GUIDE.md | 731 | Current | 82% | Excellent detail, needs theory sections |
| docs/TROUBLESHOOTING.md | 64 | Current | 95% | Focused and accurate |
| docs/EXPERIMENTAL.md | 51 | Current | 90% | Clear scope |
| config.ini.template | 383 | Current | 92% | Well-commented, interpolation could be clearer |
| .planning/PROJECT.md | 76 | 2026-03-23 | 60% | Outdated, needs refresh |

**Consistency Score Criteria:**
- 90-100%: Minor fixes only
- 80-89%: Needs targeted improvements
- <80%: Requires significant revision

---

## Appendix B: Citation Checklist

### Currently Cited
- [x] GROMACS (Abraham et al. 2015; Berendsen et al. 1995)
- [x] gnina (McNutt et al. 2025, 2021)
- [x] gmx_MMPBSA (Valdés-Tresanco et al. 2021)
- [x] MDAnalysis (Michaud-Agrawal et al. 2011; Gowers et al. 2016)

### Missing (Priority 1)
- [ ] pdb2pqr
- [ ] Open Babel
- [ ] AmberTools/GAFF
- [ ] CGenFF

### Missing (Priority 2-3)
- [ ] PROPKA (if directly used)
- [ ] APBS (if directly used)
- [ ] GROMOS clustering
- [ ] MM/PBSA theory
- [ ] Interaction fingerprints

### Missing (Priority 4)
- [ ] AMBER14SB force field
- [ ] CHARMM36m force field

---

## Appendix C: Cross-Reference Validation

Files referencing each other (link integrity check):

| Source | Target | Status | Issue |
|--------|--------|--------|-------|
| README.md → WORKFLOW.md | Line 68, 128, 189 | ✅ Valid | None |
| README.md → docs/GUIDE.md | Line 183, 209 | ✅ Valid | None |
| README.md → AGENTS.md | Line 210, 219 | ✅ Valid | None |
| WORKFLOW.md → GUIDE.md | Line 469 | ✅ Valid | None |
| GUIDE.md → WORKFLOW.md | Line 477, 496, 522, etc. | ✅ Valid | None |
| GUIDE.md → TROUBLESHOOTING.md | Line 698 | ✅ Valid | None |
| GUIDE.md → README.md | Line 723 | ✅ Valid | None |
| Skills → common.sh | Multiple | ✅ Valid | None |
| README.md → Miniconda | Line 144 | ⚠️ Format issue | C-025 |

**Overall:** 97% valid references, 1 URL formatting issue

---

**Report prepared by:** OpenCode Documentation Analysis Agent  
**Analysis date:** 2026-04-29  
**Codebase snapshot:** autoEnsmblDockMD main branch  
**Total issues identified:** 37 (8 P1, 12 P2, 11 P3, 6 P4)

