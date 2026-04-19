#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../infra/common.sh"

SCRIPT_NAME="0_prep"
CONFIG_FILE=""
LIGAND_OVERRIDE=""

usage() {
    cat <<'EOF'
Usage: 0_prep.sh [--config FILE] [--ligand NAME|PATH] [--help]

Unified complex preparation for both AMBER and CHARMM workflows:
1) Assemble receptor + ligand complex (com.gro)
2) Build system topology (sys.top)
3) AMBER only: run bypass_angle_type3.py for ligand ITP
4) Solvate and ionize system
5) Minimize (em)
6) Run position-restrained equilibration (pr_pos)
7) Submit heavy GROMACS steps via Slurm

Options:
  --config FILE          INI config file
  --ligand NAME|PATH     Prepare one ligand only
  -h, --help             Show this help and exit

Config keys used:
  [general]
    workdir
  [complex]
    mode = amber|charmm
    workdir
    ligand_dir
    ligand_pattern
    ligand_list
    receptor_gro
    receptor_top
    ff
    ff_include
    water_model
    box_distance
    ion_conc
    mdp_dir
    em_mdp
    pr_pos_mdp
    ligand_itp
    ligand_gro
    bypass_script
  [slurm]
    partition
    ntomp
    gpus

Notes:
  - Multi-ligand mode is enabled by [complex] ligand_list or ligand directory discovery.
  - Ligand names are directory names under [complex] ligand_dir unless --ligand is used.
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

require_cmd python
require_cmd sbatch

WORKDIR="$(get_config general workdir "$(pwd)")"
COMPLEX_WORKDIR="$(get_config complex workdir "${WORKDIR}/com")"
LIGAND_DIR="$(get_config complex ligand_dir "${WORKDIR}/dock")"
LIGAND_PATTERN="$(get_config complex ligand_pattern "lig*")"
LIGAND_LIST_CFG="$(get_config complex ligand_list "")"

MODE="$(get_config complex mode "charmm")"
MODE="${MODE,,}"
if [[ "${MODE}" != "amber" && "${MODE}" != "charmm" ]]; then
    log_error "Invalid [complex] mode='${MODE}'. Must be amber or charmm"
    exit 1
fi

RECEPTOR_GRO="$(get_config complex receptor_gro "${WORKDIR}/rec/prot.gro")"
RECEPTOR_TOP="$(get_config complex receptor_top "${WORKDIR}/rec/topol.top")"
FF_DEFAULT="charmm36"
if [[ "${MODE}" == "amber" ]]; then
    FF_DEFAULT="amber19sb"
fi
FF_NAME="$(get_config complex ff "${FF_DEFAULT}")"
FF_INCLUDE="$(get_config complex ff_include "${FF_NAME}.ff/forcefield.itp")"
WATER_MODEL="$(get_config complex water_model "tip3p")"
BOX_DISTANCE="$(get_config complex box_distance "1.0")"
ION_CONC="$(get_config complex ion_conc "0.15")"
MDP_DIR="$(get_config complex mdp_dir "${SCRIPT_DIR}")"
EM_MDP="$(get_config complex em_mdp "em.mdp")"
PR_POS_MDP="$(get_config complex pr_pos_mdp "pr.mdp")"

LIGAND_ITP_KEY="$(get_config complex ligand_itp "")"
LIGAND_GRO_KEY="$(get_config complex ligand_gro "")"

BYPASS_SCRIPT="$(get_config complex bypass_script "${SCRIPT_DIR}/bypass_angle_type3.py")"

SLURM_PARTITION="$(get_config slurm partition "rtx4090-short")"
NTOMP="$(get_config slurm ntomp "8")"
SLURM_GPUS="$(get_config slurm gpus "1")"

require_dir "${WORKDIR}" "General workdir not found: ${WORKDIR}"
require_dir "${LIGAND_DIR}" "Ligand directory not found: ${LIGAND_DIR}"
ensure_dir "${COMPLEX_WORKDIR}"

