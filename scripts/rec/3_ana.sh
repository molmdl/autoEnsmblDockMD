#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../infra/common.sh"

SCRIPT_NAME="3_ana"
CONFIG_FILE=""

usage() {
    cat <<'USAGE'
Usage: 3_ana.sh [--config FILE] [--help]

Convert trajectories and run RMSD/RMSF analyses for receptor MD trials.

Config sections/keys:
  [receptor]
    workdir, n_trials, analysis_start_ps, pbc_center_group, fit_group,
    rms_group, rmsf_group_bb, rmsf_group_noh, merged_fit_group, merged_out,
    merged_fit_out
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --config)
            [[ $# -ge 2 ]] || { log_error "--config requires a file path"; exit 1; }
            CONFIG_FILE="$2"
            shift 2
            ;;
        *)
            log_error "Unknown argument: $1"
            usage
            exit 1
            ;;
    esac
done

init_script "$SCRIPT_NAME" "$CONFIG_FILE"

WORKDIR="$(get_config receptor workdir rec)"
N_TRIALS="$(get_config receptor n_trials 4)"
ANALYSIS_START_PS="$(get_config receptor analysis_start_ps 10000)"
PBC_CENTER_GROUP="$(get_config receptor pbc_center_group 1)"
FIT_GROUP="$(get_config receptor fit_group 4)"
RMS_GROUP="$(get_config receptor rms_group 4)"
RMSF_GROUP_BB="$(get_config receptor rmsf_group_bb 4)"
RMSF_GROUP_NOH="$(get_config receptor rmsf_group_noh 2)"
MERGED_FIT_GROUP="$(get_config receptor merged_fit_group 1)"
MERGED_OUT="$(get_config receptor merged_out apo_50ns_merged.xtc)"
MERGED_FIT_OUT="$(get_config receptor merged_fit_out apo_50ns_merged_fit.xtc)"

require_dir "$WORKDIR" "Receptor workdir not found: $WORKDIR"
cd "$WORKDIR"

if [[ "$N_TRIALS" -lt 1 ]]; then
    log_error "n_trials must be >= 1 (got: ${N_TRIALS})"
    exit 1
fi

trial_xtcs=()
for ((i=0; i<N_TRIALS; i++)); do
    require_file "pr_${i}.xtc" "Missing trajectory file: pr_${i}.xtc"
    require_file "pr_${i}.tpr" "Missing run topology: pr_${i}.tpr"

    pbcmol_out="pbcmol_${i}.xtc"
    trial_xtc="apo_50ns_${i}_pbc.xtc"

    run_gmx trjconv -f "pr_${i}.xtc" -s "pr_${i}.tpr" -pbc mol -center -o "$pbcmol_out" -b "$ANALYSIS_START_PS" -ur compact <<< "$PBC_CENTER_GROUP $PBC_CENTER_GROUP"
    run_gmx trjconv -f "$pbcmol_out" -s "pr_${i}.tpr" -fit rot+trans -o "$trial_xtc" <<< "$FIT_GROUP $PBC_CENTER_GROUP"
    run_gmx trjconv -s "pr_${i}.tpr" -dump 0 -f "$trial_xtc" -o "apo_50ns_${i}_pbc_0.pdb" <<< "$PBC_CENTER_GROUP"

    run_gmx rms -f "$trial_xtc" -s "pr_${i}.tpr" -o "apo_50ns_${i}_bb.rmsd" <<< "$RMS_GROUP $RMS_GROUP"
    run_gmx rmsf -s "pr_${i}.tpr" -f "$trial_xtc" -oq "apo50ns_${i}_rmsf_bfac.pdb" -o "apo50ns_${i}_bb_rmsf.xvg" -res -dir "apo50ns_${i}_bb_rmsf.log" -oc "apo50ns_${i}_bb_rmsf.xvg" <<< "$RMSF_GROUP_BB $RMSF_GROUP_BB"
    run_gmx rmsf -s "pr_${i}.tpr" -f "$trial_xtc" -oq "apo50ns_${i}_rmsf_noh_bfac.pdb" -o "apo50ns_${i}_noh_rmsf.xvg" -res -dir "apo50ns_${i}_noh_rmsf.log" -oc "apo50ns_${i}_noh_rmsf.xvg" <<< "$RMSF_GROUP_BB $RMSF_GROUP_NOH"

    rm -f "$pbcmol_out"
    trial_xtcs+=("$trial_xtc")
done

run_gmx trjcat -f "${trial_xtcs[@]}" -o "$MERGED_OUT" -cat
run_gmx rms -f "$MERGED_OUT" -s "pr_0.tpr" -o "apo_50ns_merged_bb.rmsd" <<< "$RMS_GROUP $RMS_GROUP"
run_gmx rmsf -s "pr_0.tpr" -f "$MERGED_OUT" -oq "apo50ns_merged_rmsf_bfac.pdb" -o "apo50ns_merged_bb_rmsf.xvg" -res -dir "apo50ns_merged_bb_rmsf.log" -oc "apo50ns_merged_bb_rmsf.xvg" <<< "$RMSF_GROUP_BB $RMSF_GROUP_BB"
run_gmx rmsf -s "pr_0.tpr" -f "$MERGED_OUT" -oq "apo50ns_merged_rmsf_noh_bfac.pdb" -o "apo50ns_merged_noh_rmsf.xvg" -res -dir "apo50ns_merged_noh_rmsf.log" -oc "apo50ns_merged_noh_rmsf.xvg" <<< "$RMSF_GROUP_BB $RMSF_GROUP_NOH"
run_gmx trjconv -f "$MERGED_OUT" -s "pr_0.tpr" -fit rot+trans -o "$MERGED_FIT_OUT" <<< "$RMS_GROUP $MERGED_FIT_GROUP"

rm -f "$MERGED_OUT"
log_info "Receptor trajectory analysis complete"
