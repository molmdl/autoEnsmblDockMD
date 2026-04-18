#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../infra/common.sh"

SCRIPT_NAME="2_run_mmpbsa"
CONFIG_FILE=""
LIGAND_OVERRIDE=""

usage() {
    cat <<'EOF'
Usage: 2_run_mmpbsa.sh [--config FILE] [--ligand NAME|PATH] [--help]

Unified MM/PBSA workflow entrypoint:
1) Prepare trajectories and chunk workdirs via 2_trj4mmpbsa.sh
2) Submit MM/PBSA Slurm arrays via 2_sub_mmpbsa.sh

Options:
  --config FILE          INI config file
  --ligand NAME|PATH     Run one ligand only
  -h, --help             Show this help and exit

Config keys used:
  [mmpbsa]
    trj_script
    submit_script
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --config)
            [[ $# -ge 2 ]] || { log_error "--config requires a file path"; exit 1; }
            CONFIG_FILE="$2"
            shift 2
            ;;
        --ligand)
            [[ $# -ge 2 ]] || { log_error "--ligand requires a value"; exit 1; }
            LIGAND_OVERRIDE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

init_script "${SCRIPT_NAME}" "${CONFIG_FILE}"

TRJ_SCRIPT="$(get_config mmpbsa trj_script "${SCRIPT_DIR}/2_trj4mmpbsa.sh")"
SUBMIT_SCRIPT="$(get_config mmpbsa submit_script "${SCRIPT_DIR}/2_sub_mmpbsa.sh")"

require_file "${TRJ_SCRIPT}" "Trajectory preparation script not found: ${TRJ_SCRIPT}"
require_file "${SUBMIT_SCRIPT}" "MM/PBSA submit script not found: ${SUBMIT_SCRIPT}"

CMD_ARGS=()
if [[ -n "${CONFIG_FILE}" ]]; then
    CMD_ARGS+=(--config "${CONFIG_FILE}")
fi
if [[ -n "${LIGAND_OVERRIDE}" ]]; then
    CMD_ARGS+=(--ligand "${LIGAND_OVERRIDE}")
fi

log_info "Preparing trajectories for MM/PBSA"
bash "${TRJ_SCRIPT}" "${CMD_ARGS[@]}"

log_info "Submitting MM/PBSA Slurm arrays"
bash "${SUBMIT_SCRIPT}" "${CMD_ARGS[@]}"

log_info "MM/PBSA workflow orchestration complete"
