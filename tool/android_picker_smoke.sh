#!/bin/bash
# Real DocumentsUI test on an already running disposable Android emulator.
set -euo pipefail
OUT=${1:?output directory}
mkdir -p "$OUT"
RUN_ID="$(date +%s)-$$"
python3 -u tool/android_picker_driver.py --out "$OUT" --run-id "$RUN_ID" >"$OUT/driver.log" 2>&1 &
DRIVER_PID=$!
trap 'kill "$DRIVER_PID" "${TEST_PID:-}" 2>/dev/null || true' EXIT
flutter test integration_test -d emulator-5554 --dart-define="PICKER_RUN_ID=$RUN_ID" &
TEST_PID=$!
# Stop promptly if either the native driver or the Flutter assertions fail.
wait -n "$DRIVER_PID" "$TEST_PID" || { cat "$OUT/driver.log"; exit 1; }
wait "$TEST_PID"
wait "$DRIVER_PID" || { cat "$OUT/driver.log"; exit 1; }
cat "$OUT/driver.log"
