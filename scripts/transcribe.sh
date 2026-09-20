#!/bin/bash
# Local voice transcription with whatever ASR is installed.
# usage: transcribe.sh <file-or-url> <out-dir>      writes <out-dir>/<name>.txt (or .srt with ASR_FORMAT=srt)
#        transcribe.sh --check                       report which engine will be used
# engines, in order: mlx_whisper (Apple Silicon), whisper (openai-whisper), whisper-cli (whisper.cpp)
set -euo pipefail
FORMAT="${ASR_FORMAT:-txt}"
MODEL="${ASR_MODEL:-}"
engine() {
  if command -v mlx_whisper >/dev/null; then echo mlx_whisper
  elif command -v whisper >/dev/null; then echo whisper
  elif command -v whisper-cli >/dev/null; then echo whisper-cli
  else echo none; fi
}
if [ "${1:-}" = "--check" ]; then
  E=$(engine); echo "engine: $E"; command -v yt-dlp >/dev/null && echo "yt-dlp: yes" || echo "yt-dlp: no (URLs unsupported)"
  [ "$E" = none ] && { echo "install one: pip install mlx-whisper | pip install openai-whisper | brew install whisper-cpp" >&2; exit 1; }
  exit 0
fi
SRC="${1:?file or url}"; OUT="${2:?output dir}"; mkdir -p "$OUT"
case "$SRC" in
  http://*|https://*)
    command -v yt-dlp >/dev/null || { echo "yt-dlp not found, cannot download URLs" >&2; exit 1; }
    yt-dlp -q -x --audio-format m4a -o "$OUT/download.%(ext)s" "$SRC"; SRC="$OUT/download.m4a";;
esac
NAME="$(basename "${SRC%.*}")"
case "$(engine)" in
  mlx_whisper) mlx_whisper "$SRC" --output-dir "$OUT" --output-format "$FORMAT" ${MODEL:+--model "$MODEL"} >/dev/null;;
  whisper)     whisper "$SRC" --output_dir "$OUT" --output_format "$FORMAT" ${MODEL:+--model "$MODEL"} >/dev/null;;
  whisper-cli) ffmpeg -y -loglevel error -i "$SRC" -ar 16000 -ac 1 "$OUT/$NAME.wav"
               if [ "$FORMAT" = srt ]; then whisper-cli -f "$OUT/$NAME.wav" -osrt -of "$OUT/$NAME" ${MODEL:+-m "$MODEL"} >/dev/null
               else whisper-cli -f "$OUT/$NAME.wav" -otxt -of "$OUT/$NAME" ${MODEL:+-m "$MODEL"} >/dev/null; fi;;
  *) echo "no ASR engine found; run: $0 --check" >&2; exit 1;;
esac
echo "$OUT/$NAME.$FORMAT"
