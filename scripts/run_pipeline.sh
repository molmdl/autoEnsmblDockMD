#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/infra/common.sh"

STAGE=""
CONFIG_FILE=""
LIGAND_ID=""
DRY_RUN="false"
LIST_STAGES="false"

declare -A STAGE_DESC=()
declare -A STAGE_CMD=()
declare -A STAGE_SECTIONS=()
declare -A STAGE_LIGAND_MODE=()

STAGE_DESC[rec_prep]="Prepare receptor system and submit equilibration"
STAGE_CMD[rec_prep]="${SCRIPT_DIR}/rec/0_prep.sh"
STAGE_SECTIONS[rec_prep]="general,receptor,slurm"
STAGE_LIGAND_MODE[rec_prep]="none"

STAGE_DESC[rec_prod]="Submit receptor production MD trials"
STAGE_CMD[rec_prod]="${SCRIPT_DIR}/rec/1_pr_rec.sh"
STAGE_SECTIONS[rec_prod]="general,receptor,slurm"
STAGE_LIGAND_MODE[rec_prod]="none"

STAGE_DESC[rec_ana]="Run receptor trajectory analysis"
STAGE_CMD[rec_ana]="${SCRIPT_DIR}/rec/3_ana.sh"
STAGE_SECTIONS[rec_ana]="general,receptor"
STAGE_LIGAND_MODE[rec_ana]="none"

STAGE_DESC[rec_cluster]="Cluster receptor ensemble conformations"
STAGE_CMD[rec_cluster]="${SCRIPT_DIR}/rec/4_cluster.sh"
STAGE_SECTIONS[rec_cluster]="general,receptor"
STAGE_LIGAND_MODE[rec_cluster]="none"

STAGE_DESC[rec_align]="Align receptor ensemble to reference complex"
STAGE_CMD[rec_align]="${SCRIPT_DIR}/rec/5_align.py"
STAGE_SECTIONS[rec_align]="receptor"
STAGE_LIGAND_MODE[rec_align]="none"

STAGE_DESC[dock_convert]="Convert ligand inputs into docking formats"
STAGE_CMD[dock_convert]="${SCRIPT_DIR}/dock/0_gro2mol2.sh"
STAGE_SECTIONS[dock_convert]="dock"
STAGE_LIGAND_MODE[dock_convert]="none"

STAGE_DESC[dock_run]="Run gnina docking jobs"
STAGE_CMD[dock_run]="${SCRIPT_DIR}/dock/2_gnina.sh"
STAGE_SECTIONS[dock_run]="general,docking,slurm,receptor"
STAGE_LIGAND_MODE[dock_run]="ligand-list"

STAGE_DESC[dock_report]="Generate ranked docking report"
STAGE_CMD[dock_report]="${SCRIPT_DIR}/dock/3_dock_report.sh"
STAGE_SECTIONS[dock_report]="docking"
STAGE_LIGAND_MODE[dock_report]="none"

STAGE_DESC[dock2com]="Convert docked poses into complex topology"
STAGE_CMD[dock2com]="${SCRIPT_DIR}/dock/4_dock2com.sh"
STAGE_SECTIONS[dock2com]="general,docking,dock2com"
STAGE_LIGAND_MODE[dock2com]="ligand-list"

STAGE_DESC[com_prep]="Prepare complex system for MD"
STAGE_CMD[com_prep]="${SCRIPT_DIR}/com/0_prep.sh"
STAGE_SECTIONS[com_prep]="general,complex,slurm"
STAGE_LIGAND_MODE[com_prep]="ligand"

STAGE_DESC[com_prod]="Run complex production MD"
STAGE_CMD[com_prod]="${SCRIPT_DIR}/com/1_pr_prod.sh"
STAGE_SECTIONS[com_prod]="general,complex,production,slurm"
STAGE_LIGAND_MODE[com_prod]="ligand"

STAGE_DESC[com_mmpbsa]="Run MM/PBSA trajectory prep and submission"
STAGE_CMD[com_mmpbsa]="${SCRIPT_DIR}/com/2_run_mmpbsa.sh"
STAGE_SECTIONS[com_mmpbsa]="general,mmpbsa"
STAGE_LIGAND_MODE[com_mmpbsa]="ligand"

STAGE_DESC[com_ana]="Run complex trajectory analysis"
STAGE_CMD[com_ana]="${SCRIPT_DIR}/com/3_ana.sh"
STAGE_SECTIONS[com_ana]="general,complex,analysis"
STAGE_LIGAND_MODE[com_ana]="ligand"

STAGE_DESC[com_fp]="Run fingerprint analysis (optional utility)"
STAGE_CMD[com_fp]="${SCRIPT_DIR}/com/4_cal_fp.sh"
STAGE_SECTIONS[com_fp]="fingerprint"
STAGE_LIGAND_MODE[com_fp]="none"

STAGE_DESC[com_archive]="Archive/rerun selection workflow (optional utility)"
STAGE_CMD[com_archive]="${SCRIPT_DIR}/com/5_arc_sel.sh"
STAGE_SECTIONS[com_archive]="analysis"
STAGE_LIGAND_MODE[com_archive]="none"

ALL_STAGES=(
    rec_prep
    rec_prod
    rec_ana
    rec_cluster
    rec_align
    dock_convert
    dock_run
    dock_report
    dock2com
    com_prep
    com_prod
    com_mmpbsa
    com_ana
    com_fp
    com_archive
)

DEFAULT_PIPELINE_STAGES=(
    rec_prep
    rec_prod
    rec_ana
    rec_cluster
    rec_align
    dock_convert
    dock_run
    dock_report
    dock2com
    com_prep
    com_prod
    com_mmpbsa
    com_ana
)

