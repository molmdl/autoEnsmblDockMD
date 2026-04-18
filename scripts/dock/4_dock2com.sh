#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../infra/common.sh"

print_help() {
    cat <<'EOF'
Usage: 4_dock2com.sh [options]

Prepare MD-ready complex topology for docked (new) ligands.
For each selected ligand, this wrapper runs:
  1) 4_dock2com_1.py   (select/convert docking pose SDF -> GRO)
  2) 4_dock2com_2.py   (build system topology)
  3) 4_dock2com_2.2.1.py (generate ligand position restraints)

Options:
  --config <path>         Config file path (default: config.ini)
  --workdir <path>        Override [general] workdir
  --dock-dir <path>       Override docking directory containing ligand folders
  --com-dir <path>        Override complex output directory
  --ligand-list "a,b,c"   Explicit ligand IDs to process
  --pose-index <N>        Override pose index passed to 4_dock2com_1.py
  --ff <amber|charmm>     Override force-field mode passed to 4_dock2com_2.py
  --dry-run               Resolve inputs and print actions without executing
  -h, --help              Show this help message

Config keys used:
  [general] workdir
  [docking] dock_dir
  [docking] ligand_list
  [docking] ligand_pattern
  [dock2com] com_dir
  [dock2com] ff
  [dock2com] pose_index
  [dock2com] force_constant
  [dock2com] rec_top
  [dock2com] ligand_itp_pattern
  [dock2com] ligand_template_pattern
  [dock2com] sdf_pattern
  [dock2com] copy_rec_itp
EOF
}

CONFIG_FILE="config.ini"
WORKDIR_OVERRIDE=""
DOCK_DIR_OVERRIDE=""
COM_DIR_OVERRIDE=""
LIGAND_LIST_OVERRIDE=""
POSE_INDEX_OVERRIDE=""
FF_OVERRIDE=""
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --workdir)
            WORKDIR_OVERRIDE="$2"
            shift 2
            ;;
        --dock-dir)
            DOCK_DIR_OVERRIDE="$2"
            shift 2
            ;;
        --com-dir)
            COM_DIR_OVERRIDE="$2"
            shift 2
            ;;
        --ligand-list)
            LIGAND_LIST_OVERRIDE="$2"
            shift 2
            ;;
        --pose-index)
            POSE_INDEX_OVERRIDE="$2"
            shift 2
            ;;
        --ff)
            FF_OVERRIDE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN="true"
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

init_script "4_dock2com.sh" "${CONFIG_FILE}"

require_cmd python

UTIL_SDF2GRO="${SCRIPT_DIR}/4_dock2com_1.py"
UTIL_TOPOLOGY="${SCRIPT_DIR}/4_dock2com_2.py"
UTIL_POSRE="${SCRIPT_DIR}/4_dock2com_2.2.1.py"

require_file "${UTIL_SDF2GRO}" "Missing Python utility: ${UTIL_SDF2GRO}"
require_file "${UTIL_TOPOLOGY}" "Missing Python utility: ${UTIL_TOPOLOGY}"
require_file "${UTIL_POSRE}" "Missing Python utility: ${UTIL_POSRE}"

WORKDIR="$(get_config general workdir "$(pwd)")"
if [[ -n "${WORKDIR_OVERRIDE}" ]]; then
    WORKDIR="${WORKDIR_OVERRIDE}"
fi

DOCK_DIR="$(get_config docking dock_dir "${WORKDIR}/dock")"
if [[ -n "${DOCK_DIR_OVERRIDE}" ]]; then
    DOCK_DIR="${DOCK_DIR_OVERRIDE}"
fi

COM_DIR="$(get_config dock2com com_dir "${WORKDIR}/com")"
if [[ -n "${COM_DIR_OVERRIDE}" ]]; then
    COM_DIR="${COM_DIR_OVERRIDE}"
fi

FF_MODE="$(get_config dock2com ff "amber")"
if [[ -n "${FF_OVERRIDE}" ]]; then
    FF_MODE="${FF_OVERRIDE}"
fi

POSE_INDEX="$(get_config dock2com pose_index "")"
if [[ -n "${POSE_INDEX_OVERRIDE}" ]]; then
    POSE_INDEX="${POSE_INDEX_OVERRIDE}"
fi

FORCE_CONSTANT="$(get_config dock2com force_constant "1000")"
REC_TOP="$(get_config dock2com rec_top "${WORKDIR}/rec/#topol.top.1#")"
LIG_ITP_PATTERN="$(get_config dock2com ligand_itp_pattern "{ligand}.itp")"
LIG_TEMPLATE_PATTERN="$(get_config dock2com ligand_template_pattern "{ligand}.mol2")"
SDF_PATTERN="$(get_config dock2com sdf_pattern "rec*-{ligand}.sdf")"
COPY_REC_ITP="$(get_config dock2com copy_rec_itp "true")"

render_pattern() {
    local pattern="$1"
    local ligand="$2"
    printf '%s\n' "${pattern//\{ligand\}/${ligand}}"
}

discover_ligands() {
    local explicit="$1"
    local -n out_ref="$2"
    local ligand_pattern token path base

    out_ref=()

    if [[ -n "${explicit}" ]]; then
        explicit="${explicit//,/ }"
        for token in ${explicit}; do
            out_ref+=("${token}")
        done
        return
    fi

    ligand_pattern="$(get_config docking ligand_pattern "lig*")"

    shopt -s nullglob
    local candidates=("${DOCK_DIR}"/${ligand_pattern})
    shopt -u nullglob

    for path in "${candidates[@]}"; do
        [[ -d "${path}" ]] || continue
        base="$(basename "${path}")"
        out_ref+=("${base}")
    done
}

