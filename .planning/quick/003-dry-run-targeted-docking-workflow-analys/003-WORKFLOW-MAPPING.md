# 003 Workflow Mapping (Dry Run)

## Scope and Method

- Plan: `quick-003/01`
- Mode: **DRY RUN ONLY** (documentation + code inspection, no stage/script execution)
- User perspective: targeted docking (Mode A) from `work/input/` example data
- Primary references:
  - `WORKFLOW.md`
  - `AGENTS.md`
  - `work/input/README.md`
  - `.opencode/skills/aedmd-*/SKILL.md`
  - `scripts/commands/common.sh`
  - `scripts/config.ini.template`

---

## 1) Workspace Pattern (Required Operating Pattern)

### Pattern statement

Inputs are maintained under `work/input/`, then copied into a **run workspace** such as:

- `work/test/` (validation workspace)
- `work/run_YYYY-MM-DD/` (date-stamped execution workspace)

### Why this pattern matters

1. Preserves original user inputs (`work/input/`) as immutable source assets.
2. Prevents accidental overwrite of canonical input files during iterative runs.
3. Enables run-to-run reproducibility and auditability.
4. Supports parallel experiments with isolated workspaces.

### Canonical structure expected in workspace

Derived from `WORKFLOW.md` and config template defaults:

```text
work/<run>/
├── config.ini
├── rec/
├── dock/
├── com/
├── mdp/rec/
├── mdp/com/
└── ref/                # optional reference-ligand assets
```

### Input copy map (from `work/input/`)

| Source in `work/input/` | Target in workspace | Used by stage | Notes |
|---|---|---|---|
| `rec.pdb` | `rec/receptor.pdb` (or configured path) | Stage 1 | Main receptor input (`receptor.input_pdb`) |
| `ref.pdb` | `dock/ref.pdb` | Stage 2 | Reference ligand for targeted autobox (`docking.reference_ligand`) |
| `2bxo.pdb` | optional (e.g., `rec/2bxo.pdb`) | Stage 1/validation | Purpose unclear; likely alt receptor/alignment reference |
| `dzp/` | `dock/dzp/` or ligand dir per config | Stages 2–6 | Ligand with AMBER-style topology assets |
| `ibp/` | `dock/ibp/` or ligand dir per config | Stages 2–6 | Ligand with AMBER-style topology assets |
| `amber19SB_OL21_OL3_lipid17.ff/` | workspace FF path | Stages 1 & 3 | FF assets for AMBER-oriented runs |

---

## 2) Input Files → Workflow Semantics Mapping

| Input file/dir | Workflow meaning | Primary config linkage | Stage dependency |
|---|---|---|---|
| `work/input/rec.pdb` | Receptor structure to prepare and sample | `[receptor] input_pdb` | Stage 1 prerequisite |
| `work/input/ref.pdb` | Pocket-definition ligand for targeted/test docking | `[docking] reference_ligand` | Stage 2 targeted/test prerequisite |
| `work/input/2bxo.pdb` | Additional receptor candidate/reference | potentially `[receptor] align_reference` or extra rec source | Non-blocking; document ambiguity |
| `work/input/dzp/*.itp|*.gro|*.mol2|*.top` | Ligand/topology inputs for docking and complex prep | `[dock]`, `[docking]`, `[dock2com]`, `[complex]` | Stages 2–6 |
| `work/input/ibp/*.itp|*.gro|*.mol2|*.top` | Same as above for second ligand | same as above | Stages 2–6 |

---

## 3) Targeted Docking Mode A: Stage-by-Stage Mapping

> Note: Plan requests “all 6 stages”; operationally this includes Stage 0 preflight plus Stages 1–6.

