#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
DEFAULT_APP_TARGET="$ROOT_DIR/dist/FlatPaint.app"
DEFAULT_OUTPUT_ROOT="$ROOT_DIR/dist/runtime_profile"

DURATION_SEC="45"
INTERVAL_SEC="0.5"
SAMPLE_DURATION_SEC="5"
HIGH_CPU_PCT="95"
HIGH_CPU_SECONDS="3"

APP_TARGET="$DEFAULT_APP_TARGET"
OUTPUT_DIR=""
PID=""
MAX_RSS_MB=""
WORKLOAD_CMD=""
SKIP_SAMPLE=0
SKIP_VMMAP=0
STARTED_HERE=0
PROCESS_EXITED_EARLY=0
WORKLOAD_PID=""

usage() {
  cat <<'EOF'
Usage:
  bash ./scripts/profile_runtime_macos.sh [options]

Options:
  --app <path>              App binary or .app bundle to launch (default: dist/FlatPaint.app)
  --pid <pid>               Attach to an existing process instead of launching
  --duration <seconds>      Monitor window in seconds (default: 45)
  --interval <seconds>      Sampling interval in seconds (default: 0.5)
  --output <dir>            Output directory (default: dist/runtime_profile/<timestamp>)
  --max-rss-mb <mb>         Fail with non-zero if peak RSS exceeds this threshold
  --high-cpu-pct <pct>      High-CPU threshold percent (default: 95)
  --high-cpu-seconds <sec>  Consecutive high-CPU budget (default: 3)
  --workload-cmd <command>  Optional command executed during monitoring (for UI automation / scripted load)
  --skip-sample             Do not capture macOS sample stack report
  --skip-vmmap              Do not capture vmmap summary
  --help                    Show this help

Examples:
  bash ./scripts/profile_runtime_macos.sh --duration 60 --max-rss-mb 1200
  bash ./scripts/profile_runtime_macos.sh --app ./flatpaint --workload-cmd "osascript scripts/workloads/lasso_stress.scpt"
EOF
}

log() {
  printf '==> %s\n' "$*"
}

cleanup() {
  if [[ -n "$WORKLOAD_PID" ]] && kill -0 "$WORKLOAD_PID" >/dev/null 2>&1; then
    kill "$WORKLOAD_PID" >/dev/null 2>&1 || true
  fi
  if [[ "$STARTED_HERE" -eq 1 ]] && [[ -n "$PID" ]] && kill -0 "$PID" >/dev/null 2>&1; then
    kill "$PID" >/dev/null 2>&1 || true
    sleep 1
    if kill -0 "$PID" >/dev/null 2>&1; then
      kill -9 "$PID" >/dev/null 2>&1 || true
    fi
  fi
}

resolve_bundle_executable() {
  local bundle_path="$1"
  local app_name
  local guessed
  app_name="$(basename -- "$bundle_path" .app)"
  guessed="$bundle_path/Contents/MacOS/$app_name"
  if [[ -x "$guessed" ]]; then
    printf '%s\n' "$guessed"
    return 0
  fi
  guessed="$(find "$bundle_path/Contents/MacOS" -maxdepth 1 -type f -perm -111 2>/dev/null | head -n 1)"
  if [[ -n "$guessed" ]]; then
    printf '%s\n' "$guessed"
    return 0
  fi
  printf 'Unable to find executable inside bundle: %s\n' "$bundle_path" >&2
  return 1
}

launch_target() {
  local target="$1"
  if [[ "$target" == *.app ]]; then
    local bundle_executable
    if [[ ! -d "$target" ]]; then
      printf 'App bundle not found: %s\n' "$target" >&2
      return 1
    fi
    bundle_executable="$(resolve_bundle_executable "$target")"
    log "Launching app bundle: $target"
    open -n "$target"
    sleep 2
    PID="$(ps -ax -o pid=,comm= | awk -v exe="$bundle_executable" '$2 == exe { pid = $1 } END { print pid }')"
    if [[ -z "$PID" ]]; then
      printf 'Unable to find running app process for bundle: %s\n' "$target" >&2
      return 1
    fi
  else
    if [[ ! -x "$target" ]]; then
      printf 'App executable not found: %s\n' "$target" >&2
      return 1
    fi
    log "Launching app binary: $target"
    "$target" >"$OUTPUT_DIR/app.stdout.log" 2>"$OUTPUT_DIR/app.stderr.log" &
    PID="$!"
    sleep 2
  fi
  STARTED_HERE=1
}

to_mb() {
  local kb="$1"
  awk -v value="$kb" 'BEGIN { printf "%.2f", value / 1024.0 }'
}

timestamp_now() {
  date '+%Y-%m-%dT%H:%M:%S%z'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app)
      APP_TARGET="$2"
      shift 2
      ;;
    --pid)
      PID="$2"
      shift 2
      ;;
    --duration)
      DURATION_SEC="$2"
      shift 2
      ;;
    --interval)
      INTERVAL_SEC="$2"
      shift 2
      ;;
    --output)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --max-rss-mb)
      MAX_RSS_MB="$2"
      shift 2
      ;;
    --high-cpu-pct)
      HIGH_CPU_PCT="$2"
      shift 2
      ;;
    --high-cpu-seconds)
      HIGH_CPU_SECONDS="$2"
      shift 2
      ;;
    --workload-cmd)
      WORKLOAD_CMD="$2"
      shift 2
      ;;
    --skip-sample)
      SKIP_SAMPLE=1
      shift
      ;;
    --skip-vmmap)
      SKIP_VMMAP=1
      shift
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

