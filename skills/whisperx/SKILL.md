---
name: transcribe
description: Local speech-to-text using whisper-cli. Runs medium model first; upgrades to large-v3-turbo if quality is low.
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

## Notes

- Input is auto-converted to 16kHz mono WAV via ffmpeg
- Default language: English
