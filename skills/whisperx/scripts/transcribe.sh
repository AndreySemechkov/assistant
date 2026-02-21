#!/usr/bin/env bash
set -euo pipefail

WHISPER_CLI="/home/linuxbrew/.linuxbrew/bin/whisper-cli"
WHISPER_MODEL="/home/node/.openclaw/models/whisper/ggml-large-v3-turbo.bin"
INPUT=""
LANG="en"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lang) LANG="$2"; shift 2 ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) INPUT="$1"; shift ;;
  esac
done

if [[ -z "$INPUT" ]]; then
  echo "Usage: $0 <audio-file> [--lang <code>]" >&2
  exit 1
fi

if [[ ! -f "$INPUT" ]]; then
  echo "File not found: $INPUT" >&2
  exit 1
fi

TMPWAV=$(mktemp /tmp/transcribe_XXXXXX.wav)
trap 'rm -f "$TMPWAV"' EXIT

ffmpeg -i "$INPUT" -acodec pcm_s16le -ar 16000 -ac 1 "$TMPWAV" -y -loglevel error

"$WHISPER_CLI" \
  -m "$WHISPER_MODEL" \
  -l "$LANG" \
  --no-timestamps \
  "$TMPWAV"
