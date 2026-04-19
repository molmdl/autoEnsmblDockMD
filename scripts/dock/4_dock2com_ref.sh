#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../infra/common.sh"

print_help() {
    cat <<'EOF'
Usage: 4_dock2com_ref.sh [options]

Prepare MD-ready complex topology for reference ligand workflows.
For each selected reference ligand, this wrapper runs:
  1) 4_dock2com_1.py   (select/convert reference docking SDF -> GRO)
  2) 4_dock2com_2.py   (build system topology)
  3) 4_dock2com_2.2.1.py (generate ligand position restraints)

Options:
  --config <path>         Config file path (default: config.ini)
  --workdir <path>        Override [general] workdir
  --dock-dir <path>       Override docking directory containing reference ligand folders
  --ref-dir <path>        Override reference ligand parameter directory
  --com-dir <path>        Override complex output directory (default: <workdir>/com/ref)
  --ligand-list "a,b,c"   Explicit reference ligand IDs to process
  --pose-index <N>        Override pose index passed to 4_dock2com_1.py
  --ff <amber|charmm>     Override force-field mode passed to 4_dock2com_2.py
  --dry-run               Resolve inputs and print actions without executing
  -h, --help              Show this help message

Config keys used:
  [general] workdir
  [docking] dock_dir
  [dock2com_ref] ref_dir
  [dock2com_ref] ligand_list
  [dock2com_ref] ligand_pattern
  [dock2com_ref] com_dir
  [dock2com_ref] ff
  [dock2com_ref] pose_index
  [dock2com_ref] force_constant
  [dock2com_ref] rec_top
  [dock2com_ref] ligand_itp_pattern
  [dock2com_ref] ligand_template_pattern
  [dock2com_ref] sdf_pattern
  [dock2com_ref] copy_rec_itp
EOF
}

CONFIG_FILE="config.ini"
WORKDIR_OVERRIDE=""
DOCK_DIR_OVERRIDE=""
REF_DIR_OVERRIDE=""
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
        --ref-dir)
            REF_DIR_OVERRIDE="$2"
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

init_script "4_dock2com_ref.sh" "${CONFIG_FILE}"

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

REF_DIR="$(get_config dock2com_ref ref_dir "${WORKDIR}/ref")"
if [[ -n "${REF_DIR_OVERRIDE}" ]]; then
    REF_DIR="${REF_DIR_OVERRIDE}"
fi

COM_DIR="$(get_config dock2com_ref com_dir "${WORKDIR}/com/ref")"
if [[ -n "${COM_DIR_OVERRIDE}" ]]; then
    COM_DIR="${COM_DIR_OVERRIDE}"
fi

FF_MODE="$(get_config dock2com_ref ff "amber")"
if [[ -n "${FF_OVERRIDE}" ]]; then
    FF_MODE="${FF_OVERRIDE}"
fi

POSE_INDEX="$(get_config dock2com_ref pose_index "")"
if [[ -n "${POSE_INDEX_OVERRIDE}" ]]; then
    POSE_INDEX="${POSE_INDEX_OVERRIDE}"
fi

FORCE_CONSTANT="$(get_config dock2com_ref force_constant "1000")"
REC_TOP="$(get_config dock2com_ref rec_top "${WORKDIR}/rec/#topol.top.1#")"
LIG_ITP_PATTERN="$(get_config dock2com_ref ligand_itp_pattern "{ligand}.itp")"
LIG_TEMPLATE_PATTERN="$(get_config dock2com_ref ligand_template_pattern "{ligand}.mol2")"
SDF_PATTERN="$(get_config dock2com_ref sdf_pattern "rec*-{ligand}.sdf")"
COPY_REC_ITP="$(get_config dock2com_ref copy_rec_itp "true")"

render_pattern() {
    local pattern="$1"
    local ligand="$2"
    printf '%s\n' "${pattern//\{ligand\}/${ligand}}"
}

