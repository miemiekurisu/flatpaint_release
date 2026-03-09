#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

INPUT_DIR="$ROOT_DIR/scripts/testPic"
CLI_BIN="$ROOT_DIR/flatpaint_cli"
PERF_ROOT="$ROOT_DIR/tests/performance"
RUN_TAG="$(date '+%Y%m%d_%H%M%S')"
RUN_ROOT="/tmp/flatpaint_tool_menu_coverage_${RUN_TAG}"
REPORT_DIR="$PERF_ROOT/tool_menu_coverage_${RUN_TAG}"
HISTORY_FILE="$PERF_ROOT/tool_menu_coverage_history.tsv"

SEED="${SEED:-20260309}"
EXTRA_MIN=12
EXTRA_MAX=24
MAX_IMAGES=0

OP_INDEX=0
SEED_CURSOR=0
CURRENT_IMAGE=""
DOC_PATH=""
DOC_LAYER_COUNT=0
DOC_ACTIVE_LAYER=0
BASE_WIDTH=0
BASE_HEIGHT=0
IMAGE_STEM=""
RUN_START_HUMAN=""
RUN_START_EPOCH=0
RUN_END_HUMAN=""
RUN_END_EPOCH=0

RASTER_REQUIRED=(
  brush erase fill gradient line rect ellipse fillrect fillellipse
  eraserect movepixelsrect croprect
  filllasso eraselasso movepixelslasso extractrect extractlasso
  fillwand erasewand movepixelswand cropwand extractwand
  crop resize fliph flipv rot180 rotcw rotccw
  autolevel invert grayscale brightness contrast sepia blackwhite posterize blur sharpen noise outline
)

DOC_REQUIRED=(
  wrapdoc addlayerdoc pastedoc
  setactivedoc duplayerdoc movelayerdoc renamelayerdoc deletelayerdoc
  setvisibledoc setopacitydoc exportlayerdoc mergedowndoc flattendoc rot180doc
  autoleveldoc invertdoc grayscaledoc brightnessdoc contrastdoc sepiadoc
  blackwhitedoc posterizedoc blurdoc sharpendoc noisedoc outlinedoc
  exportdoc_png exportdoc_bmp exportdoc_tga exportdoc_tiff
)

EXTRA_POOL=(
  blur noise posterize contrast brightness
  movepixelslasso filllasso eraselasso movepixelswand fillwand erasewand
  wrapdoc addlayerdoc flattendoc exportdoc_png exportdoc_tiff
)

usage() {
  cat <<'EOF'
Usage:
  bash ./scripts/stress_tool_menu_coverage_cli.sh [options]

Options:
  --input-dir <dir>      Input directory with source images (default: scripts/testPic)
  --cli <path>           flatpaint_cli path (default: ./flatpaint_cli)
  --seed <n>             Random seed for reproducibility (default: 20260309 or $SEED)
  --extra-min <n>        Minimum random extra operations per image (default: 12)
  --extra-max <n>        Maximum random extra operations per image (default: 24)
  --max-images <n>       Limit number of images processed (default: 0 = all)
  --report-dir <dir>     Output report directory (default: tests/performance/tool_menu_coverage_<timestamp>)
  --run-root <dir>       Temporary working root (default: /tmp/flatpaint_tool_menu_coverage_<timestamp>)
  --help                 Show this help

Behavior:
  - Copies originals to /tmp and never mutates source files.
  - Ensures all required tool/menu operations execute at least once.
  - Randomizes operation order and adds random extra repetitions.
  - Avoids trivial no-op style sequences by using meaningful parameters and non-zero motion deltas.
  - Captures per-operation /usr/bin/time -l metrics and run-window system logs.
EOF
}

log() {
  printf '==> %s\n' "$*"
}

rand_int() {
  local min="$1"
  local max="$2"
  if (( max <= min )); then
    printf '%s\n' "$min"
    return 0
  fi
  printf '%s\n' $((min + RANDOM % (max - min + 1)))
}

rand_nonzero() {
  local min="$1"
  local max="$2"
  local value=0
  if (( max < min )); then
    value="$min"
  fi
  if (( min == 0 && max == 0 )); then
    printf '1\n'
    return 0
  fi
  while (( value == 0 )); do
    value="$(rand_int "$min" "$max")"
  done
  printf '%s\n' "$value"
}

read_dims() {
  local image_path="$1"
  local w
  local h
  w="$(sips -g pixelWidth "$image_path" 2>/dev/null | awk '/pixelWidth/ {print $2}')"
  h="$(sips -g pixelHeight "$image_path" 2>/dev/null | awk '/pixelHeight/ {print $2}')"
  if [[ -z "$w" || -z "$h" ]]; then
    printf '0 0\n'
  else
    printf '%s %s\n' "$w" "$h"
  fi
}

shuffle_values() {
  local seed="$1"
  shift
  if [[ "$#" -eq 0 ]]; then
    return 0
  fi
  printf '%s\n' "$@" \
    | awk -v seed="$seed" 'BEGIN { srand(seed) } { printf "%.16f\t%s\n", rand(), $0 }' \
    | sort -k1,1n \
    | cut -f2-
}

generate_polygon_points() {
  local width="$1"
  local height="$2"
  local count="$3"
  local points=()
  local i
  local x
  local y

  if (( width <= 1 )); then width=2; fi
  if (( height <= 1 )); then height=2; fi

  for ((i=0; i<count; i++)); do
    x=$((RANDOM % width))
    y=$((RANDOM % height))
    points+=("$x" "$y")
  done
  printf '%s\n' "${points[*]}"
}

