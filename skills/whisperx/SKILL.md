---
name: transcribe
description: Local speech-to-text using whisper-cli with the large-v3-turbo model.
metadata: { "openclaw": { "emoji": "🎙️", "requires": { "bins": ["whisper-cli", "ffmpeg"] } } }
---

# Transcribe (whisper-cli)

Use `whisper-cli` to transcribe audio locally with the large-v3-turbo model.

## Quick start

```bash
{baseDir}/scripts/transcribe.sh /path/to/audio.ogg
```

Output is printed to stdout and saved as `<input>.txt`.

## Options

```bash
{baseDir}/scripts/transcribe.sh /path/to/audio.ogg --lang he    # Hebrew
{baseDir}/scripts/transcribe.sh /path/to/audio.ogg --lang auto  # auto-detect
```

## Setup

- CLI: `/home/linuxbrew/.linuxbrew/bin/whisper-cli`
- Model: `/home/node/.openclaw/models/whisper/ggml-large-v3-turbo.bin`
- Input is auto-converted to 16kHz mono WAV via ffmpeg
