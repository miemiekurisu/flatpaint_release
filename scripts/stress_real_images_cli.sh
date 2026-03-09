#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

INPUT_DIR="$ROOT_DIR/scripts/testPic"
CLI_BIN="$ROOT_DIR/flatpaint_cli"
STEPS_PER_IMAGE=20
SEED="${SEED:-20260309}"
RUN_TAG="$(date '+%Y%m%d_%H%M%S')"
RUN_ROOT="/tmp/flatpaint_real_stress_${RUN_TAG}"
PERF_ROOT="$ROOT_DIR/tests/performance"
REPORT_DIR="$PERF_ROOT/real_images_${RUN_TAG}"
HISTORY_FILE="$PERF_ROOT/real_images_history.tsv"

usage() {
  cat <<'EOF'
Usage:
  bash ./scripts/stress_real_images_cli.sh [options]

Options:
  --input-dir <dir>       Input directory with source images (default: scripts/testPic)
  --steps <n>             Random operation count per image (default: 20)
  --seed <n>              Random seed for reproducibility (default: 20260309 or $SEED)
  --report-dir <dir>      Output report directory (default: tests/performance/real_images_<timestamp>)
  --run-root <dir>        Temporary working root (default: /tmp/flatpaint_real_stress_<timestamp>)
  --cli <path>            flatpaint_cli path (default: ./flatpaint_cli)
  --help                  Show this help

Behavior:
  - Copies originals into /tmp working directory and never mutates source files.
  - Runs random heavy operations (filters + complex lasso/wand + crop/resize/rotate).
  - Captures per-operation /usr/bin/time -l metrics (CPU + peak RSS + peak footprint).
  - Captures macOS system logs for the run window.
EOF
}

log() {
  printf '==> %s\n' "$*"
}

rand_int() {
  local min="$1"
  local max="$2"
  echo $((min + RANDOM % (max - min + 1)))
}

read_dims() {
  local image_path="$1"
  local w
  local h
  w="$(sips -g pixelWidth "$image_path" 2>/dev/null | awk '/pixelWidth/ {print $2}')"
  h="$(sips -g pixelHeight "$image_path" 2>/dev/null | awk '/pixelHeight/ {print $2}')"
  if [[ -z "$w" || -z "$h" ]]; then
    echo "0 0"
  else
    echo "$w $h"
  fi
}

generate_polygon_points() {
  local width="$1"
  local height="$2"
  local count="$3"
  local points=()
  local i
  local x
  local y
  for ((i=0; i<count; i++)); do
    x=$((RANDOM % width))
    y=$((RANDOM % height))
    points+=("$x" "$y")
  done
  printf '%s\n' "${points[*]}"
}

run_timed_op() {
  local op_index="$1"
  local image_name="$2"
  local op_name="$3"
  local input_file="$4"
  local output_file="$5"
  shift 5

  local log_file="$REPORT_DIR/ops/op_${op_index}_${op_name}.log"
  local cmd_desc="$*"
  local exit_code=0

  if ! (/usr/bin/time -l "$@") >"$log_file.stdout" 2>"$log_file"; then
    exit_code=$?
  fi

  local real_sec
  local user_sec
  local sys_sec
  local max_rss
  local peak_footprint
  real_sec="$(awk 'NR==1 {print $1}' "$log_file" 2>/dev/null || true)"
  user_sec="$(awk 'NR==1 {print $3}' "$log_file" 2>/dev/null || true)"
  sys_sec="$(awk 'NR==1 {print $5}' "$log_file" 2>/dev/null || true)"
  max_rss="$(awk '/maximum resident set size/ {print $1; exit}' "$log_file" 2>/dev/null || true)"
  peak_footprint="$(awk '/peak memory footprint/ {print $1; exit}' "$log_file" 2>/dev/null || true)"

  if [[ -z "$real_sec" ]]; then real_sec="0"; fi
  if [[ -z "$user_sec" ]]; then user_sec="0"; fi
  if [[ -z "$sys_sec" ]]; then sys_sec="0"; fi
  if [[ -z "$max_rss" ]]; then max_rss="0"; fi
  if [[ -z "$peak_footprint" ]]; then peak_footprint="0"; fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$op_index" "$image_name" "$op_name" "$input_file" "$output_file" "$exit_code" \
    "$real_sec" "$user_sec" "$sys_sec" "$max_rss" "$peak_footprint" "$cmd_desc" >>"$REPORT_DIR/metrics.tsv"

  return "$exit_code"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input-dir)
      INPUT_DIR="$2"
      shift 2
      ;;
    --steps)
      STEPS_PER_IMAGE="$2"
      shift 2
      ;;
    --seed)
      SEED="$2"
      shift 2
      ;;
    --report-dir)
      REPORT_DIR="$2"
      shift 2
      ;;
    --run-root)
      RUN_ROOT="$2"
      shift 2
      ;;
    --cli)
      CLI_BIN="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ ! -x "$CLI_BIN" ]]; then
  printf 'flatpaint_cli not found or not executable: %s\n' "$CLI_BIN" >&2
  exit 2