require_file "${RECEPTOR_GRO}" "Receptor GRO not found: ${RECEPTOR_GRO}"
require_file "${RECEPTOR_TOP}" "Receptor topology not found: ${RECEPTOR_TOP}"
require_file "${MDP_DIR}/${EM_MDP}" "Missing EM MDP file: ${MDP_DIR}/${EM_MDP}"
require_file "${MDP_DIR}/${PR_POS_MDP}" "Missing pr_pos MDP file: ${MDP_DIR}/${PR_POS_MDP}"

if [[ "${MODE}" == "amber" ]]; then
    require_file "${BYPASS_SCRIPT}" "AMBER mode requires bypass script: ${BYPASS_SCRIPT}"
fi

if [[ -d "${WORKDIR}/${FF_NAME}.ff" && ! -e "${COMPLEX_WORKDIR}/${FF_NAME}.ff" ]]; then
    ln -s "${WORKDIR}/${FF_NAME}.ff" "${COMPLEX_WORKDIR}/${FF_NAME}.ff"
fi

extract_molecule_name_from_itp() {
    local itp_file="$1"
    python - "$itp_file" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
in_section = False
for raw in path.read_text().splitlines():
    line = raw.strip()
    if not line or line.startswith(';'):
        continue
    if line.startswith('[') and line.endswith(']'):
        in_section = line.lower() == '[ moleculetype ]'
        continue
    if in_section:
        token = re.split(r"\s+", line)[0]
        print(token)
        sys.exit(0)

print("LIG")
PY
}

write_combined_gro() {
    local receptor_gro="$1"
    local ligand_gro="$2"
    local output_gro="$3"
    python - "$receptor_gro" "$ligand_gro" "$output_gro" <<'PY'
import pathlib
import sys

rec = pathlib.Path(sys.argv[1]).read_text().splitlines()
lig = pathlib.Path(sys.argv[2]).read_text().splitlines()
out = pathlib.Path(sys.argv[3])

if len(rec) < 3 or len(lig) < 3:
    raise SystemExit("Invalid GRO file: expected header, atom count, coordinates, box")

try:
    rec_n = int(rec[1].strip())
    lig_n = int(lig[1].strip())
except ValueError as exc:
    raise SystemExit(f"Invalid GRO atom count: {exc}")

rec_coords = rec[2:2 + rec_n]
lig_coords = lig[2:2 + lig_n]
box = rec[-1].strip()

merged = []
merged.append("Complex system")
merged.append(str(rec_n + lig_n))
merged.extend(rec_coords)
merged.extend(lig_coords)
merged.append(box)

out.write_text("\n".join(merged) + "\n")
PY
}

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

