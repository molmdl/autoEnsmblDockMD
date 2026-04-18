#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../infra/common.sh"

SCRIPT_NAME="4_cluster"
CONFIG_FILE=""

usage() {
    cat <<'USAGE'
Usage: 4_cluster.sh [--config FILE] [--help]

Run GROMOS clustering and extract receptor ensemble structures.

Config sections/keys:
  [receptor]
    workdir, cluster_method, cluster_xtc, cluster_tpr, cluster_cutoff,
    cluster_rmsmin, cluster_group, ensemble_size, cluster_output,
    ensemble_prefix, write_pdb
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
CLUSTER_METHOD="$(get_config receptor cluster_method gromos)"
CLUSTER_XTC="$(get_config receptor cluster_xtc apo_50ns_merged_fit.xtc)"
CLUSTER_TPR="$(get_config receptor cluster_tpr pr_0.tpr)"
CLUSTER_CUTOFF="$(get_config receptor cluster_cutoff 0.2)"
CLUSTER_RMSMIN="$(get_config receptor cluster_rmsmin 0.1)"
CLUSTER_GROUP="$(get_config receptor cluster_group 1)"
ENSEMBLE_SIZE="$(get_config receptor ensemble_size 10)"
CLUSTER_OUTPUT="$(get_config receptor cluster_output clusters.xtc)"
ENSEMBLE_PREFIX="$(get_config receptor ensemble_prefix rec)"
WRITE_PDB="$(get_config receptor write_pdb true)"

require_dir "$WORKDIR" "Receptor workdir not found: $WORKDIR"
cd "$WORKDIR"

require_file "$CLUSTER_XTC" "Missing merged trajectory for clustering: $CLUSTER_XTC"
require_file "$CLUSTER_TPR" "Missing TPR for clustering: $CLUSTER_TPR"

if [[ "$ENSEMBLE_SIZE" -lt 1 ]]; then
    log_error "ensemble_size must be >= 1 (got: ${ENSEMBLE_SIZE})"
    exit 1
fi

run_gmx cluster -method "$CLUSTER_METHOD" -f "$CLUSTER_XTC" -s "$CLUSTER_TPR" -rmsmin "$CLUSTER_RMSMIN" -cutoff "$CLUSTER_CUTOFF" -sz -clid -cl "$CLUSTER_OUTPUT" <<< "$CLUSTER_GROUP $CLUSTER_GROUP"
run_gmx trjconv -s "$CLUSTER_TPR" -f "$CLUSTER_OUTPUT" -sep -pbc mol -o "${ENSEMBLE_PREFIX}.gro" <<< "$CLUSTER_GROUP"

for ((i=0; i<ENSEMBLE_SIZE; i++)); do
    require_file "${ENSEMBLE_PREFIX}${i}.gro" "Expected clustered conformation missing: ${ENSEMBLE_PREFIX}${i}.gro"
    if [[ "$WRITE_PDB" == "true" ]]; then
        run_gmx editconf -f "${ENSEMBLE_PREFIX}${i}.gro" -o "${ENSEMBLE_PREFIX}${i}.pdb"
    fi
done

log_info "Generated ${ENSEMBLE_SIZE} receptor ensemble conformations (${ENSEMBLE_PREFIX}0..${ENSEMBLE_PREFIX}$((ENSEMBLE_SIZE - 1)))"