fi

if [[ ! -d "$INPUT_DIR" ]]; then
  printf 'Input directory not found: %s\n' "$INPUT_DIR" >&2
  exit 2
fi

mkdir -p "$RUN_ROOT/originals" "$RUN_ROOT/work" "$REPORT_DIR/ops" "$REPORT_DIR/logs"

RANDOM="$SEED"

SOURCE_IMAGES=()
while IFS= read -r image_path; do
  SOURCE_IMAGES+=("$image_path")
done < <(find "$INPUT_DIR" -maxdepth 1 -type f | sort)
if [[ "${#SOURCE_IMAGES[@]}" -eq 0 ]]; then
  printf 'No source images found in %s\n' "$INPUT_DIR" >&2
  exit 2
fi

printf 'op_index\timage_name\top_name\tinput_file\toutput_file\texit_code\treal_sec\tuser_sec\tsys_sec\tmax_rss_bytes\tpeak_footprint_bytes\tcommand\n' >"$REPORT_DIR/metrics.tsv"

RUN_START_HUMAN="$(date '+%Y-%m-%d %H:%M:%S')"
RUN_START_EPOCH="$(date '+%s')"

log "Stress run root: $RUN_ROOT"
log "Report directory: $REPORT_DIR"
log "Random seed: $SEED"
log "Images: ${#SOURCE_IMAGES[@]}, steps per image: $STEPS_PER_IMAGE"

OP_INDEX=0

