#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../infra/common.sh"

print_help() {
    cat <<'EOF'
Usage: 1_rec4dock.sh [options]

Prepare receptor ensemble files for docking:
- copy or symlink receptor ensemble conformations into dock directory
- convert GRO receptor files to PDB when needed (gnina requires PDB)

Options:
  --config <path>      Config file path (default: config.ini)
  --dock-dir <path>    Override docking directory
  --rec-dir <path>     Override receptor ensemble source directory
  --ensemble-size <N>  Expected ensemble size; validates rec0..recN-1 when set
  --link               Symlink receptor files instead of copying
  --copy               Copy receptor files (default)
  -h, --help           Show this help message

Config keys used:
  [general] workdir
  [receptor] ensemble_dir
  [receptor] ensemble_size
  [receptor] receptor_prefix
  [receptor] receptor_ext
  [docking] dock_dir
  [docking] receptor_source_dir
  [docking] link_receptors
EOF
}

CONFIG_FILE="config.ini"
DOCK_DIR_OVERRIDE=""
REC_DIR_OVERRIDE=""
ENSEMBLE_SIZE_OVERRIDE=""
LINK_MODE="copy"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --dock-dir)
            DOCK_DIR_OVERRIDE="$2"
            shift 2
            ;;
        --rec-dir)
            REC_DIR_OVERRIDE="$2"
            shift 2
            ;;
        --ensemble-size)
            ENSEMBLE_SIZE_OVERRIDE="$2"
            shift 2
            ;;
        --link)
            LINK_MODE="link"
            shift
            ;;
        --copy)
            LINK_MODE="copy"
            shift
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            print_help
            exit 1
            ;;
    esac
done

init_script "1_rec4dock.sh" "${CONFIG_FILE}"

WORKDIR="$(get_config general workdir "$(pwd)")"
RECEPTOR_PREFIX="$(get_config receptor receptor_prefix "rec")"
RECEPTOR_EXT="$(get_config receptor receptor_ext "")"

REC_DIR_DEFAULT="${WORKDIR}/rec"
REC_DIR="$(get_config receptor ensemble_dir "${REC_DIR_DEFAULT}")"
REC_DIR="$(get_config docking receptor_source_dir "${REC_DIR}")"

DOCK_DIR_DEFAULT="${WORKDIR}/dock"
DOCK_DIR="$(get_config docking dock_dir "${DOCK_DIR_DEFAULT}")"

if [[ -n "${REC_DIR_OVERRIDE}" ]]; then
    REC_DIR="${REC_DIR_OVERRIDE}"
fi
if [[ -n "${DOCK_DIR_OVERRIDE}" ]]; then
    DOCK_DIR="${DOCK_DIR_OVERRIDE}"
fi

ENSEMBLE_SIZE="$(get_config receptor ensemble_size "")"
if [[ -n "${ENSEMBLE_SIZE_OVERRIDE}" ]]; then
    ENSEMBLE_SIZE="${ENSEMBLE_SIZE_OVERRIDE}"
fi

if [[ "${LINK_MODE}" == "copy" ]]; then
    LINK_CFG="$(get_config docking link_receptors "false")"
    if [[ "${LINK_CFG,,}" == "true" || "${LINK_CFG}" == "1" ]]; then
        LINK_MODE="link"
    fi
fi

require_dir "${REC_DIR}" "Receptor ensemble directory not found: ${REC_DIR}"
ensure_dir "${DOCK_DIR}"

collect_receptors() {
    local -n _out="$1"
    local idx
    local candidate

    _out=()

    if [[ -n "${ENSEMBLE_SIZE}" ]]; then
        for (( idx=0; idx<ENSEMBLE_SIZE; idx++ )); do
            if [[ -n "${RECEPTOR_EXT}" ]]; then
                candidate="${REC_DIR}/${RECEPTOR_PREFIX}${idx}.${RECEPTOR_EXT}"
                [[ -f "${candidate}" ]] && _out+=("${candidate}")
            else
                [[ -f "${REC_DIR}/${RECEPTOR_PREFIX}${idx}.pdb" ]] && _out+=("${REC_DIR}/${RECEPTOR_PREFIX}${idx}.pdb")
                [[ -f "${REC_DIR}/${RECEPTOR_PREFIX}${idx}.gro" ]] && _out+=("${REC_DIR}/${RECEPTOR_PREFIX}${idx}.gro")
            fi
        done
        return
    fi

    shopt -s nullglob
    local pdbs=("${REC_DIR}/${RECEPTOR_PREFIX}"*.pdb)
    local gros=("${REC_DIR}/${RECEPTOR_PREFIX}"*.gro)
    shopt -u nullglob
    _out=("${pdbs[@]}" "${gros[@]}")
}

convert_gro_to_pdb() {
    local gro_file="$1"
    local out_pdb="$2"
    run_gmx editconf -f "${gro_file}" -o "${out_pdb}" >/dev/null
}

declare -a receptor_files=()
collect_receptors receptor_files

if [[ ${#receptor_files[@]} -eq 0 ]]; then
    log_error "No receptor ensemble files found in ${REC_DIR}"
    exit 1
fi

log_info "Preparing ${#receptor_files[@]} receptor files into ${DOCK_DIR} (${LINK_MODE})"

for src in "${receptor_files[@]}"; do
    base="$(basename "${src}")"
    dest="${DOCK_DIR}/${base}"

    if [[ "${LINK_MODE}" == "link" ]]; then
        ln -snf "${src}" "${dest}"
    else
        cp -f "${src}" "${dest}"
    fi

    if [[ "${dest##*.}" == "gro" ]]; then
        pdb_dest="${DOCK_DIR}/${base%.gro}.pdb"
        log_info "Converting ${dest} -> ${pdb_dest}"
        convert_gro_to_pdb "${dest}" "${pdb_dest}"
    fi
done

log_info "Receptor docking preparation complete"
