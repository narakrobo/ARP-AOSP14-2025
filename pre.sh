#!/usr/bin/env bash
set -euo pipefail

########################
RUNS=3
TOUCHES_PER_RUN=100
SLEEP_BETWEEN_TOUCH=0.10
EVENT_DEV="/dev/input/event2" # getevent -pl
OUTDIR="./aosp14_sys_bench_pre"
WARMUP_TOUCHES=30
########################

mkdir -p "$OUTDIR"
adb get-state 1>/dev/null

if (( WARMUP_TOUCHES > 0 )); then
  echo "[*] Warm-up (${WARMUP_TOUCHES} touches)"
  adb shell log -t BENCH "WARMUP_START pre"
  for i in $(seq 0 $WARMUP_TOUCHES); do
    adb shell "sendevent /dev/input/event2 3 0 500; sendevent /dev/input/event2 3 1 800; sendevent /dev/input/event2 1 330 1; sendevent /dev/input/event2 0 0 0"
    sleep 0.03
    adb shell "sendevent /dev/input/event2 1 330 0; sendevent /dev/input/event2 0 0 0"

    sleep $SLEEP_BETWEEN_TOUCH
  done
  adb shell log -t BENCH "WARMUP_END pre"
fi

touch_run () {
  local run_idx="$1"
  local stamp="$(date +%Y%m%d_%H%M%S)"
  local prefix="${OUTDIR}/pre_run${run_idx}_${stamp}"

  echo "[*] pre run ${run_idx}: start"

  adb logcat -c
  (adb logcat -v threadtime -b all | grep "TOUCHPIPE" > "${prefix}_touchpipe.log") &
  local LOGCAT_PID=$!

  # FPS
  adb shell dumpsys SurfaceFlinger --latency-clear || true

  adb shell log -t BENCH "START pre_run${run_idx}"

  for t in $(seq 0 $TOUCHES_PER_RUN); do
    adb shell "sendevent /dev/input/event2 3 0 500; sendevent /dev/input/event2 3 1 800; sendevent /dev/input/event2 1 330 1; sendevent /dev/input/event2 0 0 0"
    sleep 0.03
    adb shell "sendevent /dev/input/event2 1 330 0; sendevent /dev/input/event2 0 0 0"

    sleep "$SLEEP_BETWEEN_TOUCH"
  done

  adb shell log -t BENCH "END pre_run${run_idx}"

  adb shell dumpsys meminfo -S > "${prefix}_mem_end.txt"

  adb shell dumpsys SurfaceFlinger --latency "com.android.launcher3/com.android.launcher3.Launcher" > "${prefix}_sf_latency.txt" || true

  sleep 2
  kill ${LOGCAT_PID} 2>/dev/null || true
  wait ${LOGCAT_PID} 2>/dev/null || true
  adb logcat -d -b all -v threadtime > "${prefix}_full_logcat.txt" || true

  echo "[*] pre run ${run_idx}: done → ${prefix}*"
}

for r in $(seq 1 $RUNS); do
  touch_run "$r"
done

echo "[✓] Pre Completed. Result: ${OUTDIR}"
echo "    *_sf_latency.txt, *_mem_*.txt, *_touchpipe.log generated"

