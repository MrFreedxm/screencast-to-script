#!/bin/bash
# Extract frames from a video on scene changes (default) or on a timer.
# usage: extract-frames.sh <video> <out-dir> [threshold|timer]
#   threshold  scene-change sensitivity 0.2-0.4 (default 0.3)
#   timer      one frame every 2 seconds instead of scene detection
set -euo pipefail
VIDEO="${1:?video path}"; OUT="${2:?output dir}"; MODE="${3:-0.3}"
command -v ffmpeg >/dev/null || { echo "ffmpeg not found" >&2; exit 1; }
mkdir -p "$OUT"
if [ "$MODE" = "timer" ]; then
  ffmpeg -y -loglevel error -i "$VIDEO" -vf fps=1/2 -q:v 3 "$OUT/t_%04d.jpg"
else
  ffmpeg -y -i "$VIDEO" -vf "select='gt(scene,$MODE)',showinfo" -vsync vfr -q:v 3 "$OUT/f_%04d.jpg" 2> "$OUT/scenes.log"
fi
echo "$(ls "$OUT"/*.jpg 2>/dev/null | wc -l | tr -d ' ') frames in $OUT"