unique_work_path() {
  local tag="$1"
  local ext="$2"
  local candidate
  while :; do
    candidate="$RUN_ROOT/work/${IMAGE_STEM}_${tag}_${RANDOM}.${ext}"
    if [[ ! -e "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
}

choose_rect_xyxy() {
  local width="$1"
  local height="$2"
  local x1
  local y1
  local x2
  local y2

  if (( width < 2 )); then width=2; fi
  if (( height < 2 )); then height=2; fi

  x1="$(rand_int 0 $((width - 2)))"
  y1="$(rand_int 0 $((height - 2)))"
  x2="$(rand_int 1 $((width - 1)))"
  y2="$(rand_int 1 $((height - 1)))"

  if (( x2 <= x1 )); then
    x2=$((x1 + 1))
    if (( x2 >= width )); then x2=$((width - 1)); fi
  fi
  if (( y2 <= y1 )); then
    y2=$((y1 + 1))
    if (( y2 >= height )); then y2=$((height - 1)); fi
  fi
  printf '%s %s %s %s\n' "$x1" "$y1" "$x2" "$y2"
}

choose_crop_xywh() {
  local width="$1"
  local height="$2"
  local cw
  local ch
  local x
  local y
  local min_w
  local min_h

  if (( width < 64 )); then width=64; fi
  if (( height < 64 )); then height=64; fi

  min_w=$((width / 2))
  min_h=$((height / 2))
  if (( min_w < 64 )); then min_w=64; fi
  if (( min_h < 64 )); then min_h=64; fi

  cw="$(rand_int "$min_w" "$width")"
  ch="$(rand_int "$min_h" "$height")"
  if (( cw >= width )); then cw=$((width - 1)); fi
  if (( ch >= height )); then ch=$((height - 1)); fi
  if (( cw < 1 )); then cw=1; fi
  if (( ch < 1 )); then ch=1; fi

  x="$(rand_int 0 $((width - cw)))"
  y="$(rand_int 0 $((height - ch)))"
  printf '%s %s %s %s\n' "$x" "$y" "$cw" "$ch"
}

run_timed_cmd() {
  local image_name="$1"
  local phase="$2"
  local op_name="$3"
  local target_kind="$4"
  local input_path="$5"
  local output_path="$6"
  shift 6
  local cmd=("$@")

  OP_INDEX=$((OP_INDEX + 1))
  local op_id="$OP_INDEX"
  local log_base="$REPORT_DIR/ops/op_${op_id}_${op_name}"
  local exit_code=0

  if ! (/usr/bin/time -l "${cmd[@]}") >"${log_base}.stdout" 2>"${log_base}.log"; then
    exit_code=$?
  fi

  local real_sec
  local user_sec
  local sys_sec
  local max_rss
  local peak_footprint
  local cmd_desc

  real_sec="$(awk 'NR==1 {print $1}' "${log_base}.log" 2>/dev/null || true)"
  user_sec="$(awk 'NR==1 {print $3}' "${log_base}.log" 2>/dev/null || true)"
  sys_sec="$(awk 'NR==1 {print $5}' "${log_base}.log" 2>/dev/null || true)"
  max_rss="$(awk '/maximum resident set size/ {print $1; exit}' "${log_base}.log" 2>/dev/null || true)"
  peak_footprint="$(awk '/peak memory footprint/ {print $1; exit}' "${log_base}.log" 2>/dev/null || true)"
  cmd_desc="${cmd[*]}"

  if [[ -z "$real_sec" ]]; then real_sec="0"; fi
  if [[ -z "$user_sec" ]]; then user_sec="0"; fi
  if [[ -z "$sys_sec" ]]; then sys_sec="0"; fi
  if [[ -z "$max_rss" ]]; then max_rss="0"; fi
  if [[ -z "$peak_footprint" ]]; then peak_footprint="0"; fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$op_id" "$image_name" "$phase" "$op_name" "$target_kind" "$input_path" "$output_path" "$exit_code" \
    "$real_sec" "$user_sec" "$sys_sec" "$max_rss" "$peak_footprint" "$cmd_desc" >>"$REPORT_DIR/metrics.tsv"

  return "$exit_code"
}

rebalance_current_image_if_needed() {
  local image_name="$1"
  local phase="$2"
  local width
  local height
  local min_w
  local min_h
  local rebalance_path

  read -r width height <<<"$(read_dims "$CURRENT_IMAGE")"
  if (( width <= 0 || height <= 0 )); then
    return 0
  fi

  min_w=$((BASE_WIDTH / 2))
  min_h=$((BASE_HEIGHT / 2))
  if (( min_w < 1024 )); then min_w=1024; fi
  if (( min_h < 768 )); then min_h=768; fi

  if (( width < min_w || height < min_h )); then
    rebalance_path="$(unique_work_path "internal_rebalance" "png")"
    if run_timed_cmd "$image_name" "$phase" "internal_resize_rebalance" "raster" "$CURRENT_IMAGE" "$rebalance_path" \
      "$CLI_BIN" resize "$CURRENT_IMAGE" "$rebalance_path" "$BASE_WIDTH" "$BASE_HEIGHT"; then
      if [[ -f "$rebalance_path" ]]; then
        CURRENT_IMAGE="$rebalance_path"
      fi
    fi
  fi
}

ensure_doc_exists() {
  local image_name="$1"
  if [[ -f "$DOC_PATH" ]]; then
    return 0
  fi
  run_doc_op "$image_name" "doc_internal" "wrapdoc" >/dev/null 2>&1 || true
  [[ -f "$DOC_PATH" ]]
}

ensure_doc_layers() {
  local image_name="$1"
  local min_layers="$2"
  local guard=0

  while (( DOC_LAYER_COUNT < min_layers )); do
    guard=$((guard + 1))
    if (( guard > 8 )); then
      return 1
    fi
    if ! run_doc_op "$image_name" "doc_internal" "addlayerdoc" >/dev/null 2>&1; then
      return 1
    fi
  done
  return 0
}

run_raster_op() {
  local image_name="$1"
  local phase="$2"
  local op_name="$3"
  local width
  local height
  local x
  local y
  local x1
  local y1
  local x2
  local y2
  local cw
  local ch
  local tolerance
  local dx
  local dy
  local radius
  local amount
  local levels
  local delta
  local color_r
  local color_g
  local color_b
  local points
  local next_path
  local artifact_path
  local update_current=1
  local ok=1

  read -r width height <<<"$(read_dims "$CURRENT_IMAGE")"
  if (( width <= 1 || height <= 1 )); then
    next_path="$(unique_work_path "internal_recover_resize" "png")"
    if run_timed_cmd "$image_name" "$phase" "internal_recover_resize" "raster" "$CURRENT_IMAGE" "$next_path" \
      "$CLI_BIN" resize "$CURRENT_IMAGE" "$next_path" "$BASE_WIDTH" "$BASE_HEIGHT"; then
      CURRENT_IMAGE="$next_path"
      read -r width height <<<"$(read_dims "$CURRENT_IMAGE")"
    fi
  fi
  if (( width <= 1 || height <= 1 )); then
    return 1
  fi

  next_path="$(unique_work_path "$op_name" "png")"
  artifact_path="$(unique_work_path "${op_name}_artifact" "png")"

  case "$op_name" in
    brush)
      x="$(rand_int 0 $((width - 1)))"
      y="$(rand_int 0 $((height - 1)))"
      radius="$(rand_int 6 40)"
      color_r="$(rand_int 0 255)"
      color_g="$(rand_int 0 255)"
      color_b="$(rand_int 0 255)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" brush "$CURRENT_IMAGE" "$next_path" "$x" "$y" "$radius" "$color_r" "$color_g" "$color_b"; then ok=0; fi
      ;;
    erase)
      x="$(rand_int 0 $((width - 1)))"
      y="$(rand_int 0 $((height - 1)))"
      radius="$(rand_int 6 36)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" erase "$CURRENT_IMAGE" "$next_path" "$x" "$y" "$radius"; then ok=0; fi
      ;;
    fill)
      x="$(rand_int 0 $((width - 1)))"
      y="$(rand_int 0 $((height - 1)))"
      color_r="$(rand_int 0 255)"
      color_g="$(rand_int 0 255)"
      color_b="$(rand_int 0 255)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" fill "$CURRENT_IMAGE" "$next_path" "$x" "$y" "$color_r" "$color_g" "$color_b"; then ok=0; fi
      ;;
    gradient)
      color_r="$(rand_int 0 255)"
      color_g="$(rand_int 0 255)"
      color_b="$(rand_int 0 255)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" gradient "$CURRENT_IMAGE" "$next_path" \
        0 0 "$((width - 1))" "$((height - 1))" \
        "$color_r" "$color_g" "$color_b" \
        "$((255 - color_r))" "$((255 - color_g))" "$((255 - color_b))"; then ok=0; fi
      ;;
    line)
      read -r x1 y1 x2 y2 <<<"$(choose_rect_xyxy "$width" "$height")"
      radius="$(rand_int 1 20)"
      color_r="$(rand_int 0 255)"
      color_g="$(rand_int 0 255)"
      color_b="$(rand_int 0 255)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" line "$CURRENT_IMAGE" "$next_path" "$x1" "$y1" "$x2" "$y2" "$radius" "$color_r" "$color_g" "$color_b"; then ok=0; fi
      ;;
    rect)
      read -r x1 y1 x2 y2 <<<"$(choose_rect_xyxy "$width" "$height")"
      radius="$(rand_int 1 16)"
      color_r="$(rand_int 0 255)"
      color_g="$(rand_int 0 255)"
      color_b="$(rand_int 0 255)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" rect "$CURRENT_IMAGE" "$next_path" "$x1" "$y1" "$x2" "$y2" "$radius" "$color_r" "$color_g" "$color_b"; then ok=0; fi
      ;;
    ellipse)
      read -r x1 y1 x2 y2 <<<"$(choose_rect_xyxy "$width" "$height")"
      radius="$(rand_int 1 16)"
      color_r="$(rand_int 0 255)"
      color_g="$(rand_int 0 255)"
      color_b="$(rand_int 0 255)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" ellipse "$CURRENT_IMAGE" "$next_path" "$x1" "$y1" "$x2" "$y2" "$radius" "$color_r" "$color_g" "$color_b"; then ok=0; fi
      ;;
    fillrect)
      read -r x1 y1 x2 y2 <<<"$(choose_rect_xyxy "$width" "$height")"
      color_r="$(rand_int 0 255)"
      color_g="$(rand_int 0 255)"
      color_b="$(rand_int 0 255)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" fillrect "$CURRENT_IMAGE" "$next_path" "$x1" "$y1" "$x2" "$y2" "$color_r" "$color_g" "$color_b"; then ok=0; fi
      ;;
    fillellipse)
      read -r x1 y1 x2 y2 <<<"$(choose_rect_xyxy "$width" "$height")"
      color_r="$(rand_int 0 255)"
      color_g="$(rand_int 0 255)"
      color_b="$(rand_int 0 255)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" fillellipse "$CURRENT_IMAGE" "$next_path" "$x1" "$y1" "$x2" "$y2" "$color_r" "$color_g" "$color_b"; then ok=0; fi
      ;;
    eraserect)
      read -r x1 y1 x2 y2 <<<"$(choose_rect_xyxy "$width" "$height")"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" eraserect "$CURRENT_IMAGE" "$next_path" "$x1" "$y1" "$x2" "$y2"; then ok=0; fi
      ;;
    movepixelsrect)
      read -r x1 y1 x2 y2 <<<"$(choose_rect_xyxy "$width" "$height")"
      dx="$(rand_nonzero -160 160)"
      dy="$(rand_nonzero -160 160)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" movepixelsrect "$CURRENT_IMAGE" "$next_path" "$x1" "$y1" "$x2" "$y2" "$dx" "$dy"; then ok=0; fi
      ;;
    croprect)
      read -r x1 y1 x2 y2 <<<"$(choose_rect_xyxy "$width" "$height")"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" croprect "$CURRENT_IMAGE" "$next_path" "$x1" "$y1" "$x2" "$y2"; then ok=0; fi
      ;;
    filllasso)
      points="$(generate_polygon_points "$width" "$height" 120)"
      color_r="$(rand_int 0 255)"
      color_g="$(rand_int 0 255)"
      color_b="$(rand_int 0 255)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" filllasso "$CURRENT_IMAGE" "$next_path" "$color_r" "$color_g" "$color_b" $points; then ok=0; fi
      ;;
    eraselasso)
      points="$(generate_polygon_points "$width" "$height" 120)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" eraselasso "$CURRENT_IMAGE" "$next_path" $points; then ok=0; fi
      ;;
    movepixelslasso)
      points="$(generate_polygon_points "$width" "$height" 120)"
      dx="$(rand_nonzero -180 180)"
      dy="$(rand_nonzero -180 180)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" movepixelslasso "$CURRENT_IMAGE" "$next_path" "$dx" "$dy" $points; then ok=0; fi
      ;;
    extractrect)
      update_current=0
      read -r x1 y1 x2 y2 <<<"$(choose_rect_xyxy "$width" "$height")"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "artifact" "$CURRENT_IMAGE" "$artifact_path" \
        "$CLI_BIN" extractrect "$CURRENT_IMAGE" "$artifact_path" "$x1" "$y1" "$x2" "$y2"; then ok=0; fi
      ;;
    extractlasso)
      update_current=0
      points="$(generate_polygon_points "$width" "$height" 120)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "artifact" "$CURRENT_IMAGE" "$artifact_path" \
        "$CLI_BIN" extractlasso "$CURRENT_IMAGE" "$artifact_path" $points; then ok=0; fi
      ;;
    fillwand)
      x="$(rand_int 0 $((width - 1)))"
      y="$(rand_int 0 $((height - 1)))"
      tolerance="$(rand_int 6 96)"
      color_r="$(rand_int 0 255)"
      color_g="$(rand_int 0 255)"
      color_b="$(rand_int 0 255)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" fillwand "$CURRENT_IMAGE" "$next_path" "$x" "$y" "$tolerance" "$color_r" "$color_g" "$color_b"; then ok=0; fi
      ;;
    erasewand)
      x="$(rand_int 0 $((width - 1)))"
      y="$(rand_int 0 $((height - 1)))"
      tolerance="$(rand_int 6 96)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" erasewand "$CURRENT_IMAGE" "$next_path" "$x" "$y" "$tolerance"; then ok=0; fi
      ;;
    movepixelswand)
      x="$(rand_int 0 $((width - 1)))"
      y="$(rand_int 0 $((height - 1)))"
      tolerance="$(rand_int 6 96)"
      dx="$(rand_nonzero -180 180)"
      dy="$(rand_nonzero -180 180)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" movepixelswand "$CURRENT_IMAGE" "$next_path" "$x" "$y" "$tolerance" "$dx" "$dy"; then ok=0; fi
      ;;
    cropwand)
      x="$(rand_int 0 $((width - 1)))"
      y="$(rand_int 0 $((height - 1)))"
      tolerance="$(rand_int 6 96)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" cropwand "$CURRENT_IMAGE" "$next_path" "$x" "$y" "$tolerance"; then ok=0; fi
      ;;
    extractwand)
      update_current=0
      x="$(rand_int 0 $((width - 1)))"
      y="$(rand_int 0 $((height - 1)))"
      tolerance="$(rand_int 6 96)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "artifact" "$CURRENT_IMAGE" "$artifact_path" \
        "$CLI_BIN" extractwand "$CURRENT_IMAGE" "$artifact_path" "$x" "$y" "$tolerance"; then ok=0; fi
      ;;
    crop)
      read -r x y cw ch <<<"$(choose_crop_xywh "$width" "$height")"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" crop "$CURRENT_IMAGE" "$next_path" "$x" "$y" "$cw" "$ch"; then ok=0; fi
      ;;
    resize)
      cw="$(rand_int $((BASE_WIDTH * 8 / 10)) $((BASE_WIDTH * 12 / 10)))"
      ch="$(rand_int $((BASE_HEIGHT * 8 / 10)) $((BASE_HEIGHT * 12 / 10)))"
      if (( cw < 256 )); then cw=256; fi
      if (( ch < 256 )); then ch=256; fi
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" resize "$CURRENT_IMAGE" "$next_path" "$cw" "$ch"; then ok=0; fi
      ;;
    fliph|flipv|rot180|rotcw|rotccw|autolevel|invert|grayscale|sepia|sharpen|outline)
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" "$op_name" "$CURRENT_IMAGE" "$next_path"; then ok=0; fi
      ;;
    brightness)
      delta="$(rand_int -96 96)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" brightness "$CURRENT_IMAGE" "$next_path" "$delta"; then ok=0; fi
      ;;
    contrast)
      amount="$(rand_int -90 90)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" contrast "$CURRENT_IMAGE" "$next_path" "$amount"; then ok=0; fi
      ;;
    blackwhite)
      amount="$(rand_int 50 220)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" blackwhite "$CURRENT_IMAGE" "$next_path" "$amount"; then ok=0; fi
      ;;
    posterize)
      levels="$(rand_int 2 16)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" posterize "$CURRENT_IMAGE" "$next_path" "$levels"; then ok=0; fi
      ;;
    blur)
      radius="$(rand_int 1 10)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" blur "$CURRENT_IMAGE" "$next_path" "$radius"; then ok=0; fi
      ;;
    noise)
      amount="$(rand_int 8 64)"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "raster" "$CURRENT_IMAGE" "$next_path" \
        "$CLI_BIN" noise "$CURRENT_IMAGE" "$next_path" "$amount"; then ok=0; fi
      ;;
    *)
      ok=0
      ;;
  esac

  if (( ok == 1 )) && (( update_current == 1 )) && [[ -f "$next_path" ]]; then
    CURRENT_IMAGE="$next_path"
    rebalance_current_image_if_needed "$image_name" "$phase"
    return 0
  fi
  if (( ok == 1 )) && (( update_current == 0 )); then
    return 0
  fi
  return 1
}