resolve_single_match() {
    local base_dir="$1"
    local preferred="$2"
    local pattern="$3"

    if [[ -n "${preferred}" ]]; then
        if [[ -f "${preferred}" ]]; then
            printf '%s\n' "$(realpath "${preferred}")"
            return 0
        fi
        if [[ -f "${base_dir}/${preferred}" ]]; then
            printf '%s\n' "$(realpath "${base_dir}/${preferred}")"
            return 0
        fi
    fi

    shopt -s nullglob
    local matches=("${base_dir}"/${pattern})
    shopt -u nullglob
    if [[ ${#matches[@]} -eq 0 ]]; then
        return 1
    fi
    printf '%s\n' "$(realpath "${matches[0]}")"
    return 0
}

build_sys_top() {
    local output_top="$1"
    local ligand_itp_basename="$2"
    local ligand_molname="$3"

    python - "${RECEPTOR_TOP}" "${output_top}" "${FF_INCLUDE}" "${ligand_itp_basename}" "${ligand_molname}" <<'PY'
import pathlib
import re
import sys

receptor_top = pathlib.Path(sys.argv[1])
output_top = pathlib.Path(sys.argv[2])
ff_include = sys.argv[3]
ligand_itp = sys.argv[4]
ligand_molname = sys.argv[5]

lines = receptor_top.read_text().splitlines()

ff_idx = -1
mol_idx = -1
include_re = re.compile(r'^\s*#include\s+["<]([^">]+)[">]')

for idx, raw in enumerate(lines):
    match = include_re.match(raw)
    if match and match.group(1) == ff_include:
        ff_idx = idx
        break

if ff_idx == -1:
    for idx, raw in enumerate(lines):
        if include_re.match(raw):
            ff_idx = idx
            break

if ff_idx == -1:
    raise SystemExit(
        f"Failed to extract receptor topology block: no #include found in {receptor_top}"
    )

for idx in range(ff_idx + 1, len(lines)):
    if lines[idx].strip().lower() == "[ molecules ]":
        mol_idx = idx
        break

if mol_idx == -1:
    raise SystemExit(
        f"Failed to extract receptor topology block: [ molecules ] not found in {receptor_top}"
    )

receptor_block = lines[ff_idx + 1:mol_idx]
content = [
    "; unified complex topology",
    f'#include "{ff_include}"',
]

if receptor_block:
    content.extend(receptor_block)

content.extend(
    [
        f'#include "{ligand_itp}"',
        "",
        "[ system ]",
        "Protein-Ligand complex",
        "",
        "[ molecules ]",
        "Protein    1",
        f"{ligand_molname}    1",
        "",
    ]
)

output_top.write_text("\n".join(content))
PY
}

require_safe_id() {
    local value="$1"
    local label="$2"
    if [[ ! "${value}" =~ ^[A-Za-z0-9._-]+$ ]]; then
        log_error "Invalid ${label} '${value}'. Allowed characters: A-Z a-z 0-9 . _ -"
        exit 1
    fi
}

require_uint() {
    local value="$1"
    local label="$2"
    if [[ ! "${value}" =~ ^[0-9]+$ ]]; then
        log_error "Invalid ${label}='${value}'. Expected non-negative integer."
        exit 1
    fi
}

require_safe_partition() {
    local value="$1"
    if [[ ! "${value}" =~ ^[A-Za-z0-9._,-]+$ ]]; then
        log_error "Invalid slurm partition='${value}'."
        exit 1
    fi
}

submit_prepare_job() {
    local ligand_name="$1"
    local ligand_dir="$2"
    local ligand_itp_file="$3"
    local ligand_gro_file="$4"

    local prep_dir="${COMPLEX_WORKDIR}/${ligand_name}"
    local local_lig_itp local_lig_gro ligand_molname job_script job_id solvate_cs
    local q_prep_dir q_box_distance q_solvate_cs q_ion_conc q_ntomp

    require_safe_id "${ligand_name}" "ligand id"
    require_uint "${NTOMP}" "slurm ntomp"
    require_uint "${SLURM_GPUS}" "slurm gpus"
    require_safe_partition "${SLURM_PARTITION}"
    if [[ ! "${BOX_DISTANCE}" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        log_error "Invalid complex box_distance='${BOX_DISTANCE}'. Expected numeric value."
        exit 1
    fi
    if [[ ! "${ION_CONC}" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        log_error "Invalid complex ion_conc='${ION_CONC}'. Expected numeric value."
        exit 1
    fi

    ensure_dir "${prep_dir}"

    cp -f "${MDP_DIR}/${EM_MDP}" "${prep_dir}/em.mdp"
    cp -f "${MDP_DIR}/${PR_POS_MDP}" "${prep_dir}/pr_pos.mdp"
    cp -f "${ligand_itp_file}" "${prep_dir}/$(basename "${ligand_itp_file}")"
    cp -f "${ligand_gro_file}" "${prep_dir}/$(basename "${ligand_gro_file}")"

    local_lig_itp="${prep_dir}/$(basename "${ligand_itp_file}")"
    local_lig_gro="${prep_dir}/$(basename "${ligand_gro_file}")"

    if [[ "${MODE}" == "amber" ]]; then
        local bypass_out="${prep_dir}/bypass_$(basename "${local_lig_itp}")"
        log_info "Running AMBER angle bypass for ${ligand_name}"
        python "${BYPASS_SCRIPT}" --input "${local_lig_itp}" --output "${bypass_out}"
        local_lig_itp="${bypass_out}"
    fi

    solvate_cs="${WATER_MODEL:-}"
    if [[ -z "${solvate_cs}" ]]; then
        solvate_cs="spc216"
    fi

    ligand_molname="$(extract_molecule_name_from_itp "${local_lig_itp}")"

    write_combined_gro "${RECEPTOR_GRO}" "${local_lig_gro}" "${prep_dir}/com.gro"
    build_sys_top "${prep_dir}/sys.top" "$(basename "${local_lig_itp}")" "${ligand_molname}"

    printf -v q_prep_dir '%q' "${prep_dir}"
    printf -v q_box_distance '%q' "${BOX_DISTANCE}"
    printf -v q_solvate_cs '%q' "${solvate_cs}"
    printf -v q_ion_conc '%q' "${ION_CONC}"
    printf -v q_ntomp '%q' "${NTOMP}"

    job_script="${prep_dir}/prep_complex.sbatch"
    cat > "${job_script}" <<EOF
#!/usr/bin/env bash
#SBATCH -J com_prep_${ligand_name}
#SBATCH -n 1
#SBATCH -c ${NTOMP}
#SBATCH -p ${SLURM_PARTITION}
#SBATCH --gres=gpu:${SLURM_GPUS}

set -euo pipefail
cd ${q_prep_dir}

readonly BOX_DISTANCE=${q_box_distance}
readonly SOLVATE_CS=${q_solvate_cs}
readonly ION_CONC=${q_ion_conc}
readonly NTOMP=${q_ntomp}

gmx editconf -f com.gro -o box.gro -d "\${BOX_DISTANCE}" -bt dodecahedron -c
gmx solvate -p sys.top -cp box.gro -cs "\${SOLVATE_CS}" -o solv.gro
gmx grompp -f em.mdp -c solv.gro -p sys.top -o ion.tpr -maxwarn 2
echo SOL | gmx genion -s ion.tpr -p sys.top -neutral -nname CL -pname NA -conc "\${ION_CONC}" -o ion.gro
gmx grompp -f em.mdp -c ion.gro -p sys.top -o em.tpr -maxwarn 2
echo -e '"Protein" | "Other"\\nq' | gmx make_ndx -f em.tpr
gmx mdrun -deffnm em -ntmpi 1 -ntomp "\${NTOMP}"
gmx grompp -f pr_pos.mdp -c em.gro -p sys.top -r em.gro -o pr_pos.tpr -maxwarn 2 -n index.ndx
gmx mdrun -deffnm pr_pos -ntmpi 1 -ntomp "\${NTOMP}" -bonded gpu -nb gpu -update gpu -pme gpu -cpt 5
EOF

    chmod +x "${job_script}"
    job_id="$(submit_job "${job_script}")"
    log_info "Ligand ${ligand_name}: submitted complex prep job ${job_id}"
}

if [[ -n "${LIGAND_OVERRIDE}" ]]; then
    LIGAND_LIST_CFG="${LIGAND_OVERRIDE}"
fi

declare -a TARGETS=()
discover_ligands "${LIGAND_LIST_CFG}" TARGETS

if [[ ${#TARGETS[@]} -eq 0 ]]; then
    log_error "No ligand directories discovered under ${LIGAND_DIR} (pattern: ${LIGAND_PATTERN})"
    exit 1
fi

log_info "Preparing ${#TARGETS[@]} ligand complex(es) in mode=${MODE}"

for lig_path in "${TARGETS[@]}"; do
    lig_name="$(basename "${lig_path}")"

    lig_itp="$(resolve_single_match "${lig_path}" "${LIGAND_ITP_KEY}" "*.itp")" || {
        log_error "No ligand ITP found for ${lig_name} in ${lig_path}"
        exit 1
    }
    lig_gro="$(resolve_single_match "${lig_path}" "${LIGAND_GRO_KEY}" "*.gro")" || {
        log_error "No ligand GRO found for ${lig_name} in ${lig_path}"
        exit 1
    }

    submit_prepare_job "${lig_name}" "${lig_path}" "${lig_itp}" "${lig_gro}"
done

log_info "Complex preparation submission complete"