if [[ -z "$OUTPUT_DIR" ]]; then
  OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/$(date '+%Y%m%d_%H%M%S')"
fi
mkdir -p -- "$OUTPUT_DIR"

if [[ -z "$PID" ]]; then
  if [[ ! -e "$APP_TARGET" && -x "$ROOT_DIR/flatpaint" ]]; then
    APP_TARGET="$ROOT_DIR/flatpaint"
  fi
  launch_target "$APP_TARGET"
fi

if ! kill -0 "$PID" >/dev/null 2>&1; then
  printf 'Target PID is not running: %s\n' "$PID" >&2
  exit 2
fi

trap cleanup EXIT

CSV_FILE="$OUTPUT_DIR/process_samples.csv"
SUMMARY_FILE="$OUTPUT_DIR/summary.txt"
SAMPLE_FILE="$OUTPUT_DIR/sample.txt"
VMMAP_FILE="$OUTPUT_DIR/vmmap_summary.txt"

target_samples="$(awk -v d="$DURATION_SEC" -v i="$INTERVAL_SEC" 'BEGIN { if (i <= 0) print 1; else print int((d / i) + 0.999999) }')"
high_cpu_limit_samples="$(awk -v s="$HIGH_CPU_SECONDS" -v i="$INTERVAL_SEC" 'BEGIN { if (i <= 0) print 1; else print int((s / i) + 0.999999) }')"

printf 'timestamp,elapsed_sec,rss_kb,vsz_kb,cpu_pct,state\n' >"$CSV_FILE"
printf 'workload_cmd=%s\n' "${WORKLOAD_CMD:-<none>}" >"$OUTPUT_DIR/workload.txt"

if [[ -n "$WORKLOAD_CMD" ]]; then
  log "Running workload command: $WORKLOAD_CMD"
  bash -lc "$WORKLOAD_CMD" >"$OUTPUT_DIR/workload.log" 2>&1 &
  WORKLOAD_PID="$!"
fi

log "Monitoring PID $PID for ${DURATION_SEC}s (interval ${INTERVAL_SEC}s)"
log "Output directory: $OUTPUT_DIR"
if [[ -z "$WORKLOAD_CMD" ]]; then
  log "No workload command provided. If this is interactive profiling, perform canvas actions during this window."
fi

observed_samples=0
sum_rss_kb=0
sum_vsz_kb=0
sum_cpu_x100=0
max_rss_kb=0
max_vsz_kb=0
max_cpu_x100=0
high_cpu_streak_samples=0
max_high_cpu_streak_samples=0

for ((sample_index=1; sample_index<=target_samples; sample_index++)); do
  if ! kill -0 "$PID" >/dev/null 2>&1; then
    PROCESS_EXITED_EARLY=1
    break
  fi

  sample_line="$(ps -p "$PID" -o rss= -o vsz= -o %cpu= -o state= | awk 'NR==1{print $1, $2, $3, $4}')"
  if [[ -z "$sample_line" ]]; then
    PROCESS_EXITED_EARLY=1
    break
  fi

  read -r rss_kb vsz_kb cpu_pct state <<<"$sample_line"
  elapsed_sec="$(awk -v n="$sample_index" -v i="$INTERVAL_SEC" 'BEGIN { printf "%.2f", (n - 1) * i }')"
  now_stamp="$(timestamp_now)"
  printf '%s,%s,%s,%s,%s,%s\n' \
    "$now_stamp" "$elapsed_sec" "$rss_kb" "$vsz_kb" "$cpu_pct" "$state" >>"$CSV_FILE"

  observed_samples=$((observed_samples + 1))
  sum_rss_kb=$((sum_rss_kb + rss_kb))
  sum_vsz_kb=$((sum_vsz_kb + vsz_kb))

  cpu_x100="$(awk -v c="$cpu_pct" 'BEGIN { printf "%.0f", c * 100.0 }')"
  sum_cpu_x100=$((sum_cpu_x100 + cpu_x100))

  if (( rss_kb > max_rss_kb )); then
    max_rss_kb="$rss_kb"
  fi
  if (( vsz_kb > max_vsz_kb )); then
    max_vsz_kb="$vsz_kb"
  fi
  if (( cpu_x100 > max_cpu_x100 )); then
    max_cpu_x100="$cpu_x100"
  fi

  if awk -v c="$cpu_pct" -v t="$HIGH_CPU_PCT" 'BEGIN { exit !(c >= t) }'; then
    high_cpu_streak_samples=$((high_cpu_streak_samples + 1))
    if (( high_cpu_streak_samples > max_high_cpu_streak_samples )); then
      max_high_cpu_streak_samples="$high_cpu_streak_samples"
    fi
  else
    high_cpu_streak_samples=0
  fi

  if (( sample_index < target_samples )); then
    sleep "$INTERVAL_SEC"
  fi