run_doc_op() {
  local image_name="$1"
  local phase="$2"
  local op_name="$3"
  local out_doc
  local out_img
  local source_image
  local layer_idx
  local from_idx
  local to_idx
  local x
  local y
  local delta
  local amount
  local levels
  local threshold
  local opacity
  local ok=0

  source_image="$RUN_ROOT/originals/$image_name"

  case "$op_name" in
    wrapdoc)
      out_doc="$(unique_work_path "wrapdoc" "fpd")"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "doc" "$CURRENT_IMAGE" "$out_doc" \
        "$CLI_BIN" wrapdoc "$CURRENT_IMAGE" "$out_doc"; then ok=1; fi
      if (( ok == 0 )) && [[ -f "$out_doc" ]]; then
        DOC_PATH="$out_doc"
        DOC_LAYER_COUNT=1
        DOC_ACTIVE_LAYER=0
      fi
      ;;
    addlayerdoc)
      ensure_doc_exists "$image_name" || return 1
      out_doc="$(unique_work_path "addlayerdoc" "fpd")"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "doc" "$DOC_PATH" "$out_doc" \
        "$CLI_BIN" addlayerdoc "$DOC_PATH" "$source_image" "$out_doc"; then ok=1; fi
      if (( ok == 0 )) && [[ -f "$out_doc" ]]; then
        DOC_PATH="$out_doc"
        DOC_LAYER_COUNT=$((DOC_LAYER_COUNT + 1))
      fi
      ;;
    pastedoc)
      ensure_doc_exists "$image_name" || return 1
      read -r x y <<<"$(read_dims "$CURRENT_IMAGE")"
      if (( x <= 1 )); then x=64; fi
      if (( y <= 1 )); then y=64; fi
      out_doc="$(unique_work_path "pastedoc" "fpd")"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "doc" "$DOC_PATH" "$out_doc" \
        "$CLI_BIN" pastedoc "$DOC_PATH" "$source_image" "$(rand_int 0 $((x / 4)))" "$(rand_int 0 $((y / 4)))" "$out_doc"; then ok=1; fi
      if (( ok == 0 )) && [[ -f "$out_doc" ]]; then
        DOC_PATH="$out_doc"
      fi
      ;;
    setactivedoc)
      ensure_doc_exists "$image_name" || return 1
      ensure_doc_layers "$image_name" 2 || true
      layer_idx="$(rand_int 0 $((DOC_LAYER_COUNT - 1)))"
      out_doc="$(unique_work_path "setactivedoc" "fpd")"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "doc" "$DOC_PATH" "$out_doc" \
        "$CLI_BIN" setactivedoc "$DOC_PATH" "$layer_idx" "$out_doc"; then ok=1; fi
      if (( ok == 0 )) && [[ -f "$out_doc" ]]; then
        DOC_PATH="$out_doc"
        DOC_ACTIVE_LAYER="$layer_idx"
      fi
      ;;
    duplayerdoc)
      ensure_doc_exists "$image_name" || return 1
      layer_idx="$(rand_int 0 $((DOC_LAYER_COUNT - 1)))"
      out_doc="$(unique_work_path "duplayerdoc" "fpd")"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "doc" "$DOC_PATH" "$out_doc" \
        "$CLI_BIN" duplayerdoc "$DOC_PATH" "$layer_idx" "$out_doc"; then ok=1; fi
      if (( ok == 0 )) && [[ -f "$out_doc" ]]; then
        DOC_PATH="$out_doc"
        DOC_LAYER_COUNT=$((DOC_LAYER_COUNT + 1))
      fi
      ;;
    movelayerdoc)
      ensure_doc_exists "$image_name" || return 1
      ensure_doc_layers "$image_name" 2 || true
      from_idx="$(rand_int 0 $((DOC_LAYER_COUNT - 1)))"
      to_idx="$(rand_int 0 $((DOC_LAYER_COUNT - 1)))"
      if (( to_idx == from_idx )); then
        to_idx=$(((to_idx + 1) % DOC_LAYER_COUNT))
      fi
      out_doc="$(unique_work_path "movelayerdoc" "fpd")"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "doc" "$DOC_PATH" "$out_doc" \
        "$CLI_BIN" movelayerdoc "$DOC_PATH" "$from_idx" "$to_idx" "$out_doc"; then ok=1; fi
      if (( ok == 0 )) && [[ -f "$out_doc" ]]; then
        DOC_PATH="$out_doc"
      fi
      ;;
    renamelayerdoc)
      ensure_doc_exists "$image_name" || return 1
      layer_idx="$(rand_int 0 $((DOC_LAYER_COUNT - 1)))"
      out_doc="$(unique_work_path "renamelayerdoc" "fpd")"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "doc" "$DOC_PATH" "$out_doc" \
        "$CLI_BIN" renamelayerdoc "$DOC_PATH" "$layer_idx" "stress_${RUN_TAG}_${layer_idx}" "$out_doc"; then ok=1; fi
      if (( ok == 0 )) && [[ -f "$out_doc" ]]; then
        DOC_PATH="$out_doc"
      fi
      ;;
    deletelayerdoc)
      ensure_doc_exists "$image_name" || return 1
      ensure_doc_layers "$image_name" 2 || true
      if (( DOC_LAYER_COUNT <= 1 )); then return 1; fi
      layer_idx="$(rand_int 1 $((DOC_LAYER_COUNT - 1)))"
      out_doc="$(unique_work_path "deletelayerdoc" "fpd")"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "doc" "$DOC_PATH" "$out_doc" \
        "$CLI_BIN" deletelayerdoc "$DOC_PATH" "$layer_idx" "$out_doc"; then ok=1; fi
      if (( ok == 0 )) && [[ -f "$out_doc" ]]; then
        DOC_PATH="$out_doc"
        DOC_LAYER_COUNT=$((DOC_LAYER_COUNT - 1))
        if (( DOC_ACTIVE_LAYER >= DOC_LAYER_COUNT )); then
          DOC_ACTIVE_LAYER=$((DOC_LAYER_COUNT - 1))
        fi
      fi
      ;;
    setvisibledoc)
      ensure_doc_exists "$image_name" || return 1
      layer_idx="$(rand_int 0 $((DOC_LAYER_COUNT - 1)))"
      out_doc="$(unique_work_path "setvisibledoc" "fpd")"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "doc" "$DOC_PATH" "$out_doc" \
        "$CLI_BIN" setvisibledoc "$DOC_PATH" "$layer_idx" "$(rand_int 0 1)" "$out_doc"; then ok=1; fi
      if (( ok == 0 )) && [[ -f "$out_doc" ]]; then
        DOC_PATH="$out_doc"
      fi
      ;;
    setopacitydoc)
      ensure_doc_exists "$image_name" || return 1
      layer_idx="$(rand_int 0 $((DOC_LAYER_COUNT - 1)))"
      opacity="$(rand_int 48 255)"
      out_doc="$(unique_work_path "setopacitydoc" "fpd")"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "doc" "$DOC_PATH" "$out_doc" \
        "$CLI_BIN" setopacitydoc "$DOC_PATH" "$layer_idx" "$opacity" "$out_doc"; then ok=1; fi
      if (( ok == 0 )) && [[ -f "$out_doc" ]]; then
        DOC_PATH="$out_doc"
      fi
      ;;
    exportlayerdoc)
      ensure_doc_exists "$image_name" || return 1
      layer_idx="$(rand_int 0 $((DOC_LAYER_COUNT - 1)))"
      out_img="$RUN_ROOT/work/${IMAGE_STEM}_layer_${layer_idx}_${RANDOM}.png"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "artifact" "$DOC_PATH" "$out_img" \
        "$CLI_BIN" exportlayerdoc "$DOC_PATH" "$layer_idx" "$out_img"; then ok=1; fi
      ;;
    mergedowndoc)
      ensure_doc_exists "$image_name" || return 1
      ensure_doc_layers "$image_name" 2 || true
      if (( DOC_LAYER_COUNT <= 1 )); then return 1; fi
      layer_idx="$(rand_int 1 $((DOC_LAYER_COUNT - 1)))"
      out_doc="$(unique_work_path "mergedowndoc" "fpd")"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "doc" "$DOC_PATH" "$out_doc" \
        "$CLI_BIN" mergedowndoc "$DOC_PATH" "$layer_idx" "$out_doc"; then ok=1; fi
      if (( ok == 0 )) && [[ -f "$out_doc" ]]; then
        DOC_PATH="$out_doc"
        DOC_LAYER_COUNT=$((DOC_LAYER_COUNT - 1))
      fi
      ;;
    flattendoc)
      ensure_doc_exists "$image_name" || return 1
      out_doc="$(unique_work_path "flattendoc" "fpd")"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "doc" "$DOC_PATH" "$out_doc" \
        "$CLI_BIN" flattendoc "$DOC_PATH" "$out_doc"; then ok=1; fi
      if (( ok == 0 )) && [[ -f "$out_doc" ]]; then
        DOC_PATH="$out_doc"
        DOC_LAYER_COUNT=1
        DOC_ACTIVE_LAYER=0
      fi
      ;;
    rot180doc|autoleveldoc|invertdoc|grayscaledoc|sepiadoc|sharpendoc|noisedoc|outlinedoc)
      ensure_doc_exists "$image_name" || return 1
      out_doc="$(unique_work_path "$op_name" "fpd")"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "doc" "$DOC_PATH" "$out_doc" \
        "$CLI_BIN" "$op_name" "$DOC_PATH" "$out_doc"; then ok=1; fi
      if (( ok == 0 )) && [[ -f "$out_doc" ]]; then DOC_PATH="$out_doc"; fi
      ;;
    brightnessdoc)
      ensure_doc_exists "$image_name" || return 1
      delta="$(rand_int -96 96)"
      out_doc="$(unique_work_path "brightnessdoc" "fpd")"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "doc" "$DOC_PATH" "$out_doc" \
        "$CLI_BIN" brightnessdoc "$DOC_PATH" "$delta" "$out_doc"; then ok=1; fi
      if (( ok == 0 )) && [[ -f "$out_doc" ]]; then DOC_PATH="$out_doc"; fi
      ;;
    contrastdoc)
      ensure_doc_exists "$image_name" || return 1
      amount="$(rand_int -90 90)"
      out_doc="$(unique_work_path "contrastdoc" "fpd")"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "doc" "$DOC_PATH" "$out_doc" \
        "$CLI_BIN" contrastdoc "$DOC_PATH" "$amount" "$out_doc"; then ok=1; fi
      if (( ok == 0 )) && [[ -f "$out_doc" ]]; then DOC_PATH="$out_doc"; fi
      ;;
    blackwhitedoc)
      ensure_doc_exists "$image_name" || return 1
      threshold="$(rand_int 50 220)"
      out_doc="$(unique_work_path "blackwhitedoc" "fpd")"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "doc" "$DOC_PATH" "$out_doc" \
        "$CLI_BIN" blackwhitedoc "$DOC_PATH" "$threshold" "$out_doc"; then ok=1; fi
      if (( ok == 0 )) && [[ -f "$out_doc" ]]; then DOC_PATH="$out_doc"; fi
      ;;
    posterizedoc)
      ensure_doc_exists "$image_name" || return 1
      levels="$(rand_int 2 16)"
      out_doc="$(unique_work_path "posterizedoc" "fpd")"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "doc" "$DOC_PATH" "$out_doc" \
        "$CLI_BIN" posterizedoc "$DOC_PATH" "$levels" "$out_doc"; then ok=1; fi
      if (( ok == 0 )) && [[ -f "$out_doc" ]]; then DOC_PATH="$out_doc"; fi
      ;;
    blurdoc)
      ensure_doc_exists "$image_name" || return 1
      levels="$(rand_int 1 10)"
      out_doc="$(unique_work_path "blurdoc" "fpd")"
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "doc" "$DOC_PATH" "$out_doc" \
        "$CLI_BIN" blurdoc "$DOC_PATH" "$levels" "$out_doc"; then ok=1; fi
      if (( ok == 0 )) && [[ -f "$out_doc" ]]; then DOC_PATH="$out_doc"; fi
      ;;
    exportdoc_png|exportdoc_bmp|exportdoc_tga|exportdoc_tiff)
      ensure_doc_exists "$image_name" || return 1
      case "$op_name" in
        exportdoc_png) out_img="$RUN_ROOT/work/${IMAGE_STEM}_export_${RANDOM}.png" ;;
        exportdoc_bmp) out_img="$RUN_ROOT/work/${IMAGE_STEM}_export_${RANDOM}.bmp" ;;
        exportdoc_tga) out_img="$RUN_ROOT/work/${IMAGE_STEM}_export_${RANDOM}.tga" ;;
        exportdoc_tiff) out_img="$RUN_ROOT/work/${IMAGE_STEM}_export_${RANDOM}.tiff" ;;
      esac
      if ! run_timed_cmd "$image_name" "$phase" "$op_name" "export" "$DOC_PATH" "$out_img" \
        "$CLI_BIN" exportdoc "$DOC_PATH" "$out_img"; then ok=1; fi
      ;;
    *)
      ok=1
      ;;
  esac

  return "$ok"
}

