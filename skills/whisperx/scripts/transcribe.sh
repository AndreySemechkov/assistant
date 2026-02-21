#!/usr/bin/env bash
set -euo pipefail

WHISPER_CLI="/home/linuxbrew/.linuxbrew/bin/whisper-cli"
MODEL_LARGE="/home/node/.openclaw/models/whisper/ggml-large-v3-turbo.bin"
MODEL_MEDIUM="/home/node/.openclaw/models/whisper/ggml-medium.bin"
INPUT=""
LANG="en"

# Quality thresholds
MIN_WORDS=3           # fewer words = likely low quality
MAX_BLANK_RATIO=0.4   # if >40% of lines are [BLANK_AUDIO] = low quality

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

run_whisper() {
  local model="$1"
  "$WHISPER_CLI" -m "$model" -l "$LANG" --no-timestamps "$TMPWAV" 2>/dev/null \
    | tr -s ' ' | sed 's/^ *//' | grep -v '^$' || true
}

check_quality() {
  local text="$1"
  local word_count blank_lines total_lines blank_ratio

  word_count=$(echo "$text" | wc -w | tr -d ' ')
  total_lines=$(echo "$text" | wc -l | tr -d ' ')
  blank_lines=$(echo "$text" | grep -c '\[BLANK_AUDIO\]' || true)

  if [[ "$word_count" -lt "$MIN_WORDS" ]]; then
    echo "low"
    return
  fi

  if [[ "$total_lines" -gt 0 ]]; then
    blank_ratio=$(python3 -c "print(1 if $blank_lines/$total_lines > $MAX_BLANK_RATIO else 0)")
    if [[ "$blank_ratio" == "1" ]]; then
      echo "low"
      return
    fi
  fi

  echo "ok"
}

echo "▶ Running large-v3-turbo model..." >&2
RESULT=$(run_whisper "$MODEL_LARGE")
QUALITY=$(check_quality "$RESULT")

if [[ "$QUALITY" == "low" ]]; then
  echo "⚠ Low quality result, retrying with medium model..." >&2
  MEDIUM_RESULT=$(run_whisper "$MODEL_MEDIUM")
  MEDIUM_QUALITY=$(check_quality "$MEDIUM_RESULT")

  if [[ "$MEDIUM_QUALITY" == "ok" || $(echo "$MEDIUM_RESULT" | wc -w) -gt $(echo "$RESULT" | wc -w) ]]; then
    echo "✓ Using medium model result" >&2
    RESULT="$MEDIUM_RESULT"
  else
    echo "✓ Using large model result (medium was not better)" >&2
  fi
fi

echo "$RESULT"
