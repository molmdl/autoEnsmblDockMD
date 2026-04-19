#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../infra/common.sh"

SCRIPT_NAME="5_arc_sel"
CONFIG_FILE=""
LIGAND_OVERRIDE=""

usage() {
    cat <<'EOF'
Usage: 5_arc_sel.sh [--config FILE] [--ligand NAME|PATH] [--help]

Archive selected ligand result files into per-ligand tarballs.

Options:
  --config FILE          INI config file
  --ligand NAME|PATH     Limit to specific ligand(s), comma-separated
  -h, --help             Show this help and exit

Config keys used:
  [general]
    workdir
  [complex]
    workdir
    ligand_pattern
  [archive]
    workdir
    ligand_dir
    ligand_pattern
    ligand_list
    archive_dir
    include_patterns
    dry_run
    compress_level
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
require_cmd tar

WORKDIR="$(get_config general workdir "$(pwd)")"
COMPLEX_WORKDIR="$(get_config complex workdir "${WORKDIR}/com")"
ARCHIVE_WORKDIR="$(get_config archive workdir "${COMPLEX_WORKDIR}")"
LIGAND_DIR="$(get_config archive ligand_dir "${ARCHIVE_WORKDIR}")"
COMPLEX_LIGAND_PATTERN_DEFAULT="$(get_config complex ligand_pattern "lig*")"
LIGAND_PATTERN="$(get_config archive ligand_pattern "${COMPLEX_LIGAND_PATTERN_DEFAULT}")"
LIGAND_LIST_CFG="$(get_config archive ligand_list "")"
ARCHIVE_DIR="$(get_config archive archive_dir "${ARCHIVE_WORKDIR}/archive")"
INCLUDE_PATTERNS="$(get_config archive include_patterns "*.gro,*.xtc,*.xvg,mmpbsa_*/FINAL_RESULTS_MMPBSA.dat,mmpbsa_*/FINAL_RESULTS_MMPBSA.csv")"
DRY_RUN="$(get_config archive dry_run "false")"
COMPRESS_LEVEL="$(get_config archive compress_level "6")"

if [[ -n "${LIGAND_OVERRIDE}" ]]; then
    LIGAND_LIST_CFG="${LIGAND_OVERRIDE}"
fi

require_dir "${LIGAND_DIR}" "Archive ligand directory not found: ${LIGAND_DIR}"
ensure_dir "${ARCHIVE_DIR}"

discover_ligands() {
    local explicit="$1"
    local -n _targets_ref="$2"
    local token
    _targets_ref=()

    if [[ -n "${explicit}" ]]; then
        explicit="${explicit//,/ }"
        for token in ${explicit}; do
            if [[ -d "${token}" ]]; then
                _targets_ref+=("$(realpath "${token}")")
            elif [[ -d "${LIGAND_DIR}/${token}" ]]; then
                _targets_ref+=("$(realpath "${LIGAND_DIR}/${token}")")
            else
                log_error "Ligand target not found: ${token}"
                exit 1
            fi
        done
        return
    fi

    shopt -s nullglob
    local entries=("${LIGAND_DIR}/${LIGAND_PATTERN}")
    shopt -u nullglob

    for token in "${entries[@]}"; do
        [[ -d "${token}" ]] || continue
        _targets_ref+=("$(realpath "${token}")")
    done
}

is_true() {
    local v="${1,,}"
    [[ "${v}" == "1" || "${v}" == "true" || "${v}" == "yes" || "${v}" == "on" ]]
}

collect_files_for_ligand() {
    local lig_path="$1"
    local raw_patterns="$2"
    local token
    local -a files=()

    raw_patterns="${raw_patterns//,/ }"
    for token in ${raw_patterns}; do
        local matches=()
        shopt -s nullglob
        matches=("${lig_path}"/${token})
        shopt -u nullglob
        if [[ ${#matches[@]} -gt 0 ]]; then
            files+=("${matches[@]}")
        fi
    done

    if [[ ${#files[@]} -eq 0 ]]; then
        return 1
    fi

    printf '%s\n' "${files[@]}"
    return 0
}

declare -a TARGETS=()
discover_ligands "${LIGAND_LIST_CFG}" TARGETS

if [[ ${#TARGETS[@]} -eq 0 ]]; then
    log_error "No ligand directories discovered under ${LIGAND_DIR} (pattern: ${LIGAND_PATTERN})"
    exit 1
fi

for lig_path in "${TARGETS[@]}"; do
    lig_name="$(basename "${lig_path}")"
    archive_file="${ARCHIVE_DIR}/${lig_name}_results.tar.gz"

    mapfile -t files_to_archive < <(collect_files_for_ligand "${lig_path}" "${INCLUDE_PATTERNS}" || true)
    if [[ ${#files_to_archive[@]} -eq 0 ]]; then
        log_warn "No files matched archive patterns for ${lig_name}; skipping"
        continue
    fi

    if is_true "${DRY_RUN}"; then
        log_info "[DRY-RUN] ${lig_name} -> ${archive_file}"
        for f in "${files_to_archive[@]}"; do
            log_info "[DRY-RUN] include: ${f}"
        done
        continue
    fi

    rel_files=()
    for f in "${files_to_archive[@]}"; do
        rel_files+=("${f#${lig_path}/}")
    done

    pushd "${lig_path}" >/dev/null
    GZIP="-${COMPRESS_LEVEL}" tar -czf "${archive_file}" "${rel_files[@]}"
    popd >/dev/null

    log_info "Archived ${#rel_files[@]} file(s) for ${lig_name} -> ${archive_file}"
done

log_info "Archive selection workflow complete"