run_coverage_for_image() {
  local image_name="$1"
  local phase_prefix="$2"
  local op

  while IFS= read -r op; do
    [[ -z "$op" ]] && continue
    run_raster_op "$image_name" "${phase_prefix}_raster" "$op" || true
  done < <(shuffle_values "$SEED_CURSOR" "${RASTER_REQUIRED[@]}")
  SEED_CURSOR=$((SEED_CURSOR + 1))

  # Doc bootstrap for meaningful layer/menu operations.
  run_doc_op "$image_name" "${phase_prefix}_doc_bootstrap" "wrapdoc" || true
  run_doc_op "$image_name" "${phase_prefix}_doc_bootstrap" "addlayerdoc" || true
  run_doc_op "$image_name" "${phase_prefix}_doc_bootstrap" "pastedoc" || true
  run_doc_op "$image_name" "${phase_prefix}_doc_bootstrap" "duplayerdoc" || true

  while IFS= read -r op; do
    [[ -z "$op" ]] && continue
    case "$op" in
      wrapdoc|addlayerdoc|pastedoc|duplayerdoc) continue ;;
    esac
    run_doc_op "$image_name" "${phase_prefix}_doc" "$op" || true
  done < <(shuffle_values "$SEED_CURSOR" "${DOC_REQUIRED[@]}")
  SEED_CURSOR=$((SEED_CURSOR + 1))

  # Keep raster and doc context aligned for subsequent random extras.
  if [[ -f "$DOC_PATH" ]]; then
    local sync_png
    sync_png="$(unique_work_path "internal_sync_from_doc" "png")"
    if run_timed_cmd "$image_name" "${phase_prefix}_doc_sync" "internal_exportdoc_sync_png" "internal" "$DOC_PATH" "$sync_png" \
      "$CLI_BIN" exportdoc "$DOC_PATH" "$sync_png"; then
      if [[ -f "$sync_png" ]]; then
        CURRENT_IMAGE="$sync_png"
        rebalance_current_image_if_needed "$image_name" "${phase_prefix}_doc_sync"
      fi
    fi
  fi
}