find_first_match() {
    local pattern="$1"
    local match

    shopt -s nullglob
    local hits=(${pattern})
    shopt -u nullglob

    if [[ ${#hits[@]} -eq 0 ]]; then
        return 1
    fi

    printf '%s\n' "${hits[0]}"
}

ligand_list_cfg="$(get_config docking ligand_list "")"
if [[ -n "${LIGAND_LIST_OVERRIDE}" ]]; then
    ligand_list_cfg="${LIGAND_LIST_OVERRIDE}"
fi

declare -a LIGANDS=()
discover_ligands "${ligand_list_cfg}" LIGANDS

if [[ ${#LIGANDS[@]} -eq 0 ]]; then
    log_error "No ligand directories found in ${DOCK_DIR}. Provide --ligand-list or configure [docking] ligand_list."
    exit 1
fi

if [[ "${DRY_RUN}" == "true" ]]; then
    log_info "Mode: new ligand dock2com"
    log_info "Workdir: ${WORKDIR}"
    log_info "Dock dir: ${DOCK_DIR}"
    log_info "Complex dir: ${COM_DIR}"
    log_info "Force field mode: ${FF_MODE}"
    log_info "Ligands: ${LIGANDS[*]}"
    exit 0
fi

require_file "${REC_TOP}" "Receptor topology not found: ${REC_TOP}"
ensure_dir "${COM_DIR}"

for ligand_id in "${LIGANDS[@]}"; do
    ligand_dir="${DOCK_DIR}/${ligand_id}"
    require_dir "${ligand_dir}" "Ligand docking directory not found: ${ligand_dir}"

    sdf_glob="${ligand_dir}/$(render_pattern "${SDF_PATTERN}" "${ligand_id}")"
    if ! selected_sdf="$(find_first_match "${sdf_glob}")"; then
        log_error "No docking SDF matches '${sdf_glob}' for ligand ${ligand_id}"
        exit 1
    fi

    itp_path="${ligand_dir}/$(render_pattern "${LIG_ITP_PATTERN}" "${ligand_id}")"
    if [[ ! -f "${itp_path}" && -f "${ligand_dir}/lig.itp" ]]; then
        itp_path="${ligand_dir}/lig.itp"
    fi
    require_file "${itp_path}" "Ligand ITP not found for ${ligand_id}: ${itp_path}"

    template_path="${ligand_dir}/$(render_pattern "${LIG_TEMPLATE_PATTERN}" "${ligand_id}")"
    if [[ ! -f "${template_path}" ]]; then
        if alt_template="$(find_first_match "${ligand_dir}/*.mol2")"; then
            template_path="${alt_template}"
        fi
    fi
    require_file "${template_path}" "Ligand MOL2 template not found for ${ligand_id}: ${template_path}"

    lig_gro="${ligand_dir}/best.gro"
    com_gro="${ligand_dir}/com.gro"
    rec_itp="${ligand_dir}/rec.itp"
    sys_top="${ligand_dir}/sys.top"
    posre_lig="${ligand_dir}/posre_lig.itp"

    log_info "[${ligand_id}] SDF->GRO: ${selected_sdf}"
    pose_args=()
    if [[ -n "${POSE_INDEX}" ]]; then
        pose_args+=(--pose-index "${POSE_INDEX}")
    fi
    python "${UTIL_SDF2GRO}" --sdf "${selected_sdf}" --output "${lig_gro}" "${pose_args[@]}" --config "${CONFIG_FILE}"

    log_info "[${ligand_id}] Build topology"
    python "${UTIL_TOPOLOGY}" --receptor-top "${REC_TOP}" --ligand-itp "${itp_path}" --output-top "${sys_top}" --ff "${FF_MODE}" --config "${CONFIG_FILE}"

    if [[ ! -f "${com_gro}" && -f "${ligand_dir}/complex.gro" ]]; then
        com_gro="${ligand_dir}/complex.gro"
    fi
    require_file "${sys_top}" "System topology was not generated: ${sys_top}"
    require_file "${com_gro}" "Complex GRO was not generated: ${com_gro}"

    log_info "[${ligand_id}] Generate ligand position restraints"
    python "${UTIL_POSRE}" --gro "${lig_gro}" --force-constant "${FORCE_CONSTANT}" --output "${posre_lig}"
    require_file "${posre_lig}" "Ligand position restraints were not generated: ${posre_lig}"

    out_dir="${COM_DIR}/${ligand_id}"
    ensure_dir "${out_dir}"
    cp -f "${sys_top}" "${out_dir}/sys.top"
    cp -f "${com_gro}" "${out_dir}/complex.gro"
    cp -f "${posre_lig}" "${out_dir}/posre_lig.itp"

    if [[ "${COPY_REC_ITP,,}" == "true" || "${COPY_REC_ITP}" == "1" ]]; then
        if [[ -f "${rec_itp}" ]]; then
            cp -f "${rec_itp}" "${out_dir}/rec.itp"
        fi
    fi

    cp -f "${lig_gro}" "${out_dir}/best.gro"
    cp -f "${itp_path}" "${out_dir}/$(basename "${itp_path}")"

    log_info "[${ligand_id}] Completed -> ${out_dir}"
done

log_info "Dock-to-complex conversion completed for ${#LIGANDS[@]} ligands"
