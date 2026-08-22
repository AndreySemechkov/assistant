---
name: transcribe
description: Speech-to-text through the local AgentSpeak service, with direct ElevenLabs and local Whisper fallbacks.
metadata: { "openclaw": { "emoji": "🎙️", "requires": { "bins": ["node"] } } }
---

# Transcribe (AgentSpeak)

Primary voice transcription through the local AgentSpeak service. AgentSpeak uses
ElevenLabs Scribe v2 for speech-to-text. Language: Hebrew (`he`).

## Usage

```bash
node {baseDir}/scripts/run-transcribe.mjs /path/to/audio.ogg
```

## Fallback

If both AgentSpeak and the direct ElevenLabs fallback fail:

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

- AgentSpeak is reached at `$AGENTSPEAK_URL`, or at the Compose service name
  `http://agentspeak:8080` by default
- The direct fallback API key is read from `$ELEVENLABS_CREDENTIALS_FILE`
- Audio file is passed as-is; ElevenLabs accepts OGG, MP3, WAV, M4A, and more
- Language is set to Hebrew (`language_code: "he"`)