usage() {
    cat <<'EOF'
Usage: run_pipeline.sh --config <file> [--stage <name>] [--ligand <id>] [--dry-run]

Pipeline wrapper for receptor -> docking -> complex MD -> MM/PBSA -> analysis.

Required:
  --config <file>      INI config file

Optional:
  --stage <name>       Run one stage only (default: run full pipeline)
  --ligand <id>        Per-ligand target for stages that support it
  --dry-run            Print resolved command(s) without execution
  --list-stages        Print machine-readable stage list
  --help               Show this help message

Stages:
  rec_prep      receptor preparation and equilibration submission
  rec_prod      receptor production MD submissions
  rec_ana       receptor analysis
  rec_cluster   receptor clustering
  rec_align     receptor alignment
  dock_convert  ligand docking format conversion
  dock_run      gnina docking execution
  dock_report   docking score reporting
  dock2com      docked pose to complex conversion
  com_prep      complex MD preparation
  com_prod      complex production MD submission
  com_mmpbsa    MM/PBSA orchestration
  com_ana       trajectory analysis
  com_fp        optional fingerprint utility stage
  com_archive   optional archive/rerun utility stage
EOF
}

list_stages_machine_readable() {
    local stage cmd status
    printf 'stage\tscript\tstatus\tdescription\n'
    for stage in "${ALL_STAGES[@]}"; do
        cmd="${STAGE_CMD[$stage]}"
        status="implemented"
        [[ -f "$cmd" ]] || status="missing-script"
        printf '%s\t%s\t%s\t%s\n' "$stage" "$cmd" "$status" "${STAGE_DESC[$stage]}"
    done
}

config_has_section() {
    local config_file="$1"
    local section="$2"
    [[ -n "$section" ]] || return 0
    grep -Eq "^[[:space:]]*\[${section}\][[:space:]]*$" "$config_file"
}

validate_stage_config_sections() {
    local stage="$1"
    local required_csv section
    required_csv="${STAGE_SECTIONS[$stage]}"
    IFS=',' read -r -a _required_sections <<< "$required_csv"
    for section in "${_required_sections[@]}"; do
        [[ -n "$section" ]] || continue
        if ! config_has_section "$CONFIG_FILE" "$section"; then
            log_error "Stage '${stage}' requires config section [${section}] in ${CONFIG_FILE}"
            exit 1
        fi
    done
}

run_one_stage() {
    local stage="$1"
    local cmd mode
    local -a run_cmd

    if [[ -z "${STAGE_CMD[$stage]:-}" ]]; then
        log_error "Unknown stage: ${stage}"
        usage
        exit 1
    fi

    cmd="${STAGE_CMD[$stage]}"
    validate_stage_config_sections "$stage"

    if [[ ! -f "$cmd" ]]; then
        log_error "Stage '${stage}' is defined but script is missing: ${cmd}"
        exit 1
    fi

    mode="${STAGE_LIGAND_MODE[$stage]}"
    run_cmd=("$cmd" "--config" "$CONFIG_FILE")

    if [[ -n "$LIGAND_ID" ]]; then
        case "$mode" in
            ligand)
                run_cmd+=("--ligand" "$LIGAND_ID")
                ;;
            ligand-list)
                run_cmd+=("--ligand-list" "$LIGAND_ID")
                ;;
            target)
                run_cmd+=("--target" "$LIGAND_ID")
                ;;
            *)
                log_warn "Stage '${stage}' does not consume --ligand; ignoring ligand '${LIGAND_ID}'"
                ;;
        esac
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        printf '[DRY-RUN] %s\n' "${run_cmd[*]}"
        return 0
    fi

    log_info "[pipeline] stage_start=${stage} ts=$(date +"%Y-%m-%dT%H:%M:%S%z")"
    if [[ "$cmd" == *.py ]]; then
        python "${run_cmd[@]}"
    else
        bash "${run_cmd[@]}"
    fi
    log_info "[pipeline] stage_end=${stage} ts=$(date +"%Y-%m-%dT%H:%M:%S%z")"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --stage)
            [[ $# -ge 2 ]] || { log_error "--stage requires a value"; exit 1; }
            STAGE="$2"
            shift 2
            ;;
        --config)
            [[ $# -ge 2 ]] || { log_error "--config requires a file path"; exit 1; }
            CONFIG_FILE="$2"
            shift 2
            ;;
        --ligand)
            [[ $# -ge 2 ]] || { log_error "--ligand requires a value"; exit 1; }
            LIGAND_ID="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        --list-stages)
            LIST_STAGES="true"
            shift
            ;;
        --help|-h)
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

if [[ "$LIST_STAGES" == "true" ]]; then
    list_stages_machine_readable
    exit 0
fi

if [[ -z "$CONFIG_FILE" ]]; then
    log_error "--config is required"
    usage
    exit 1
fi
require_file "$CONFIG_FILE" "Config file not found: $CONFIG_FILE"

if [[ -n "$STAGE" ]]; then
    run_one_stage "$STAGE"
else
    log_info "[pipeline] start ts=$(date +"%Y-%m-%dT%H:%M:%S%z")"
    for stage in "${DEFAULT_PIPELINE_STAGES[@]}"; do
        run_one_stage "$stage"
    done
    if [[ -f "${STAGE_CMD[com_fp]}" ]]; then
        run_one_stage "com_fp"
    else
        log_warn "Optional stage com_fp skipped (script missing: ${STAGE_CMD[com_fp]})"
    fi
    if [[ -f "${STAGE_CMD[com_archive]}" ]]; then
        run_one_stage "com_archive"
    else
        log_warn "Optional stage com_archive skipped (script missing: ${STAGE_CMD[com_archive]})"
    fi
    log_info "[pipeline] end ts=$(date +"%Y-%m-%dT%H:%M:%S%z")"
fi
