#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../infra/common.sh"

print_help() {
    cat <<'EOF'
Usage: 3_dock_report.sh [options]

Generate ranked docking score reports across ligands × receptors.

Options:
  --config <path>      Config file path (default: config.ini)
  --dock-dir <path>    Docking directory containing gnina *.sdf outputs
  --output <path>      Output report path
  --format <fmt>       Output format: csv|text (default: csv)
  --top-n <N>          Keep top N poses after ranking (default: 0 = all)
  -h, --help           Show this help message

Config keys used:
  [docking] dock_dir
  [docking] report_output
  [docking] report_format
  [docking] report_top_n
EOF
}

CONFIG_FILE="config.ini"
DOCK_DIR_OVERRIDE=""
OUTPUT_OVERRIDE=""
FORMAT_OVERRIDE=""
TOP_N_OVERRIDE=""

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
        --output)
            OUTPUT_OVERRIDE="$2"
            shift 2
            ;;
        --format)
            FORMAT_OVERRIDE="$2"
            shift 2
            ;;
        --top-n)
            TOP_N_OVERRIDE="$2"
            shift 2
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

init_script "3_dock_report.sh" "${CONFIG_FILE}"

DOCK_DIR="$(get_config docking dock_dir "$(pwd)/dock")"
OUTPUT_PATH="$(get_config docking report_output "${DOCK_DIR}/dock_report.csv")"
OUTPUT_FORMAT="$(get_config docking report_format "csv")"
TOP_N="$(get_config docking report_top_n "0")"

[[ -n "${DOCK_DIR_OVERRIDE}" ]] && DOCK_DIR="${DOCK_DIR_OVERRIDE}"
[[ -n "${OUTPUT_OVERRIDE}" ]] && OUTPUT_PATH="${OUTPUT_OVERRIDE}"
[[ -n "${FORMAT_OVERRIDE}" ]] && OUTPUT_FORMAT="${FORMAT_OVERRIDE}"
[[ -n "${TOP_N_OVERRIDE}" ]] && TOP_N="${TOP_N_OVERRIDE}"

if [[ "${OUTPUT_FORMAT}" != "csv" && "${OUTPUT_FORMAT}" != "text" ]]; then
    log_error "Invalid --format '${OUTPUT_FORMAT}'. Use csv or text."
    exit 1
fi

if ! [[ "${TOP_N}" =~ ^[0-9]+$ ]]; then
    log_error "Invalid --top-n '${TOP_N}'. Must be a non-negative integer."
    exit 1
fi

require_dir "${DOCK_DIR}" "Docking directory not found: ${DOCK_DIR}"

python - "${DOCK_DIR}" "${OUTPUT_PATH}" "${OUTPUT_FORMAT}" "${TOP_N}" <<'PY'
from __future__ import annotations

import csv
import re
import sys
from pathlib import Path
from typing import Dict, List


def parse_sdf_models(path: Path) -> List[Dict[str, object]]:
    text = path.read_text(encoding="utf-8", errors="replace")
    records = [r.strip() for r in text.split("$$$$") if r.strip()]
    models: List[Dict[str, object]] = []
    for idx, rec in enumerate(records, start=1):
        scores: Dict[str, float] = {}
        lines = rec.splitlines()
        for i, line in enumerate(lines):
            if line.startswith("> <"):
                key = line[3:].strip().rstrip(">")
                if i + 1 < len(lines):
                    try:
                        scores[key] = float(lines[i + 1].strip())
                    except ValueError:
                        continue
        models.append({"pose": idx, "scores": scores})
    return models


def ligand_receptor_from_name(name: str) -> tuple[str, str]:
    stem = Path(name).stem
    m = re.match(r"(?P<rec>[^-]+)-(?P<lig>.+)$", stem)
    if m:
        return m.group("lig"), m.group("rec")
    return stem, "unknown"


def get_score(scores: Dict[str, float], keys: List[str]) -> float | None:
    for k in keys:
        if k in scores:
            return scores[k]
    return None


def rank_key(row: Dict[str, object]) -> tuple[float, float, float]:
    cnn = row.get("cnnscore")
    affinity = row.get("minimizedAffinity")
    rmsd = row.get("rmsd")
    cnn_sort = -(cnn if isinstance(cnn, float) else float("-inf"))
    aff_sort = affinity if isinstance(affinity, float) else float("inf")
    rmsd_sort = rmsd if isinstance(rmsd, float) else float("inf")
    return (cnn_sort, aff_sort, rmsd_sort)


def main() -> int:
    dock_dir = Path(sys.argv[1]).resolve()
    output_path = Path(sys.argv[2]).resolve()
    out_format = sys.argv[3]
    top_n = int(sys.argv[4])

    sdf_files = sorted(dock_dir.rglob("*.sdf"))
    if not sdf_files:
        raise FileNotFoundError(f"No SDF files found under {dock_dir}")

    rows: List[Dict[str, object]] = []
    for sdf in sdf_files:
        ligand, receptor = ligand_receptor_from_name(sdf.name)
        for model in parse_sdf_models(sdf):
            scores = model["scores"]
            rows.append(
                {
                    "file": str(sdf.relative_to(dock_dir)),
                    "receptor": receptor,
                    "ligand": ligand,
                    "pose": model["pose"],
                    "minimizedAffinity": get_score(scores, ["minimizedAffinity", "Vina score", "vina_score"]),
                    "cnnscore": get_score(scores, ["CNNscore", "cnnscore"]),
                    "cnnaffinity": get_score(scores, ["CNNaffinity", "cnnaffinity"]),
                    "rmsd": get_score(scores, ["RMSD", "rmsd", "rmsd/lb", "rmsd_ub"]),
                }
            )

    rows.sort(key=rank_key)
    if top_n > 0:
        rows = rows[:top_n]

    output_path.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = ["rank", "file", "receptor", "ligand", "pose", "minimizedAffinity", "cnnscore", "cnnaffinity", "rmsd"]

    if out_format == "csv":
        with output_path.open("w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(handle, fieldnames=fieldnames)
            writer.writeheader()
            for rank, row in enumerate(rows, start=1):
                writer.writerow({"rank": rank, **row})
    else:
        with output_path.open("w", encoding="utf-8") as handle:
            handle.write("\t".join(fieldnames) + "\n")
            for rank, row in enumerate(rows, start=1):
                values = [
                    str(rank),
                    str(row["file"]),
                    str(row["receptor"]),
                    str(row["ligand"]),
                    str(row["pose"]),
                    "" if row["minimizedAffinity"] is None else f"{row['minimizedAffinity']:.4f}",
                    "" if row["cnnscore"] is None else f"{row['cnnscore']:.4f}",
                    "" if row["cnnaffinity"] is None else f"{row['cnnaffinity']:.4f}",
                    "" if row["rmsd"] is None else f"{row['rmsd']:.4f}",
                ]
                handle.write("\t".join(values) + "\n")

    print(f"Wrote docking report: {output_path}")
    print(f"Entries: {len(rows)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY

log_info "Docking report written to ${OUTPUT_PATH}"