| Stage | User-facing objective | Skill | Wrapper | Stage token | Script(s) resolved/executed | Key config keys |
|---|---|---|---|---|---|---|
| 0: Input prep | Validate config + paths | (N/A direct skill) | `scripts/run_pipeline.sh` preflight | N/A | `scripts/infra/config_loader.sh`, `scripts/infra/common.sh` | `[general] workdir`, required section presence |
| 1: Receptor ensemble | Prepare receptor + sample + cluster + align | `aedmd-rec-ensemble` | `scripts/commands/aedmd-rec-ensemble.sh` | `receptor_prep` | `scripts/rec/0_prep.sh` via `STAGE_SCRIPT_MAP`; full manual chain in `WORKFLOW.md` includes `1_pr_rec.sh`, `3_ana.sh`, `4_cluster.sh`, `5_align.py` | `[receptor] input_pdb, ff, water_model, mdp_dir, n_trials, ensemble_size, align_reference` |
| 2: Docking (targeted) | Gnina ensemble docking around ref ligand | `aedmd-dock-run` | `scripts/commands/aedmd-dock-run.sh` | `docking_run` | `scripts/dock/2_gnina.sh` via map; supporting prep/report scripts in workflow doc | `[docking] mode=targeted, reference_ligand, receptor_dir, ligand_pattern, autobox_ligand, autobox_add` |
| 3: Complex setup | Convert docked pose to MD-ready complex (AMBER branch) | `aedmd-com-setup` | `scripts/commands/aedmd-com-setup.sh` | `complex_prep` | `scripts/com/0_prep.sh` via map; plus `dock2com` scripts in manual chain | `[dock2com] ff=amber, rec_top`; `[complex] mode=amber, receptor_gro, receptor_top` |
| 4: MD simulation | Equilibration + production for each ligand/trial | `aedmd-com-md` | `scripts/commands/aedmd-com-md.sh` | `complex_md` | `scripts/com/1_pr_prod.sh` | `[production] n_trials, n_equilibration_stages, pr0_mdp, production_mdp` |
| 5: MM/PBSA | Chunked binding-energy calculations | `aedmd-com-mmpbsa` | `scripts/commands/aedmd-com-mmpbsa.sh` | `complex_mmpbsa` | `scripts/com/2_run_mmpbsa.sh` (orchestrates `2_trj4mmpbsa.sh`, `2_sub_mmpbsa.sh`, `2_mmpbsa.sh`) | `[mmpbsa] amber_topology_file, group_ids_file, source_xtc_pattern, source_tpr_pattern` |
| 6: Analysis | RMSD/RMSF/H-bond/contact summaries | `aedmd-com-analyze` | `scripts/commands/aedmd-com-analyze.sh` | `complex_analysis` | `scripts/com/3_ana.sh` (+ optional fingerprint/archive utilities) | `[analysis] run_rmsd, run_rmsf, run_hbond, run_advanced, contact_cutoff` |

---

## 4) Required Config.ini Sections and Targeted-Mode Keys

| Section | Required keys for this dry-run mapping | Why required |
|---|---|---|
| `[general]` | `workdir` | Defines workspace root for rec/dock/com stages |
| `[receptor]` | `input_pdb`, `ff`, `water_model`, `mdp_dir`, `n_trials`, `ensemble_size`, `align_reference` | Stage 1 setup and ensemble generation |
| `[dock]` | `ligand_dir`, `output_dir`, `gro_pattern`, `converter_script` | Ligand format conversion helpers |
| `[docking]` | `mode=targeted`, `reference_ligand`, `receptor_dir`, `ligand_pattern`, `autobox_ligand`, `autobox_add` | Stage 2 targeted gnina behavior |
| `[dock2com]` | `ff`, `rec_top`, `ligand_itp_pattern`, `sdf_pattern` | Docked-pose to complex topology preparation |
| `[complex]` | `mode=amber`, `receptor_gro`, `receptor_top`, `ff_include`, `mdp_dir`, `solvent_coordinates` | MD-ready complex assembly |
| `[production]` | `n_trials`, `n_equilibration_stages`, `pr0_mdp`, `pr_mdp_prefix`, `production_mdp` | Stage 4 simulation protocol |
| `[mmpbsa]` | `amber_topology_file`, `group_ids_file`, `n_chunks`, `source_xtc_pattern`, `source_tpr_pattern` | Stage 5 energy calculations |
| `[analysis]` | `run_rmsd`, `run_rmsf`, `run_hbond`, `run_advanced`, `contact_cutoff` | Stage 6 output generation |

---

## 5) Agent Skill → Wrapper → Script/Handoff Chain

### Generic call path

