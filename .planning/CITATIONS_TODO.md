# Citations To-Do List

**Source:** Scancode Analysis Report C (Documentation Consistency)  
**Date:** 2026-04-29  
**Status:** Requires manual verification before adding to README.md

---

## Priority 1: Critical Missing Citations

These tools are used extensively in the codebase and MUST be cited before publication or production use.

### 1. pdb2pqr
**Used in:** `scripts/rec/0_prep.sh`, documented in README, WORKFLOW, GUIDE  
**Citations:**
```markdown
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

### 2. Open Babel
**Used in:** Ligand file format conversions (SDF, MOL2, PDB)  
**Citation:**
```markdown
- O'Boyle, N. M., Banck, M., James, C. A., Morley, C., Vandermeersch, T., 
  & Hutchison, G. R. (2011). Open Babel: An open chemical toolbox. 
  *Journal of Cheminformatics*, 3(1), 33. 
  https://doi.org/10.1186/1758-2946-3-33
```

### 3. AmberTools / GAFF (General Amber Force Field)
**Used in:** Mode A topology generation, ligand parameterization  
**Citations:**
```markdown
- Case, D. A., Cheatham, T. E., III, Darden, T., Gohlke, H., Luo, R., 
  Merz, K. M., Jr., Onufriev, A., Simmerling, C., Wang, B., & Woods, R. J. 
  (2005). The Amber biomolecular simulation programs. 
  *Journal of Computational Chemistry*, 26(16), 1668-1688. 
  https://doi.org/10.1002/jcc.20290

- Wang, J., Wolf, R. M., Caldwell, J. W., Kollman, P. A., & Case, D. A. (2004). 
  Development and testing of a general amber force field. 
  *Journal of Computational Chemistry*, 25(9), 1157-1174. 
  https://doi.org/10.1002/jcc.20035
```

### 4. CGenFF (CHARMM General Force Field)
**Used in:** Mode B topology generation, ligand parameterization  
**Citations:**
```markdown
- Vanommeslaeghe, K., Hatcher, E., Acharya, C., Kundu, S., Zhong, S., Shim, J., 
  Darian, E., Guvench, O., Lopes, P., Vorobyov, I., & MacKerell, A. D., Jr. 
  (2010). CHARMM general force field: A force field for drug-like molecules 
  compatible with the CHARMM all-atom additive biological force fields. 
  *Journal of Computational Chemistry*, 31(4), 671-690. 
  https://doi.org/10.1002/jcc.21367

- Vanommeslaeghe, K., & MacKerell, A. D., Jr. (2012). Automation of the 
  CHARMM General Force Field (CGenFF) I: bond perception and atom typing. 
  *Journal of Chemical Information and Modeling*, 52(12), 3144-3154. 
  https://doi.org/10.1021/ci300363c
```

---

## Priority 2: Conditional Citations

Only needed if these tools are **directly used** (verify in code):

### 5. PROPKA
**Verify usage:** Check if pH prediction is used directly (may be internal to pdb2pqr)  
**Citation (if used):**
```markdown
- Søndergaard, C. R., Olsson, M. H. M., Rostkowski, M., & Jensen, J. H. (2011). 
  Improved Treatment of Ligands and Coupling Effects in Empirical Calculation 
  and Rationalization of pKa Values. 
  *Journal of Chemical Theory and Computation*, 7(7), 2284-2295. 
  https://doi.org/10.1021/ct200133y
```

### 6. APBS (Adaptive Poisson-Boltzmann Solver)
**Verify usage:** Check if electrostatic calculations used directly  
**Citation (if used):**
```markdown
- Jurrus, E., et al. (2018). [Same as pdb2pqr citation above - APBS bundled with PDB2PQR]
```

---

## Priority 3: Method Citations

Consider adding these for scientific completeness:

### 7. GROMOS Clustering
**Used in:** Receptor ensemble clustering (`scripts/rec/2_cluster.sh`)  
**Citation:**
```markdown
- Daura, X., Gademann, K., Jaun, B., Seebach, D., van Gunsteren, W. F., 
  & Mark, A. E. (1999). Peptide Folding: When Simulation Meets Experiment. 
  *Angewandte Chemie International Edition*, 38(1-2), 236-240.
```

### 8. MM/PBSA Theory
**Used in:** Binding free energy calculations  
**Suggested citation:**
```markdown
- Genheden, S., & Ryde, U. (2015). The MM/PBSA and MM/GBSA methods to estimate 
  ligand-binding affinities. 
  *Expert Opinion on Drug Discovery*, 10(5), 449-461. 
  https://doi.org/10.1517/17460441.2015.1032936
```

---

## Already Cited (✓)

These tools are already properly cited in README.md:

- ✅ GROMACS
- ✅ gnina
- ✅ gmx_MMPBSA
- ✅ MDAnalysis

---

## Action Items

### Step 1: Verify Tool Usage (30 min)
- [ ] Confirm PROPKA is used directly (not just via pdb2pqr)
- [ ] Confirm APBS is used directly (not just via pdb2pqr)
- [ ] Check if GROMOS clustering should be cited

### Step 2: Add Citations to README.md (30 min)
Location: `README.md` → **Citations** section

Add Priority 1 citations (mandatory):
- [ ] pdb2pqr (2 citations)
- [ ] Open Babel
- [ ] AmberTools/GAFF (2 citations)
- [ ] CGenFF (2 citations)

Add Priority 2 citations (if verified):
- [ ] PROPKA (conditional)
- [ ] APBS (conditional - may be covered by pdb2pqr citation)

Add Priority 3 citations (recommended):
- [ ] GROMOS clustering (if used)
- [ ] MM/PBSA theory overview

### Step 3: Update Documentation (15 min)
- [ ] Ensure citations appear in README.md **Citations** section
- [ ] Add brief mention in WORKFLOW.md where tools are first used
- [ ] Consider adding to docs/GUIDE.md in relevant sections

---

## Notes

**Manual verification required because:**
1. Tool versions may have different citation requirements
2. Some tools (PROPKA, APBS) may be used internally by other tools
3. Citation style may need to match journal/institutional requirements
4. DOI links should be verified as active

**Estimated time to complete:** 1-2 hours total (including verification)

---

**Next steps:**
1. Review this document
2. Verify tool usage in codebase
3. Add verified citations to README.md
4. Commit with message: `docs: add missing tool citations (scancode C-001 to C-006)`
