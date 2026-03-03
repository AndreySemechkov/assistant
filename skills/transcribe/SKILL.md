---
name: transcribe
description: Cloud speech-to-text using ElevenLabs Scribe v2. Primary transcription skill for voice messages. Falls back to transcribe-local (whisper) on error.
metadata: { "openclaw": { "emoji": "🎙️", "requires": { "bins": ["node"] } } }
---

# Transcribe (ElevenLabs Scribe v2)

Primary voice transcription using ElevenLabs Scribe v2 cloud API. Language: Hebrew (`he`).

## Usage

```bash
node {baseDir}/scripts/transcribe.js /path/to/audio.ogg
```

## Fallback

If the script exits with a non-zero code (rate limit, API error, missing key):

1. Inform the user: _"ElevenLabs transcription failed ([reason]). Falling back to local whisper…"_
2. Use the `transcribe-local` skill (whisper-cli direct execution — not the script, to avoid the 50s timeout):
   ```
   /home/linuxbrew/.linuxbrew/bin/whisper-cli -m /home/node/.openclaw/models/whisper/ggml-large-v3-turbo.bin -l auto --no-timestamps -f <audio-file>
   ```

## Error codes from the script

| stderr prefix | Meaning                          |
| ------------- | -------------------------------- |
| `RATE_LIMIT:` | 429 — ElevenLabs quota hit       |
| `ERROR:`      | Any other API or network failure |

## Notes

- API key is read at runtime from `$ELEVENLABS_CREDENTIALS_FILE` (set in docker-compose)
- Audio file is passed as-is; ElevenLabs accepts OGG, MP3, WAV, M4A, and more
- Language is set to Hebrew (`language_code: "he"`)
