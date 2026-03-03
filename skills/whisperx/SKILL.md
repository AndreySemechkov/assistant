---
name: transcribe-local
description: Local speech-to-text using whisper-cli (offline fallback). Runs medium model first; upgrades to large-v3-turbo if quality is low. Use when ElevenLabs transcription fails or is unavailable.
metadata: { "openclaw": { "emoji": "🎙️", "requires": { "bins": ["whisper-cli", "ffmpeg"] } } }
---

# Transcribe (whisper-cli)

Transcribes audio locally. Runs the medium model first for speed. If the result has fewer than 3 words or more than 40% `[BLANK_AUDIO]` segments, upgrades with the large-v3-turbo model and picks the better output.

## Quick start

```bash
{baseDir}/scripts/transcribe.sh /path/to/audio.ogg
```

## Options

```bash
{baseDir}/scripts/transcribe.sh /path/to/audio.ogg --lang he    # Hebrew
{baseDir}/scripts/transcribe.sh /path/to/audio.ogg --lang auto  # auto-detect
```

## Models

- Primary: `ggml-medium.bin`
- Fallback: `ggml-large-v3-turbo.bin`
- Both at: `/home/node/.openclaw/models/whisper/`

## ⚠️ Script timeout — use direct execution for large model

`transcribe.sh` has a 50-second timeout. The large-v3-turbo model takes longer than that to load and will be **killed by SIGTERM** if run via the script.

**If the script fails or quality is still low after the script's upgrade attempt, bypass it entirely:**

```bash
# 1. Convert to 16kHz mono WAV
ffmpeg -i /path/to/audio.ogg -ar 16000 -ac 1 /tmp/audio.wav

# 2. Run large-v3-turbo directly (no timeout)
/home/linuxbrew/.linuxbrew/bin/whisper-cli \
  -m /home/node/.openclaw/models/whisper/ggml-large-v3-turbo.bin \
  -l auto \
  --no-timestamps \
  -f /tmp/audio.wav
```

Direct execution has no timeout and reliably handles the large model's slower load time.

## Notes

- Input is auto-converted to 16kHz mono WAV via ffmpeg
- Default language: English