for source in "${SOURCE_IMAGES[@]}"; do
  image_name="$(basename "$source")"
  base_name="${image_name%.*}"
  cp -f "$source" "$RUN_ROOT/originals/$image_name"

  read -r width height <<<"$(read_dims "$source")"
  if (( width <= 0 || height <= 0 )); then
    log "Skipping unreadable image: $source"
    continue
  fi

  current="$RUN_ROOT/work/${base_name}_00.png"
  OP_INDEX=$((OP_INDEX + 1))
  run_timed_op "$OP_INDEX" "$image_name" "normalize_png" "$source" "$current" \
    "$CLI_BIN" resize "$source" "$current" "$width" "$height" || true

  if [[ ! -f "$current" ]]; then
    log "Failed to normalize image, skipping: $source"
    continue
  fi

  for ((step=1; step<=STEPS_PER_IMAGE; step++)); do
    op_choice=$((RANDOM % 13))
    next="$RUN_ROOT/work/${base_name}_$(printf '%02d' "$step").png"
    op_name=""
    cmd=()

    read -r width height <<<"$(read_dims "$current")"
    if (( width <= 8 || height <= 8 )); then
      width=32
      height=32
    fi

    case "$op_choice" in
      0)
        radius="$(rand_int 1 8)"
        op_name="blur"
        cmd=("$CLI_BIN" blur "$current" "$next" "$radius")
        ;;
      1)
        amount="$(rand_int 8 60)"
        op_name="noise"
        cmd=("$CLI_BIN" noise "$current" "$next" "$amount")
        ;;
      2)
        delta="$(rand_int -90 90)"
        op_name="brightness"
        cmd=("$CLI_BIN" brightness "$current" "$next" "$delta")
        ;;
      3)
        amount="$(rand_int -80 80)"
        op_name="contrast"
        cmd=("$CLI_BIN" contrast "$current" "$next" "$amount")
        ;;
      4)
        levels="$(rand_int 2 12)"
        op_name="posterize"
        cmd=("$CLI_BIN" posterize "$current" "$next" "$levels")
        ;;
      5)
        op_name="outline"
        cmd=("$CLI_BIN" outline "$current" "$next")
        ;;
      6)
        points="$(generate_polygon_points "$width" "$height" 120)"
        r="$(rand_int 0 255)"
        g="$(rand_int 0 255)"
        b="$(rand_int 0 255)"
        op_name="filllasso_complex"
        cmd=("$CLI_BIN" filllasso "$current" "$next" "$r" "$g" "$b")
        for point in $points; do cmd+=("$point"); done
        ;;
      7)
        points="$(generate_polygon_points "$width" "$height" 120)"
        op_name="eraselasso_complex"
        cmd=("$CLI_BIN" eraselasso "$current" "$next")
        for point in $points; do cmd+=("$point"); done
        ;;
      8)
        points="$(generate_polygon_points "$width" "$height" 120)"
        dx="$(rand_int -120 120)"
        dy="$(rand_int -120 120)"
        op_name="movepixelslasso_complex"
        cmd=("$CLI_BIN" movepixelslasso "$current" "$next" "$dx" "$dy")
        for point in $points; do cmd+=("$point"); done
        ;;
      9)
        x="$(rand_int 0 $((width - 1)))"
        y="$(rand_int 0 $((height - 1)))"
        tolerance="$(rand_int 8 96)"
        r="$(rand_int 0 255)"
        g="$(rand_int 0 255)"
        b="$(rand_int 0 255)"
        op_name="fillwand"
        cmd=("$CLI_BIN" fillwand "$current" "$next" "$x" "$y" "$tolerance" "$r" "$g" "$b")
        ;;
      10)
        x1="$(rand_int 0 $((width / 4)))"
        y1="$(rand_int 0 $((height / 4)))"
        x2="$(rand_int $((width / 2)) $((width - 1)))"
        y2="$(rand_int $((height / 2)) $((height - 1)))"
        op_name="croprect"
        cmd=("$CLI_BIN" croprect "$current" "$next" "$x1" "$y1" "$x2" "$y2")
        ;;
      11)
        new_w="$(rand_int $((width * 3 / 4)) $((width * 5 / 4)))"
        new_h="$(rand_int $((height * 3 / 4)) $((height * 5 / 4)))"
        if (( new_w < 64 )); then new_w=64; fi
        if (( new_h < 64 )); then new_h=64; fi
        op_name="resize"
        cmd=("$CLI_BIN" resize "$current" "$next" "$new_w" "$new_h")
        ;;
      12)
        if (( RANDOM % 2 == 0 )); then
          op_name="rotcw"
          cmd=("$CLI_BIN" rotcw "$current" "$next")
        else
          op_name="rotccw"
          cmd=("$CLI_BIN" rotccw "$current" "$next")
        fi
        ;;
    esac

    OP_INDEX=$((OP_INDEX + 1))
    if run_timed_op "$OP_INDEX" "$image_name" "$op_name" "$current" "$next" "${cmd[@]}"; then
      if [[ -f "$next" ]]; then
        current="$next"
      fi
    else
      rm -f "$next"
    fi
  done

  doc_path="$RUN_ROOT/work/${base_name}.fpd"
  merged_doc="$RUN_ROOT/work/${base_name}.merged.fpd"
  export_png="$RUN_ROOT/work/${base_name}.export.png"
  export_bmp="$RUN_ROOT/work/${base_name}.export.bmp"
  export_tga="$RUN_ROOT/work/${base_name}.export.tga"
  export_tiff="$RUN_ROOT/work/${base_name}.export.tiff"

  OP_INDEX=$((OP_INDEX + 1))
  run_timed_op "$OP_INDEX" "$image_name" "wrapdoc" "$current" "$doc_path" \
    "$CLI_BIN" wrapdoc "$current" "$doc_path" || true

  OP_INDEX=$((OP_INDEX + 1))
  run_timed_op "$OP_INDEX" "$image_name" "addlayerdoc" "$doc_path" "$merged_doc" \
    "$CLI_BIN" addlayerdoc "$doc_path" "$RUN_ROOT/originals/$image_name" "$merged_doc" || true

  OP_INDEX=$((OP_INDEX + 1))
  run_timed_op "$OP_INDEX" "$image_name" "flattendoc" "$merged_doc" "$doc_path" \
    "$CLI_BIN" flattendoc "$merged_doc" "$doc_path" || true

  OP_INDEX=$((OP_INDEX + 1))
  run_timed_op "$OP_INDEX" "$image_name" "export_png" "$doc_path" "$export_png" \
    "$CLI_BIN" exportdoc "$doc_path" "$export_png" || true

  OP_INDEX=$((OP_INDEX + 1))
  run_timed_op "$OP_INDEX" "$image_name" "export_bmp" "$doc_path" "$export_bmp" \
    "$CLI_BIN" exportdoc "$doc_path" "$export_bmp" || true

  OP_INDEX=$((OP_INDEX + 1))
  run_timed_op "$OP_INDEX" "$image_name" "export_tga" "$doc_path" "$export_tga" \
    "$CLI_BIN" exportdoc "$doc_path" "$export_tga" || true

  OP_INDEX=$((OP_INDEX + 1))
  run_timed_op "$OP_INDEX" "$image_name" "export_tiff" "$doc_path" "$export_tiff" \
    "$CLI_BIN" exportdoc "$doc_path" "$export_tiff" || true