run_random_extras_for_image() {
  local image_name="$1"
  local extra_count
  local i
  local op
  local pool_size

  pool_size="${#EXTRA_POOL[@]}"
  if (( pool_size == 0 )); then
    return 0
  fi

  extra_count="$(rand_int "$EXTRA_MIN" "$EXTRA_MAX")"
  for ((i=0; i<extra_count; i++)); do
    op="${EXTRA_POOL[$((RANDOM % pool_size))]}"
    case "$op" in
      wrapdoc|addlayerdoc|pastedoc|setactivedoc|duplayerdoc|movelayerdoc|renamelayerdoc|deletelayerdoc|setvisibledoc|setopacitydoc|exportlayerdoc|mergedowndoc|flattendoc|rot180doc|autoleveldoc|invertdoc|grayscaledoc|brightnessdoc|contrastdoc|sepiadoc|blackwhitedoc|posterizedoc|blurdoc|sharpendoc|noisedoc|outlinedoc|exportdoc_png|exportdoc_bmp|exportdoc_tga|exportdoc_tiff)
        run_doc_op "$image_name" "extra_doc" "$op" || true
        ;;
      *)
        run_raster_op "$image_name" "extra_raster" "$op" || true
        ;;
    esac
  done
}

build_coverage_reports() {
  local required_file="$REPORT_DIR/required_ops.txt"
  local coverage_body="$REPORT_DIR/coverage_body.tsv"
  local coverage_file="$REPORT_DIR/coverage.tsv"
  local missing_total

  {
    printf '%s\n' "${RASTER_REQUIRED[@]}"
    printf '%s\n' "${DOC_REQUIRED[@]}"
  } | sort -u >"$required_file"

  awk -F'\t' '
    NR==FNR { req[$1]=1; next }
    NR>1 && $8==0 { success[$4]++ }
    END {
      for (op in req) {
        c = success[op] + 0
        status = (c > 0) ? "OK" : "MISSING"
        printf "%s\t%s\t%d\n", op, status, c
      }
    }
  ' "$required_file" "$REPORT_DIR/metrics.tsv" >"$coverage_body"

  missing_total="$(awk -F'\t' '$2=="MISSING" {c++} END {print c+0}' "$coverage_body")"
  {
    printf 'op_name\tstatus\tsuccess_count\n'
    sort "$coverage_body"
    printf 'missing_total\t%s\t0\n' "$missing_total"
  } >"$coverage_file"

  rm -f "$coverage_body"
  printf '%s\n' "$missing_total"
}