done

if [[ -n "$WORKLOAD_PID" ]]; then
  wait "$WORKLOAD_PID" || true
fi

if (( observed_samples == 0 )); then
  printf 'No valid process samples were collected.\n' >&2
  exit 3
fi

avg_rss_kb="$(awk -v sum="$sum_rss_kb" -v n="$observed_samples" 'BEGIN { if (n == 0) print 0; else printf "%.2f", sum / n }')"
avg_vsz_kb="$(awk -v sum="$sum_vsz_kb" -v n="$observed_samples" 'BEGIN { if (n == 0) print 0; else printf "%.2f", sum / n }')"
avg_cpu_pct="$(awk -v sum="$sum_cpu_x100" -v n="$observed_samples" 'BEGIN { if (n == 0) print 0; else printf "%.2f", (sum / 100.0) / n }')"
max_cpu_pct="$(awk -v max="$max_cpu_x100" 'BEGIN { printf "%.2f", max / 100.0 }')"
observed_duration_sec="$(awk -v n="$observed_samples" -v i="$INTERVAL_SEC" 'BEGIN { printf "%.2f", n * i }')"
max_high_cpu_streak_sec="$(awk -v n="$max_high_cpu_streak_samples" -v i="$INTERVAL_SEC" 'BEGIN { printf "%.2f", n * i }')"

if [[ "$SKIP_SAMPLE" -eq 0 ]] && kill -0 "$PID" >/dev/null 2>&1; then
  log "Capturing stack sample: $SAMPLE_FILE"
  sample "$PID" "$SAMPLE_DURATION_SEC" 1 -file "$SAMPLE_FILE" >/dev/null 2>&1 || true
fi

if [[ "$SKIP_VMMAP" -eq 0 ]] && kill -0 "$PID" >/dev/null 2>&1; then
  log "Capturing vmmap summary: $VMMAP_FILE"
  vmmap -summary "$PID" >"$VMMAP_FILE" 2>&1 || true
fi

status="PASS"
exit_code=0
failure_reason=""

if [[ -n "$MAX_RSS_MB" ]] && awk -v rss_kb="$max_rss_kb" -v max_mb="$MAX_RSS_MB" 'BEGIN { exit !((rss_kb / 1024.0) > max_mb) }'; then
  status="FAIL"
  exit_code=1
  failure_reason="peak RSS exceeded threshold"
fi

if (( max_high_cpu_streak_samples >= high_cpu_limit_samples )); then
  if [[ "$status" == "PASS" ]]; then
    status="FAIL"
    exit_code=1
    failure_reason="consecutive high CPU duration exceeded threshold"
  else
    failure_reason="$failure_reason + consecutive high CPU duration exceeded threshold"
  fi
fi

{
  printf 'status=%s\n' "$status"
  printf 'failure_reason=%s\n' "${failure_reason:-<none>}"
  printf 'pid=%s\n' "$PID"
  printf 'started_here=%s\n' "$STARTED_HERE"
  printf 'process_exited_early=%s\n' "$PROCESS_EXITED_EARLY"
  printf 'target_duration_sec=%s\n' "$DURATION_SEC"
  printf 'observed_duration_sec=%s\n' "$observed_duration_sec"
  printf 'interval_sec=%s\n' "$INTERVAL_SEC"
  printf 'sample_count=%s\n' "$observed_samples"
  printf 'peak_rss_kb=%s\n' "$max_rss_kb"
  printf 'peak_rss_mb=%s\n' "$(to_mb "$max_rss_kb")"
  printf 'avg_rss_kb=%s\n' "$avg_rss_kb"
  printf 'avg_rss_mb=%s\n' "$(to_mb "$avg_rss_kb")"
  printf 'peak_vsz_kb=%s\n' "$max_vsz_kb"
  printf 'peak_vsz_mb=%s\n' "$(to_mb "$max_vsz_kb")"
  printf 'avg_vsz_kb=%s\n' "$avg_vsz_kb"
  printf 'avg_vsz_mb=%s\n' "$(to_mb "$avg_vsz_kb")"
  printf 'peak_cpu_pct=%s\n' "$max_cpu_pct"
  printf 'avg_cpu_pct=%s\n' "$avg_cpu_pct"
  printf 'high_cpu_threshold_pct=%s\n' "$HIGH_CPU_PCT"
  printf 'high_cpu_threshold_sec=%s\n' "$HIGH_CPU_SECONDS"
  printf 'max_high_cpu_streak_sec=%s\n' "$max_high_cpu_streak_sec"
  printf 'max_rss_threshold_mb=%s\n' "${MAX_RSS_MB:-<none>}"
  printf 'sample_report=%s\n' "$SAMPLE_FILE"
  printf 'vmmap_summary=%s\n' "$VMMAP_FILE"
  printf 'csv=%s\n' "$CSV_FILE"
} >"$SUMMARY_FILE"

log "Summary: $SUMMARY_FILE"
cat "$SUMMARY_FILE"

exit "$exit_code"