done

RUN_END_HUMAN="$(date '+%Y-%m-%d %H:%M:%S')"
RUN_END_EPOCH="$(date '+%s')"

/usr/bin/log show --style compact --start "$RUN_START_HUMAN" --end "$RUN_END_HUMAN" \
  --predicate 'process == "flatpaint_cli" || process == "FlatPaint"' \
  >"$REPORT_DIR/logs/system_flatpaint.log" 2>&1 || true

/usr/bin/log show --style compact --start "$RUN_START_HUMAN" --end "$RUN_END_HUMAN" \
  --predicate '(process == "flatpaint_cli" || process == "FlatPaint") && (eventMessage CONTAINS[c] "error" || eventMessage CONTAINS[c] "fault" || eventMessage CONTAINS[c] "exception" || eventMessage CONTAINS[c] "oom" || eventMessage CONTAINS[c] "malloc")' \
  >"$REPORT_DIR/logs/system_flatpaint_errors.log" 2>&1 || true

{
  printf "op_name\tcount\tavg_real_sec\tavg_user_sec\tavg_sys_sec\tmax_real_sec\tmax_rss_mb\n"
  awk -F'\t' '
  NR == 1 { next }
  $6 == 0 {
    op = $3
    count[op]++
    real_sum[op] += $7
    user_sum[op] += $8
    sys_sum[op] += $9
    if ($7 > real_max[op]) real_max[op] = $7
    if ($10 > rss_max[op]) rss_max[op] = $10
  }
  END {
    for (op in count) {
      printf "%s\t%d\t%.4f\t%.4f\t%.4f\t%.4f\t%.2f\n",
        op, count[op], real_sum[op]/count[op], user_sum[op]/count[op], sys_sum[op]/count[op], real_max[op], rss_max[op]/1024/1024
    }
  }
  ' "$REPORT_DIR/metrics.tsv" | sort
} >"$REPORT_DIR/op_summary.tsv"

