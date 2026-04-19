# Troubleshooting (HPC + Async Pipeline Execution)

This guide focuses on the most common operational pitfall in `autoEnsmblDockMD`: **assuming stage completion when a stage has only submitted jobs**.

## 1) Understand async stages first

In Slurm-backed runs, several stages submit jobs and return immediately.

Common async submission stages:

- `rec_prod` (`scripts/rec/1_pr_rec.sh`)
- `com_prep` (`scripts/com/0_prep.sh`, depending on branch/resources)
- `com_prod` (`scripts/com/1_pr_prod.sh`)
- `com_mmpbsa` (`scripts/com/2_run_mmpbsa.sh` via `2_sub_mmpbsa.sh`)

Return from `scripts/run_pipeline.sh` or stage scripts may mean **submission succeeded**, not that downstream artifacts are ready.

## 2) Minimal scheduler check workflow

After any async stage:

1. Capture job ID(s) from script output (`Submitted batch job <id>`).
2. Check live queue:

```bash
squeue -u "$USER"
```

3. Check final status/details:

```bash
sacct -j <jobid> --format=JobID,State,Elapsed,ExitCode
```

4. Only proceed when required jobs show terminal success (`COMPLETED`) and expected stage artifacts exist.

## 3) Stage-ready file checks (quick checklist)

Use these before launching dependent stages:

- Before `rec_ana`/`rec_cluster`: receptor trial outputs from `rec_prod` are present.
- Before `com_prod`: per-ligand prep outputs such as `pr_pos.gro`, `sys.top`, `index.ndx` exist.
- Before `com_mmpbsa`: per-ligand production files `prod_*.xtc` and `prod_*.tpr` exist.
- Before interpreting MM/PBSA: chunk outputs (for configured chunk count) are complete.

## 4) Common HPC pitfalls and fixes

| Symptom | Likely cause | What to check | Fix |
|---|---|---|---|
| Next stage fails on missing files | Stage was submitted, not completed | `squeue`, `sacct`, artifact presence | Wait for completion; rerun stage if failed |
| Jobs stay pending | Partition/resource mismatch | Requested partition/CPU/GPU and cluster policy | Adjust `[slurm]`, `[production]`, or `[mmpbsa]` resource keys |
| `COMPLETED` missing in array subsets | Partial array failures | `sacct -j <jobid>` for child tasks | Resubmit failed tasks only (use rerun helper if configured) |
| MM/PBSA results incomplete | Chunk jobs still running/failed | `mmpbsa_*` directories + scheduler history | Re-run failed chunk submissions; confirm `group_ids_file` consistency |
| Status looks stale | Wrong workspace/config target | `aedmd-status --workdir ... --config ...` | Point commands to correct workspace root/config |

## 5) Useful commands

```bash
# Workspace snapshot
bash scripts/commands/aedmd-status.sh --workdir work/my_project --config work/my_project/config.ini

# List available dispatcher stages
bash scripts/run_pipeline.sh --config work/my_project/config.ini --list-stages
```