build_hotspot_report() {
  local hotspot_file="$REPORT_DIR/hotspots.txt"
  local metrics="$REPORT_DIR/metrics.tsv"
  local failed_ops
  local total_ops

  failed_ops="$(awk -F'\t' 'NR>1 && $8 != 0 {c++} END {print c+0}' "$metrics")"
  total_ops="$(awk -F'\t' 'NR>1 {c++} END {print c+0}' "$metrics")"

  {
    printf 'Top 12 by peak RSS (MB)\n'
    printf 'op_index\timage_name\tphase\top_name\treal_sec\tmax_rss_mb\n'
    awk -F'\t' 'NR>1 {printf "%s\t%s\t%s\t%s\t%s\t%.2f\n", $1, $2, $3, $4, $9, $12/1024/1024}' "$metrics" \
      | sort -t$'\t' -k6,6nr \
      | head -n 12
    printf '\nTop 12 by real time (sec)\n'
    printf 'op_index\timage_name\tphase\top_name\treal_sec\tmax_rss_mb\n'
    awk -F'\t' 'NR>1 {printf "%s\t%s\t%s\t%s\t%s\t%.2f\n", $1, $2, $3, $4, $9, $12/1024/1024}' "$metrics" \
      | sort -t$'\t' -k5,5nr \
      | head -n 12
    printf '\nFailures: %s / %s\n' "$failed_ops" "$total_ops"
  } >"$hotspot_file"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input-dir)
      INPUT_DIR="$2"
      shift 2
      ;;
    --cli)
      CLI_BIN="$2"
      shift 2
      ;;
    --seed)
      SEED="$2"
      shift 2
      ;;
    --extra-min)
      EXTRA_MIN="$2"
      shift 2
      ;;
    --extra-max)
      EXTRA_MAX="$2"
      shift 2
      ;;
    --max-images)
      MAX_IMAGES="$2"
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
  printf 'input dir not found: %s\n' "$INPUT_DIR" >&2
  exit 2