discover_ref_ligands() {
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

    ligand_pattern="$(get_config dock2com_ref ligand_pattern "*")"

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

    shopt -s nullglob
    local hits=(${pattern})
    shopt -u nullglob

    if [[ ${#hits[@]} -eq 0 ]]; then
        return 1
    fi

    printf '%s\n' "${hits[0]}"
}

resolve_receptor_gro() {
    local sdf_path="$1"
    local ligand_dir="$2"
    local sdf_name stem prefix
    local -a candidates

    sdf_name="$(basename "${sdf_path}")"
    stem="${sdf_name%.*}"
    prefix="${stem%%-*}"

    candidates=(
        "${ligand_dir}/${prefix}.pdb_ali.gro"
        "${DOCK_DIR}/${prefix}.pdb_ali.gro"
        "${WORKDIR}/${prefix}.pdb_ali.gro"
        "${WORKDIR}/rec/${prefix}.pdb_ali.gro"
    )

    local candidate
    for candidate in "${candidates[@]}"; do
        if [[ -f "${candidate}" ]]; then
            printf '%s\n' "${candidate}"
            return 0
        fi
    done

    return 1
}

merge_complex_gro() {
    local rec_gro="$1"
    local lig_gro="$2"
    local out_gro="$3"

    local rec_atoms rec_extra lig_atoms lig_extra
    local rec_box_idx lig_box_idx total_atoms
    local rec_lines_count lig_lines_count
    local -a rec_lines lig_lines

    mapfile -t rec_lines < "${rec_gro}"
    mapfile -t lig_lines < "${lig_gro}"

    rec_lines_count=${#rec_lines[@]}
    lig_lines_count=${#lig_lines[@]}

    if (( rec_lines_count < 3 || lig_lines_count < 3 )); then
        log_error "Invalid GRO input while creating ${out_gro}: files are too short"
        return 1
    fi

    read -r rec_atoms rec_extra <<< "${rec_lines[1]}"
    read -r lig_atoms lig_extra <<< "${lig_lines[1]}"

    if [[ ! "${rec_atoms}" =~ ^[0-9]+$ || ! "${lig_atoms}" =~ ^[0-9]+$ ]]; then
        log_error "Invalid GRO atom count while creating ${out_gro}"
        return 1
    fi

    rec_box_idx=$((2 + rec_atoms))
    lig_box_idx=$((2 + lig_atoms))
    if (( rec_box_idx >= rec_lines_count || lig_box_idx >= lig_lines_count )); then
        log_error "GRO atom-count/header mismatch while creating ${out_gro}"
        return 1
    fi

    total_atoms=$((rec_atoms + lig_atoms))
    {
        printf 'Complex merged from %s and %s\n' "$(basename "${rec_gro}")" "$(basename "${lig_gro}")"
        printf '%5d\n' "${total_atoms}"

        local idx
        for (( idx = 2; idx < rec_box_idx; idx++ )); do
            printf '%s\n' "${rec_lines[idx]}"
        done
        for (( idx = 2; idx < lig_box_idx; idx++ )); do
            printf '%s\n' "${lig_lines[idx]}"
        done
        printf '%s\n' "${rec_lines[rec_box_idx]}"
    } > "${out_gro}"
}

ligand_list_cfg="$(get_config dock2com_ref ligand_list "")"
if [[ -n "${LIGAND_LIST_OVERRIDE}" ]]; then
    ligand_list_cfg="${LIGAND_LIST_OVERRIDE}"
fi

declare -a REF_LIGANDS=()
discover_ref_ligands "${ligand_list_cfg}" REF_LIGANDS

if [[ ${#REF_LIGANDS[@]} -eq 0 ]]; then
    log_error "No reference ligand directories found in ${DOCK_DIR}. Provide --ligand-list or configure [dock2com_ref] ligand_list."
    exit 1
fi

if [[ "${DRY_RUN}" == "true" ]]; then
    log_info "Mode: reference ligand dock2com"
    log_info "Workdir: ${WORKDIR}"
    log_info "Dock dir: ${DOCK_DIR}"
    log_info "Ref dir: ${REF_DIR}"
    log_info "Complex dir: ${COM_DIR}"
    log_info "Force field mode: ${FF_MODE}"
    log_info "Reference ligands: ${REF_LIGANDS[*]}"
    exit 0
fi

require_file "${REC_TOP}" "Receptor topology not found: ${REC_TOP}"
require_dir "${REF_DIR}" "Reference ligand directory not found: ${REF_DIR}"
ensure_dir "${COM_DIR}"

for ligand_id in "${REF_LIGANDS[@]}"; do
    ligand_dir="${DOCK_DIR}/${ligand_id}"
    require_dir "${ligand_dir}" "Reference ligand docking directory not found: ${ligand_dir}"

    sdf_glob="${ligand_dir}/$(render_pattern "${SDF_PATTERN}" "${ligand_id}")"
    if ! selected_sdf="$(find_first_match "${sdf_glob}")"; then
        log_error "No docking SDF matches '${sdf_glob}' for reference ligand ${ligand_id}"
        exit 1
    fi

    ref_ligand_dir="${REF_DIR}/${ligand_id}"
    require_dir "${ref_ligand_dir}" "Reference ligand parameter directory missing: ${ref_ligand_dir}"

    itp_path="${ref_ligand_dir}/$(render_pattern "${LIG_ITP_PATTERN}" "${ligand_id}")"
    if [[ ! -f "${itp_path}" && -f "${ligand_dir}/$(render_pattern "${LIG_ITP_PATTERN}" "${ligand_id}")" ]]; then
        itp_path="${ligand_dir}/$(render_pattern "${LIG_ITP_PATTERN}" "${ligand_id}")"
    fi
    if [[ ! -f "${itp_path}" && -f "${ligand_dir}/lig.itp" ]]; then
        itp_path="${ligand_dir}/lig.itp"
    fi
    require_file "${itp_path}" "Reference ligand ITP not found for ${ligand_id}: ${itp_path}"

    template_path="${ref_ligand_dir}/$(render_pattern "${LIG_TEMPLATE_PATTERN}" "${ligand_id}")"
    if [[ ! -f "${template_path}" && -f "${ligand_dir}/$(render_pattern "${LIG_TEMPLATE_PATTERN}" "${ligand_id}")" ]]; then
        template_path="${ligand_dir}/$(render_pattern "${LIG_TEMPLATE_PATTERN}" "${ligand_id}")"
    fi
    if [[ ! -f "${template_path}" ]]; then
        if alt_template="$(find_first_match "${ligand_dir}/*.mol2")"; then
            template_path="${alt_template}"
        fi
    fi
    require_file "${template_path}" "Reference ligand MOL2 template not found for ${ligand_id}: ${template_path}"

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

    if ! rec_gro="$(resolve_receptor_gro "${selected_sdf}" "${ligand_dir}")"; then
        log_error "[${ligand_id}] Could not locate receptor GRO for ${selected_sdf}. Expected <prefix>.pdb_ali.gro near docking/receptor outputs."
        exit 1
    fi
    require_file "${rec_gro}" "[${ligand_id}] Receptor GRO not found: ${rec_gro}"

    log_info "[${ligand_id}] Create complex GRO: ${com_gro}"
    if ! merge_complex_gro "${rec_gro}" "${lig_gro}" "${com_gro}"; then
        log_error "[${ligand_id}] Failed to merge receptor+ligand GRO into ${com_gro}"
        exit 1
    fi

    if [[ ! -f "${com_gro}" && -f "${ligand_dir}/complex.gro" ]]; then
        com_gro="${ligand_dir}/complex.gro"
    fi
    require_file "${sys_top}" "System topology was not generated: ${sys_top}"
    require_file "${com_gro}" "Complex GRO was not generated: ${com_gro}"

    log_info "[${ligand_id}] Generate ligand position restraints"
    python "${UTIL_POSRE}" --gro "${lig_gro}" --itp "${itp_path}" --force-constant "${FORCE_CONSTANT}" --output "${posre_lig}"
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

log_info "Reference dock-to-complex conversion completed for ${#REF_LIGANDS[@]} ligands"
