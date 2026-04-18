#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../infra/common.sh"

SCRIPT_NAME="3_ana"
CONFIG_FILE=""
LIGAND_OVERRIDE=""

usage() {
    cat <<'EOF'
Usage: 3_ana.sh [--config FILE] [--ligand NAME|PATH] [--help]

Run complex MD trajectory analysis (GROMACS + MDAnalysis):
  - RMSD (gmx rms)
  - RMSF (gmx rmsf)
  - Hydrogen bonds (gmx hbond)
  - Advanced analysis/plots (python 3_com_ana_trj.py)

Options:
  --config FILE          INI config file
  --ligand NAME|PATH     Analyze one ligand only
  -h, --help             Show this help and exit

Config keys used:
  [general] workdir
  [complex] workdir
  [analysis] output_subdir
  [analysis] run_rmsd
  [analysis] run_rmsf
  [analysis] run_hbond
  [analysis] run_advanced
  [analysis] plot_format
  [analysis] plot_dpi
  [analysis] contact_cutoff
  [analysis] selections
  [analysis] ligand_list
  [analysis] gmx_rmsd_ref_group
  [analysis] gmx_rmsd_mobile_group
  [analysis] gmx_rmsf_group
  [analysis] gmx_hbond_group_a
  [analysis] gmx_hbond_group_b
EOF
}

is_true() {
    local value="${1:-}"
    value="${value,,}"
    [[ "${value}" == "1" || "${value}" == "true" || "${value}" == "yes" || "${value}" == "on" ]]
}

resolve_targets() {
    local explicit="$1"
    local base_dir="$2"
    local -n _targets_ref="$3"
    _targets_ref=()

    if [[ -n "${explicit}" ]]; then
        explicit="${explicit//,/ }"
        local token
        for token in ${explicit}; do
            if [[ -d "${token}" ]]; then
                _targets_ref+=("$(realpath "${token}")")
            elif [[ -d "${base_dir}/${token}" ]]; then
                _targets_ref+=("$(realpath "${base_dir}/${token}")")
            else
                log_error "Ligand analysis target not found: ${token}"
                exit 1
            fi
        done
        return
    fi

    shopt -s nullglob
    local entries=("${base_dir}"/*)
    shopt -u nullglob
    local entry
    for entry in "${entries[@]}"; do
        [[ -d "${entry}" ]] || continue
        if [[ -f "${entry}/com.tpr" && -f "${entry}/com_traj.xtc" ]]; then
            _targets_ref+=("$(realpath "${entry}")")
        fi
    done
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

require_cmd python
require_cmd gmx

WORKDIR="$(get_config general workdir "$(pwd)")"
COMPLEX_WORKDIR="$(get_config complex workdir "${WORKDIR}/com")"
OUTPUT_SUBDIR="$(get_config analysis output_subdir "analysis")"

RUN_RMSD="$(get_config analysis run_rmsd "true")"
RUN_RMSF="$(get_config analysis run_rmsf "true")"
RUN_HBOND="$(get_config analysis run_hbond "true")"
RUN_ADVANCED="$(get_config analysis run_advanced "true")"

PLOT_FORMAT="$(get_config analysis plot_format "png")"
PLOT_DPI="$(get_config analysis plot_dpi "300")"
CONTACT_CUTOFF="$(get_config analysis contact_cutoff "4.5")"
SELECTIONS="$(get_config analysis selections "")"
RMSD_REF_GROUP="$(get_config analysis gmx_rmsd_ref_group "4")"
RMSD_MOBILE_GROUP="$(get_config analysis gmx_rmsd_mobile_group "4")"
RMSF_GROUP="$(get_config analysis gmx_rmsf_group "4")"
HBOND_GROUP_A="$(get_config analysis gmx_hbond_group_a "1")"
HBOND_GROUP_B="$(get_config analysis gmx_hbond_group_b "13")"

TARGET_OVERRIDE="${LIGAND_OVERRIDE}"
if [[ -z "${TARGET_OVERRIDE}" ]]; then
    TARGET_OVERRIDE="$(get_config analysis ligand_list "")"
fi

require_dir "${COMPLEX_WORKDIR}" "Complex directory not found: ${COMPLEX_WORKDIR}"

declare -a TARGETS=()
resolve_targets "${TARGET_OVERRIDE}" "${COMPLEX_WORKDIR}" TARGETS

if [[ ${#TARGETS[@]} -eq 0 ]]; then
    log_error "No analyzable complex directories found in ${COMPLEX_WORKDIR}"
    exit 1
fi

for target in "${TARGETS[@]}"; do
    ligand_name="$(basename "${target}")"
    log_info "Analyzing ligand: ${ligand_name}"

    require_file "${target}/com.tpr" "Missing topology for ${ligand_name}: ${target}/com.tpr"
    require_file "${target}/com_traj.xtc" "Missing trajectory for ${ligand_name}: ${target}/com_traj.xtc"

    out_dir="${target}/${OUTPUT_SUBDIR}"
    ensure_dir "${out_dir}"

    if is_true "${RUN_RMSD}"; then
        log_info "Running GROMACS RMSD for ${ligand_name}"
        (cd "${target}" && printf '%s\n%s\n' "${RMSD_REF_GROUP}" "${RMSD_MOBILE_GROUP}" | gmx rms -s com.tpr -f com_traj.xtc -o "${OUTPUT_SUBDIR}/rmsd_backbone_gmx.xvg")
    fi

    if is_true "${RUN_RMSF}"; then
        log_info "Running GROMACS RMSF for ${ligand_name}"
        (cd "${target}" && printf '%s\n' "${RMSF_GROUP}" | gmx rmsf -s com.tpr -f com_traj.xtc -o "${OUTPUT_SUBDIR}/rmsf_backbone_gmx.xvg" -res)
    fi

    if is_true "${RUN_HBOND}"; then
        log_info "Running GROMACS hydrogen bond analysis for ${ligand_name}"
        (cd "${target}" && printf '%s\n%s\n' "${HBOND_GROUP_A}" "${HBOND_GROUP_B}" | gmx hbond -s com.tpr -f com_traj.xtc -num "${OUTPUT_SUBDIR}/hbond_count_gmx.xvg")
    fi

    if is_true "${RUN_ADVANCED}"; then
        log_info "Running MDAnalysis advanced analysis for ${ligand_name}"
        python "${SCRIPT_DIR}/3_com_ana_trj.py" \
            --trajectory "${target}/com_traj.xtc" \
            --topology "${target}/com.tpr" \
            --output-dir "${out_dir}" \
            --config "${CONFIG_FILE}" \
            --selections "${SELECTIONS}" \
            --plot-format "${PLOT_FORMAT}" \
            --dpi "${PLOT_DPI}" \
            --contact-cutoff "${CONTACT_CUTOFF}"
    fi

    log_info "Completed analysis for ${ligand_name}"
done

log_info "Trajectory analysis complete for ${#TARGETS[@]} complex(es)"
