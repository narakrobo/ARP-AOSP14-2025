#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <sf_latency.txt>"
  exit 1
fi

LATENCY_FILE="$1"


# ─────────────────────────────────────────────────────────────────────
# row 1: display_refresh_period_ns
# row 2~: posted_ns - acquired_ns - presented_ns
# FPS = 1000 / (presented_ns frame gap (ms))
# ─────────────────────────────────────────────────────────────────────

# chmod +x fps_from_latency.sh
# adb shell dumpsys SurfaceFlinger --latency "com.android.launcher3/com.android.launcher3.Launcher" > sf_latency.txt
# ./fps_from_latency.sh sf_latency.txt


awk '
NR==1 { next } # skip row 1
NF>=3 && $3>0 {
  presented_ns = $3 # ns
  if (has_prev) {
    frame_interval_ms = (presented_ns - prev_presented_ns) / 1e6 # ns -> ms
    sum_ms += frame_interval_ms
    frame_cnt++
  }
  prev_presented_ns = presented_ns
  has_prev = 1
}
END {
  if (frame_cnt == 0) { print "no frames"; exit }
  mean_ms = sum_ms / frame_cnt
  fps = 1000 / mean_ms
  printf("FPS=%.2f\n", fps)
}
' "$LATENCY_FILE"