fi

if (( EXTRA_MAX < EXTRA_MIN )); then
  printf 'extra-max must be >= extra-min\n' >&2
  exit 2
fi

mkdir -p "$RUN_ROOT/originals" "$RUN_ROOT/work" "$REPORT_DIR/ops" "$REPORT_DIR/logs" "$PERF_ROOT"

RANDOM="$SEED"
SEED_CURSOR="$SEED"

SOURCE_IMAGES=()
while IFS= read -r image_path; do
  SOURCE_IMAGES+=("$image_path")
done < <(find "$INPUT_DIR" -maxdepth 1 -type f | sort)

if [[ "${#SOURCE_IMAGES[@]}" -eq 0 ]]; then
  printf 'no source images found under %s\n' "$INPUT_DIR" >&2
  exit 2
fi

if (( MAX_IMAGES > 0 )) && (( MAX_IMAGES < ${#SOURCE_IMAGES[@]} )); then
  SOURCE_IMAGES=("${SOURCE_IMAGES[@]:0:$MAX_IMAGES}")
fi

printf 'op_index\timage_name\tphase\top_name\ttarget_kind\tinput_path\toutput_path\texit_code\treal_sec\tuser_sec\tsys_sec\tmax_rss_bytes\tpeak_footprint_bytes\tcommand\n' >"$REPORT_DIR/metrics.tsv"

RUN_START_HUMAN="$(date '+%Y-%m-%d %H:%M:%S')"
RUN_START_EPOCH="$(date '+%s')"

log "Coverage stress run root: $RUN_ROOT"
log "Report directory: $REPORT_DIR"
log "Seed: $SEED"
log "Images: ${#SOURCE_IMAGES[@]} (max-images=$MAX_IMAGES)"
log "Extra ops/image: $EXTRA_MIN..$EXTRA_MAX"

for source in "${SOURCE_IMAGES[@]}"; do
  image_name="$(basename -- "$source")"
  IMAGE_STEM="${image_name%.*}"
  DOC_PATH=""
  DOC_LAYER_COUNT=0
  DOC_ACTIVE_LAYER=0

  cp -f "$source" "$RUN_ROOT/originals/$image_name"
  read -r BASE_WIDTH BASE_HEIGHT <<<"$(read_dims "$source")"
  if (( BASE_WIDTH <= 0 || BASE_HEIGHT <= 0 )); then
    log "Skipping unreadable image: $source"
    continue
  fi

  CURRENT_IMAGE="$(unique_work_path "normalize" "png")"
  run_timed_cmd "$image_name" "setup" "normalize_png" "raster" "$source" "$CURRENT_IMAGE" \
    "$CLI_BIN" resize "$source" "$CURRENT_IMAGE" "$BASE_WIDTH" "$BASE_HEIGHT" || true
  if [[ ! -f "$CURRENT_IMAGE" ]]; then
    log "Failed to normalize source image: $source"
    continue
  fi

  run_coverage_for_image "$image_name" "coverage"
  run_random_extras_for_image "$image_name"
done

RUN_END_HUMAN="$(date '+%Y-%m-%d %H:%M:%S')"
RUN_END_EPOCH="$(date '+%s')"

/usr/bin/log show --style compact --start "$RUN_START_HUMAN" --end "$RUN_END_HUMAN" \
  --predicate 'process == "flatpaint_cli" || process == "FlatPaint"' \
  >"$REPORT_DIR/logs/system_flatpaint.log" 2>&1 || true

/usr/bin/log show --style compact --start "$RUN_START_HUMAN" --end "$RUN_END_HUMAN" \
  --predicate '(process == "flatpaint_cli" || process == "FlatPaint") && (eventMessage CONTAINS[c] "error" || eventMessage CONTAINS[c] "fault" || eventMessage CONTAINS[c] "exception" || eventMessage CONTAINS[c] "oom" || eventMessage CONTAINS[c] "malloc")' \
  >"$REPORT_DIR/logs/system_flatpaint_errors.log" 2>&1 || true

MISSING_OPS="$(build_coverage_reports)"
build_hotspot_report

FAILED_OPS="$(awk -F'\t' 'NR>1 && $8 != 0 {c++} END {print c+0}' "$REPORT_DIR/metrics.tsv")"
TOTAL_OPS="$(awk -F'\t' 'NR>1 {c++} END {print c+0}' "$REPORT_DIR/metrics.tsv")"
PEAK_RSS_BYTES="$(awk -F'\t' 'NR>1 && $12+0 > max { max=$12+0 } END { print max+0 }' "$REPORT_DIR/metrics.tsv")"
SLOWEST_REAL_SEC="$(awk -F'\t' 'NR>1 && $9+0 > max { max=$9+0 } END { print max+0 }' "$REPORT_DIR/metrics.tsv")"

{
  printf 'run_start=%s\n' "$RUN_START_HUMAN"
  printf 'run_end=%s\n' "$RUN_END_HUMAN"
  printf 'run_seconds=%s\n' "$((RUN_END_EPOCH - RUN_START_EPOCH))"
  printf 'seed=%s\n' "$SEED"
  printf 'input_dir=%s\n' "$INPUT_DIR"
  printf 'run_root=%s\n' "$RUN_ROOT"
  printf 'report_dir=%s\n' "$REPORT_DIR"
  printf 'image_count=%s\n' "${#SOURCE_IMAGES[@]}"
  printf 'extra_min=%s\n' "$EXTRA_MIN"
  printf 'extra_max=%s\n' "$EXTRA_MAX"
  printf 'total_ops=%s\n' "$TOTAL_OPS"
  printf 'failed_ops=%s\n' "$FAILED_OPS"
  printf 'missing_ops=%s\n' "$MISSING_OPS"
  printf 'peak_rss_mb=%.2f\n' "$(awk -v b="$PEAK_RSS_BYTES" 'BEGIN { print b/1024/1024 }')"
  printf 'slowest_real_sec=%s\n' "$SLOWEST_REAL_SEC"
  printf 'metrics=%s\n' "$REPORT_DIR/metrics.tsv"
  printf 'coverage=%s\n' "$REPORT_DIR/coverage.tsv"
  printf 'hotspots=%s\n' "$REPORT_DIR/hotspots.txt"
  printf 'system_log=%s\n' "$REPORT_DIR/logs/system_flatpaint.log"
  printf 'system_error_log=%s\n' "$REPORT_DIR/logs/system_flatpaint_errors.log"
  printf 'history_file=%s\n' "$HISTORY_FILE"
} >"$REPORT_DIR/run_summary.txt"

if [[ ! -f "$HISTORY_FILE" ]]; then
  printf 'run_tag\trun_start\trun_end\trun_seconds\tseed\timage_count\textra_min\textra_max\ttotal_ops\tfailed_ops\tmissing_ops\tstatus\tpeak_rss_mb\tslowest_real_sec\treport_dir\trun_summary\tcoverage\n' >"$HISTORY_FILE"
fi

printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%.2f\t%s\t%s\t%s\t%s\n' \
  "$RUN_TAG" "$RUN_START_HUMAN" "$RUN_END_HUMAN" "$((RUN_END_EPOCH - RUN_START_EPOCH))" \
  "$SEED" "${#SOURCE_IMAGES[@]}" "$EXTRA_MIN" "$EXTRA_MAX" "$TOTAL_OPS" "$FAILED_OPS" "$MISSING_OPS" "COMPLETED" \
  "$(awk -v b="$PEAK_RSS_BYTES" 'BEGIN { print b/1024/1024 }')" "$SLOWEST_REAL_SEC" \
  "$REPORT_DIR" "$REPORT_DIR/run_summary.txt" "$REPORT_DIR/coverage.tsv" >>"$HISTORY_FILE"

log "Run summary: $REPORT_DIR/run_summary.txt"
log "Coverage report: $REPORT_DIR/coverage.tsv"
log "Hotspots: $REPORT_DIR/hotspots.txt"
log "History index: $HISTORY_FILE"
