#!/usr/bin/env node
// ElevenLabs Scribe v2 transcription script
// Usage: node transcribe.js <audio-file-path>
//
// Reads API key from the file path in ELEVENLABS_CREDENTIALS_FILE env var.
// Uses native fetch (not the SDK) because the API expects "file" but the SDK sends "audio".
// Exits with code 0 and prints transcript on success.
// Exits with non-zero code and prints error to stderr on failure.

import { readFileSync } from "node:fs";
import { resolve, basename } from "node:path";

const audioFile = process.argv[2];
if (!audioFile) {
  console.error("Usage: transcribe.js <audio-file-path>");
  process.exit(1);
}

const credentialsFile = process.env.ELEVENLABS_CREDENTIALS_FILE;
if (!credentialsFile) {
  console.error("ELEVENLABS_CREDENTIALS_FILE env var is not set");
  process.exit(1);
}

let apiKey;
try {
  apiKey = readFileSync(credentialsFile, "utf8").trim();
} catch (err) {
  console.error(`Failed to read ElevenLabs credentials from ${credentialsFile}: ${err.message}`);
  process.exit(1);
}

if (!apiKey) {
  console.error(`ElevenLabs credentials file is empty: ${credentialsFile}`);
  process.exit(1);
}

try {
  const filePath = resolve(audioFile);
  const fileBuffer = readFileSync(filePath);
  const blob = new Blob([fileBuffer]);

  const form = new FormData();
  form.append("file", blob, basename(filePath));
  form.append("model_id", "scribe_v2");
  form.append("language_code", "he");

  const res = await fetch("https://api.elevenlabs.io/v1/speech-to-text", {
    method: "POST",
    headers: { "xi-api-key": apiKey },
    body: form,
  });

  if (!res.ok) {
    const body = await res.text();
    if (res.status === 429) {
      console.error(`RATE_LIMIT: ElevenLabs rate limit reached`);
    } else {
      console.error(`ERROR: ElevenLabs API ${res.status}: ${body}`);
    }
    process.exit(1);
  }

  const result = await res.json();
  console.log(result.text);
} catch (err) {
  console.error(`ERROR: ElevenLabs transcription failed: ${err.message ?? err}`);
  process.exit(1);
}
