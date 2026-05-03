#!/usr/bin/env bash
#
# Dryrun Report Generator for autoEnsmblDockMD Pipeline
# Generates comprehensive markdown report showing file/config/tool readiness,
# command preview, and workflow flowchart before expensive execution.
#
# Usage:
#   bash scripts/phase7/07-dryrun-report.sh --config <path> --mode <blind|targeted> [--output <path>]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source environment and common utilities
# shellcheck source=/dev/null
source "${PROJECT_ROOT}/setenv.sh" 2>/dev/null || true
# shellcheck source=/dev/null
source "${PROJECT_ROOT}/infra/common.sh"

# Default values
CONFIG_FILE=""
MODE=""
OUTPUT_FILE=""
TEMP_DIR=""

# Cleanup function
cleanup() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

usage() {
    cat <<'EOF'
Dryrun Report Generator

Generates comprehensive markdown report showing pipeline readiness before execution.

Usage:
  07-dryrun-report.sh --config <path> --mode <blind|targeted> [--output <path>]

Required:
  --config <path>      Config file path (INI format)
  --mode <mode>        Docking mode: blind or targeted

Optional:
  --output <path>      Output report path (default: .planning/phases/07-first-controlled-execution/07-dryrun-report-{mode}.md)

Examples:
  bash scripts/phase7/07-dryrun-report.sh --config work/input/config.ini --mode targeted
  bash scripts/phase7/07-dryrun-report.sh --config config.ini --mode blind --output /tmp/report.md
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --config)
                [[ $# -ge 2 ]] || { log_error "--config requires a file path"; exit 1; }
                CONFIG_FILE="$2"
                shift 2
                ;;
            --mode)
                [[ $# -ge 2 ]] || { log_error "--mode requires a value"; exit 1; }
                MODE="$2"
                shift 2
                ;;
            --output)
                [[ $# -ge 2 ]] || { log_error "--output requires a file path"; exit 1; }
                OUTPUT_FILE="$2"
                shift 2
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

    # Validate required arguments
    if [[ -z "$CONFIG_FILE" ]]; then
        log_error "--config is required"
        usage
        exit 1
    fi

    if [[ -z "$MODE" ]]; then
        log_error "--mode is required (blind or targeted)"
        usage
        exit 1
    fi

    if [[ "$MODE" != "blind" && "$MODE" != "targeted" ]]; then
        log_error "Invalid mode: $MODE (expected: blind or targeted)"
        exit 1
    fi

    # Set default output path
    if [[ -z "$OUTPUT_FILE" ]]; then
        OUTPUT_FILE="${PROJECT_ROOT}/../.planning/phases/07-first-controlled-execution/07-dryrun-report-${MODE}.md"
    fi
}

check_preflight() {
    local preflight_script="${PROJECT_ROOT}/infra/plugins/preflight.py"
    local preflight_output
    
    log_info "Running preflight validation..."
    
    if [[ ! -f "$preflight_script" ]]; then
        log_warn "Preflight script not found: $preflight_script"
        echo "STATUS:missing"
        echo "ERROR:Preflight script not found"
        return 0
    fi
    
    # Run preflight and capture output
    if ! preflight_output=$(python "$preflight_script" --config "$CONFIG_FILE" 2>&1); then
        log_warn "Preflight validation returned non-zero exit code"
    fi
    
    # Return the output for parsing
    echo "$preflight_output"
}

get_dryrun_commands() {
    local pipeline_script="${PROJECT_ROOT}/run_pipeline.sh"
    local dryrun_output
    
    log_info "Running pipeline dry-run..."
    
    if [[ ! -f "$pipeline_script" ]]; then
        log_error "Pipeline script not found: $pipeline_script"
        return 1
    fi
    
    # Run dry-run and capture commands
    if ! dryrun_output=$(bash "$pipeline_script" --config "$CONFIG_FILE" --dry-run 2>&1); then
        log_warn "Pipeline dry-run returned non-zero exit code"
    fi
    
    # Extract only [DRY-RUN] lines
    echo "$dryrun_output" | grep '^\[DRY-RUN\]' || true
}

parse_preflight_results() {
    local preflight_output="$1"
    local status="unknown"
    local mode_value=""
    local tools_checked=""
    local errors=""
    local warnings=""
    
    # Parse JSON output if available
    if echo "$preflight_output" | jq -e . >/dev/null 2>&1; then
        status=$(echo "$preflight_output" | jq -r '.status // "unknown"')
        mode_value=$(echo "$preflight_output" | jq -r '.data.mode // ""')
        tools_checked=$(echo "$preflight_output" | jq -r '.data.tools_checked | join(", ") // ""')
        
        if echo "$preflight_output" | jq -e '.errors | length > 0' >/dev/null 2>&1; then
            errors=$(echo "$preflight_output" | jq -r '.errors[] | "• " + .' 2>/dev/null)
        fi
        
        if echo "$preflight_output" | jq -e '.warnings | length > 0' >/dev/null 2>&1; then
            warnings=$(echo "$preflight_output" | jq -r '.warnings[] | "• " + .' 2>/dev/null)
        fi
    else
        # Fallback: parse text output
        status=$(echo "$preflight_output" | grep -oP 'STATUS:\K\S+' || echo "unknown")
    fi
    
    # Store results for later use
    PREFLIGHT_STATUS="$status"
    PREFLIGHT_MODE="$mode_value"
    PREFLIGHT_TOOLS="$tools_checked"
    PREFLIGHT_ERRORS="$errors"
    PREFLIGHT_WARNINGS="$warnings"
}

check_file_readiness() {
    local config_dir
    config_dir=$(dirname "$CONFIG_FILE")
    
    local files_checked=0
    local files_found=0
    local file_report=""
    
    # Check config file exists
    files_checked=$((files_checked + 1))
    if [[ -f "$CONFIG_FILE" ]]; then
        files_found=$((files_found + 1))
        file_report+="✓ Config file: $CONFIG_FILE\n"
    else
        file_report+="✗ Config file missing: $CONFIG_FILE\n"
    fi
    
    # Check for common input files
    local input_files=(
        "receptor.pdb"
        "rec.pdb"
        "ref.pdb"
    )
    
    for file in "${input_files[@]}"; do
        files_checked=$((files_checked + 1))
        if [[ -f "${config_dir}/${file}" ]]; then
            files_found=$((files_found + 1))
            file_report+="✓ Input file: ${file}\n"
        fi
    done
    
    # Check for ligand directories
    if [[ -d "${config_dir}/dzp" ]]; then
        files_checked=$((files_checked + 1))
        files_found=$((files_found + 1))
        file_report+="✓ Ligand directory: dzp/\n"
    fi
    
    if [[ -d "${config_dir}/ibp" ]]; then
        files_checked=$((files_checked + 1))
        files_found=$((files_found + 1))
        file_report+="✓ Ligand directory: ibp/\n"
    fi
    
    FILE_COUNT="$files_found/$files_checked"
    FILE_REPORT="$file_report"
}

check_config_sections() {
    local sections=(
        "general"
        "docking"
        "receptor"
        "complex"
        "slurm"
        "production"
        "mmpbsa"
        "analysis"
    )
    
    local sections_found=0
    local section_report=""
    
    for section in "${sections[@]}"; do
        if grep -q "^\[${section}\]" "$CONFIG_FILE" 2>/dev/null; then
            sections_found=$((sections_found + 1))
            section_report+="✓ [${section}]\n"
        else
            section_report+="✗ [${section}] missing\n"
        fi
    done
    
    SECTION_COUNT="${sections_found}/${#sections[@]}"
    SECTION_REPORT="$section_report"
}

generate_flowchart() {
    local flowchart_script="${SCRIPT_DIR}/07-generate-flowchart.py"
    local flowchart_output
    
    if [[ ! -f "$flowchart_script" ]]; then
        log_warn "Flowchart generator not found: $flowchart_script"
        echo "```\nFlowchart generator not available.\n```"
        return 0
    fi
    
    # Generate flowchart
    if ! flowchart_output=$(python "$flowchart_script" --mode "$MODE" 2>&1); then
        log_warn "Flowchart generation failed"
        echo "```\nFlowchart generation failed.\n```"
        return 0
    fi
    
    echo "$flowchart_output"
}

generate_report() {
    local report_file="$1"
    local report_dir
    report_dir=$(dirname "$report_file")
    
    # Create output directory if needed
    if [[ ! -d "$report_dir" ]]; then
        mkdir -p "$report_dir"
    fi
    
    log_info "Generating dryrun report: $report_file"
    
    # Get current timestamp
    local timestamp
    timestamp=$(date +"%Y-%m-%dT%H:%M:%S%z")
    
    # Calculate overall status
    local overall_status="READY"
    if [[ -n "$PREFLIGHT_ERRORS" ]]; then
        overall_status="BLOCKED"
    elif [[ -n "$PREFLIGHT_WARNINGS" ]]; then
        overall_status="NEEDS_REVIEW"
    fi
    
    # Generate markdown report
    cat > "$report_file" <<EOF
# Dryrun Report: ${MODE^} Docking Mode

**Generated:** ${timestamp}  
**Config:** ${CONFIG_FILE}  
**Mode:** ${MODE}  
**Status:** ${overall_status}

---

## Summary

| Category | Status | Details |
|----------|--------|---------|
| Preflight Validation | ${PREFLIGHT_STATUS:-unknown} | $(if [[ -n "$PREFLIGHT_ERRORS" ]]; then echo "Errors found"; elif [[ -n "$PREFLIGHT_WARNINGS" ]]; then echo "Warnings found"; else echo "All checks passed"; fi) |
| File Readiness | ${FILE_COUNT:-0/0} files found | Input files and directories |
| Config Sections | ${SECTION_COUNT:-0/0} sections found | Required configuration sections |
| Tool Availability | $(if [[ -n "$PREFLIGHT_TOOLS" ]]; then echo "✓ Tools found"; else echo "⚠ Tools check pending"; fi) | ${PREFLIGHT_TOOLS:-N/A} |

EOF

    # Add errors section if present
    if [[ -n "$PREFLIGHT_ERRORS" ]]; then
        cat >> "$report_file" <<EOF

## Errors

${PREFLIGHT_ERRORS}

EOF
    fi

    # Add warnings section if present
    if [[ -n "$PREFLIGHT_WARNINGS" ]]; then
        cat >> "$report_file" <<EOF

## Warnings

${PREFLIGHT_WARNINGS}

EOF
    fi

    # Add file/config readiness section
    cat >> "$report_file" <<EOF

## File/Config Readiness

### Files

$(echo -e "$FILE_REPORT")

### Configuration Sections

$(echo -e "$SECTION_REPORT")

EOF

    # Add tool availability section
    cat >> "$report_file" <<EOF

## Tool Availability

| Tool | Status |
|------|--------|
EOF

    for tool in gmx gnina gmx_MMPBSA; do
        if command -v "$tool" >/dev/null 2>&1; then
            echo "| $tool | ✓ Available |" >> "$report_file"
        else
            echo "| $tool | ✗ Not found |" >> "$report_file"
        fi
    done

    # Add command preview section
    cat >> "$report_file" <<EOF

## Command Preview

The following commands would execute during pipeline run:

<details>
<summary>Click to expand command list (${DRYRUN_COMMAND_COUNT:-0} commands)</summary>

\`\`\`bash
${DRYRUN_COMMANDS:-No commands to display}
\`\`\`

</details>

EOF

    # Add workflow flowchart
    local flowchart
    flowchart=$(generate_flowchart)
    
    cat >> "$report_file" <<EOF

## Workflow Flowchart

EOF

    echo "$flowchart" >> "$report_file"

    # Add manual approval gate
    cat >> "$report_file" <<EOF

---

## Manual Approval Gate

EOF

    if [[ "$overall_status" == "BLOCKED" ]]; then
        cat >> "$report_file" <<EOF

⚠️ **BLOCKED** - Critical issues must be resolved before execution.

**Action Required:**
1. Review errors listed above
2. Fix configuration or missing files
3. Re-run dryrun report to verify fixes

**DO NOT PROCEED** until all blocking issues are resolved.
EOF
    elif [[ "$overall_status" == "NEEDS_REVIEW" ]]; then
        cat >> "$report_file" <<EOF

⚠️ **NEEDS REVIEW** - Warnings detected but execution can proceed.

**Action Recommended:**
1. Review warnings listed above
2. Decide if warnings are acceptable
3. Type "approved" to proceed with execution

**You may proceed** after reviewing warnings.
EOF
    else
        cat >> "$report_file" <<EOF

✓ **READY FOR EXECUTION** - All checks passed.

**Next Steps:**
1. Review this dryrun report
2. Verify the command preview shows expected workflow
3. Type "approved" to proceed with execution

**Safe to proceed** after your review.
EOF
    fi

    # Add footer
    cat >> "$report_file" <<EOF

---

*Report generated by scripts/phase7/07-dryrun-report.sh*  
*autoEnsmblDockMD Pipeline Validation*
EOF

    log_info "Report generated successfully: $report_file"
}

main() {
    parse_args "$@"
    
    # Verify config file exists
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Config file not found: $CONFIG_FILE"
        exit 1
    fi
    
    log_info "Starting dryrun report generation..."
    log_info "Config: $CONFIG_FILE"
    log_info "Mode: $MODE"
    log_info "Output: $OUTPUT_FILE"
    
    # Create temp directory for intermediate files
    TEMP_DIR=$(mktemp -d)
    
    # Run checks
    local preflight_output
    preflight_output=$(check_preflight)
    parse_preflight_results "$preflight_output"
    
    check_file_readiness
    check_config_sections
    
    # Get dryrun commands
    DRYRUN_COMMANDS=$(get_dryrun_commands)
    DRYRUN_COMMAND_COUNT=$(echo "$DRYRUN_COMMANDS" | grep -c '^\[DRY-RUN\]' || echo "0")
    
    # Generate report
    generate_report "$OUTPUT_FILE"
    
    # Exit with appropriate code
    if [[ "$PREFLIGHT_STATUS" == "failure" ]]; then
        log_error "Dryrun report generated with blocking issues"
        exit 1
    elif [[ -n "$PREFLIGHT_WARNINGS" ]]; then
        log_warn "Dryrun report generated with warnings"
        exit 2
    else
        log_info "Dryrun report generated successfully"
        exit 0
    fi
}

main "$@"