1. User invokes slash command (e.g., `/aedmd-dock-run`).
2. Wrapper script `scripts/commands/aedmd-*.sh` sources `common.sh`.
3. Wrapper calls `dispatch_agent "<role>" "<stage-token>"`.
4. `dispatch_agent` writes `.handoffs/<stage>.json` and runs `python -m scripts.agents ...`.
5. For runner/analyzer, `resolve_stage_script` maps token via `STAGE_SCRIPT_MAP`.
6. Wrapper calls `check_handoff_result <stage>`.
7. Status handling in `check_handoff_result`:
   - `success` → exit 0
   - `needs_review` → warnings + exit 2
   - `failure|blocked` → errors/recommendations + exit 1

### Concrete mapping table

| Skill | Wrapper | dispatch_agent args | STAGE_SCRIPT_MAP target | Handoff file |
|---|---|---|---|---|
| `aedmd-rec-ensemble` | `aedmd-rec-ensemble.sh` | `("runner", "receptor_prep")` | `scripts/rec/0_prep.sh` | `.handoffs/receptor_prep.json` |
| `aedmd-dock-run` | `aedmd-dock-run.sh` | `("runner", "docking_run")` | `scripts/dock/2_gnina.sh` | `.handoffs/docking_run.json` |
| `aedmd-com-setup` | `aedmd-com-setup.sh` | `("runner", "complex_prep")` | `scripts/com/0_prep.sh` | `.handoffs/complex_prep.json` |
| `aedmd-com-md` | `aedmd-com-md.sh` | `("runner", "complex_md")` | `scripts/com/1_pr_prod.sh` | `.handoffs/complex_md.json` |
| `aedmd-com-mmpbsa` | `aedmd-com-mmpbsa.sh` | `("runner", "complex_mmpbsa")` | `scripts/com/2_run_mmpbsa.sh` | `.handoffs/complex_mmpbsa.json` |
| `aedmd-com-analyze` | `aedmd-com-analyze.sh` | `("analyzer", "complex_analysis")` | `scripts/com/3_ana.sh` | `.handoffs/complex_analysis.json` |

---

## 6) Key Link Validation (Plan must-have links)

| Required link | Evidence in repo | Status |
|---|---|---|
| `WORKFLOW.md Stage 2` → `aedmd-dock-run` via targeted mode | `WORKFLOW.md` Stage 2 lists targeted mode with `reference_ligand`; `aedmd-dock-run/SKILL.md` states `blind/targeted/test`; `scripts/dock/2_gnina.sh` validates `mode=targeted` | ✅ linked |
| `work/input/ref.pdb` → `[docking] reference_ligand` | `work/input/README.md` defines `ref.pdb` as reference ligand; `scripts/config.ini.template` has `[docking] reference_ligand`; `2_gnina.sh` requires reference ligand in targeted/test | ✅ linked |

---

## 7) Dependencies and Checkpoints (User Perspective)

| Stage | Must exist before stage | Produces for next stage |
|---|---|---|
| 0 | Valid `config.ini`, copied workspace files | usable stage config and path resolution |
| 1 | receptor input PDB + FF + MDP | receptor conformers/coords for docking |
| 2 | receptor conformers + ligand inputs + `ref.pdb` (targeted) | ranked docked poses |
| 3 | selected poses + receptor topology + ligand topology | `com.gro`, `sys.top`, `index.ndx` |
| 4 | prepared complex directories + production MDPs | `prod_*.xtc`/`prod_*.tpr` |
| 5 | production trajectories + group IDs/topology | MM/PBSA result artifacts |
| 6 | trajectories (+ optional MM/PBSA) | final analysis summaries/plots |

---

## 8) Known Ambiguities to Carry into Audit/Report

1. `work/input/2bxo.pdb` purpose is not explicitly documented in workflow narrative.
2. Agent wrappers map only one script per stage token; manual pipeline includes multi-script stage chains.
3. Targeted mode distinction between `reference_ligand` and `autobox_ligand` is script-level clear, but not fully explicit in all user-facing docs.

---

## 9) Dry-Run Compliance Statement

- No pipeline script execution was performed.
- Mapping is based on static inspection of docs, wrappers, config template, and script code paths.
