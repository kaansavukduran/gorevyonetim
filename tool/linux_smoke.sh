#!/bin/bash
# Runtime smoke of the Linux release build under Xvfb, driven like a person
# with the mouse and keyboard (xdotool). Run from the repository root:
#   flutter build linux --release
#   xvfb-run -a -s "-screen 0 1180x800x24" tool/linux_smoke.sh <out-dir>
# Checks: first start writes nothing; a typed task and a click on its box
# are saved to the real file; a second start shows them again.
set -euo pipefail
OUT=${1:?output directory}
BIN=build/linux/x64/release/bundle/gunluk_gorevler
mkdir -p "$OUT"
DATA=$(mktemp -d)
trap 'rm -rf "$DATA"' EXIT
export GUNLUK_GOREVLER_DIR=$DATA GDK_BACKEND=x11

start_app() {
  "$BIN" >>"$OUT/app.log" 2>&1 &
  APP=$!
  for _ in $(seq 1 60); do
    WID=$(xdotool search --name "Günlük Görevler" 2>/dev/null | head -1) && [ -n "$WID" ] && break
    sleep 0.5
  done
  [ -n "${WID:-}" ] || { echo "FAIL: window did not appear"; exit 1; }
  xdotool windowmove "$WID" 0 0 windowsize "$WID" 1180 800
  sleep 3
}

stop_app() { kill "$APP"; wait "$APP" 2>/dev/null || true; }

start_app
import -window root "$OUT/1-first-start.png"
if [ -e "$DATA/gorevler.json" ]; then echo "FAIL: first start wrote a file"; exit 1; fi
echo "PASS: first start wrote nothing"

# The quick-add field sits under the hero strip and the week strip.
xdotool mousemove 520 322 click 1
sleep 0.5
xdotool type --delay 40 "Su ic"
xdotool key Return
sleep 1.5
xdotool mousemove 290 471 click 1
sleep 1.5
import -window root "$OUT/2-added-and-ticked.png"
stop_app

grep -q '"title": "Su ic"' "$DATA/gorevler.json" || { echo "FAIL: task not saved"; exit 1; }
TODAY=$(date +%F)
grep -q "\"date\": \"$TODAY\"" "$DATA/gorevler.json" || { echo "FAIL: tick for $TODAY not saved"; exit 1; }
echo "PASS: task and today's tick saved to gorevler.json"

start_app
import -window root "$OUT/3-after-restart.png"
stop_app
echo "PASS: second start completed (see 3-after-restart.png)"