peak_rss_bytes="$(awk -F'\t' 'NR>1 && $10+0 > max { max=$10+0 } END { print max+0 }' "$REPORT_DIR/metrics.tsv")"
slowest_real_sec="$(awk -F'\t' 'NR>1 && $7+0 > max { max=$7+0 } END { print max+0 }' "$REPORT_DIR/metrics.tsv")"
failed_ops="$(awk -F'\t' 'NR>1 && $6 != 0 { c++ } END { print c+0 }' "$REPORT_DIR/metrics.tsv")"
total_ops="$(awk -F'\t' 'NR>1 { c++ } END { print c+0 }' "$REPORT_DIR/metrics.tsv")"

{
  printf 'run_start=%s\n' "$RUN_START_HUMAN"
  printf 'run_end=%s\n' "$RUN_END_HUMAN"
  printf 'run_seconds=%s\n' "$((RUN_END_EPOCH - RUN_START_EPOCH))"
  printf 'seed=%s\n' "$SEED"
  printf 'input_dir=%s\n' "$INPUT_DIR"
  printf 'run_root=%s\n' "$RUN_ROOT"
  printf 'report_dir=%s\n' "$REPORT_DIR"
  printf 'steps_per_image=%s\n' "$STEPS_PER_IMAGE"
  printf 'image_count=%s\n' "${#SOURCE_IMAGES[@]}"
  printf 'metrics=%s\n' "$REPORT_DIR/metrics.tsv"
  printf 'summary=%s\n' "$REPORT_DIR/op_summary.tsv"
  printf 'system_log=%s\n' "$REPORT_DIR/logs/system_flatpaint.log"
  printf 'system_error_log=%s\n' "$REPORT_DIR/logs/system_flatpaint_errors.log"
  printf 'history_file=%s\n' "$HISTORY_FILE"
} >"$REPORT_DIR/run_summary.txt"

mkdir -p "$(dirname "$HISTORY_FILE")"
if [[ ! -f "$HISTORY_FILE" ]]; then
  printf 'run_tag\trun_start\trun_end\trun_seconds\tseed\tsteps_per_image\timage_count\ttotal_ops\tfailed_ops\tpeak_rss_mb\tslowest_real_sec\treport_dir\trun_summary\n' >"$HISTORY_FILE"
fi
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%.2f\t%.4f\t%s\t%s\n' \
  "$RUN_TAG" "$RUN_START_HUMAN" "$RUN_END_HUMAN" "$((RUN_END_EPOCH - RUN_START_EPOCH))" \
  "$SEED" "$STEPS_PER_IMAGE" "${#SOURCE_IMAGES[@]}" "$total_ops" "$failed_ops" \
  "$(awk -v b="$peak_rss_bytes" 'BEGIN { print b / 1024 / 1024 }')" "$slowest_real_sec" \
  "$REPORT_DIR" "$REPORT_DIR/run_summary.txt" >>"$HISTORY_FILE"

{
  printf 'Top 10 by peak RSS (MB)\n'
  printf 'op_index\timage_name\top_name\treal_sec\tmax_rss_mb\n'
  awk -F'\t' 'NR>1 {printf "%s\t%s\t%s\t%s\t%.2f\n", $1, $2, $3, $7, $10/1024/1024}' \
    "$REPORT_DIR/metrics.tsv" | sort -t$'\t' -k5,5nr | head -n 10
  printf '\nTop 10 by real time (sec)\n'
  printf 'op_index\timage_name\top_name\treal_sec\tmax_rss_mb\n'
  awk -F'\t' 'NR>1 {printf "%s\t%s\t%s\t%s\t%.2f\n", $1, $2, $3, $7, $10/1024/1024}' \
    "$REPORT_DIR/metrics.tsv" | sort -t$'\t' -k4,4nr | head -n 10
  printf '\nFailures: %s / %s\n' "$failed_ops" "$total_ops"
} >"$REPORT_DIR/hotspots.txt"

log "Run summary: $REPORT_DIR/run_summary.txt"
log "Operation metrics: $REPORT_DIR/metrics.tsv"
log "Operation summary: $REPORT_DIR/op_summary.tsv"
log "Hotspot report: $REPORT_DIR/hotspots.txt"
log "History index: $HISTORY_FILE"
