#!/usr/bin/env node
// Transcription script: Agentspeak server (primary), ElevenLabs direct API (fallback).
// Usage: node --import tsx transcribe.ts <audio-file-path>

import { existsSync, readFileSync } from "node:fs";
import { basename, resolve } from "node:path";

const audioFile = process.argv[2];
if (!audioFile) {
  console.error("Usage: transcribe.ts <audio-file-path>");
  process.exit(1);
}

const filePath = resolve(audioFile);
const fileBuffer = readFileSync(filePath);
const fileName = basename(filePath);

function normalizeBaseUrl(url: string): string {
  return url.replace(/\/+$/, "");
}

function unique(values: string[]): string[] {
  return [...new Set(values.filter(Boolean).map(normalizeBaseUrl))];
}

function resolveAgentspeakUrls(): string[] {
  const configured = process.env.AGENTSPEAK_URL;
  if (configured) {
    return unique(configured.split(",").map((value) => value.trim()));
  }

  const port = process.env.AGENTSPEAK_PORT || "8080";
  const serviceUrl = "http://agentspeak:8080";
  const hostUrls = [`http://localhost:${port}`, `http://127.0.0.1:${port}`];

  return existsSync("/.dockerenv")
    ? unique([serviceUrl, ...hostUrls])
    : unique([...hostUrls, serviceUrl]);
}

function buildAudioForm(): FormData {
  const form = new FormData();
  form.append("audio", new Blob([fileBuffer]), fileName);
  form.append("file", new Blob([fileBuffer]), fileName);
  form.append("language", "he");
  return form;
}

function describeFetchError(error: unknown): string {
  if (error instanceof Error && error.name === "AbortError") {
    return "timeout";
  }

  const cause = error instanceof Error ? error.cause : undefined;
  const nestedCause =
    typeof cause === "object" && cause != null && "errors" in cause && Array.isArray(cause.errors)
      ? cause.errors.find((item) => {
          return typeof item === "object" && item != null && ("code" in item || "message" in item);
        })
      : null;

  if (typeof nestedCause === "object" && nestedCause != null) {
    const message = error instanceof Error ? error.message : String(error);
    if ("code" in nestedCause && typeof nestedCause.code === "string") {
      return `${message}: ${nestedCause.code}`;
    }
    if ("message" in nestedCause && typeof nestedCause.message === "string") {
      return `${message}: ${nestedCause.message}`;
    }
  }

  if (
    typeof cause === "object" &&
    cause != null &&
    "code" in cause &&
    typeof cause.code === "string"
  ) {
    const message = error instanceof Error ? error.message : String(error);
    return `${message}: ${cause.code}`;
  }

  return error instanceof Error ? error.message : String(error);
}

async function transcribeViaAgentspeak(): Promise<string | null> {
  const urls = resolveAgentspeakUrls();

  for (const url of urls) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5_000);

    try {
      const res = await fetch(`${url}/v1/voice/transcribe`, {
        method: "POST",
        body: buildAudioForm(),
        signal: controller.signal,
      });

      if (!res.ok) {
        const body = await res.text();
        console.error(`AGENTSPEAK_ERROR: ${url}: ${res.status}: ${body}`);
        continue;
      }

      const result = (await res.json()) as { transcript?: string; text?: string };
      const transcript = result.transcript?.trim() || result.text?.trim();
      if (transcript) {
        return transcript;
      }
      console.error(`AGENTSPEAK_ERROR: ${url}: empty transcript`);
    } catch (error) {
      console.error(`AGENTSPEAK_ERROR: ${url}: ${describeFetchError(error)}`);
    } finally {
      clearTimeout(timeout);
    }
  }

  return null;
}

async function transcribeViaElevenLabs(): Promise<string> {
  const credentialsFile = process.env.ELEVENLABS_CREDENTIALS_FILE;
  if (!credentialsFile) {
    throw new Error("ELEVENLABS_CREDENTIALS_FILE env var is not set");
  }

  const apiKey = readFileSync(credentialsFile, "utf8").trim();
  if (!apiKey) {
    throw new Error(`ElevenLabs credentials file is empty: ${credentialsFile}`);
  }

  const form = new FormData();
  form.append("file", new Blob([fileBuffer]), fileName);
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
      console.error("RATE_LIMIT: ElevenLabs rate limit reached");
      process.exit(1);
    }
    throw new Error(`ElevenLabs API ${res.status}: ${body}`);
  }

  const result = (await res.json()) as { text?: string };
  return result.text ?? "";
}

const transcript = await transcribeViaAgentspeak();
if (transcript) {
  console.log(transcript);
  process.exit(0);
}

try {
  const fallbackTranscript = await transcribeViaElevenLabs();
  console.log(fallbackTranscript);
} catch (error) {
  const message = error instanceof Error ? error.message : String(error);
  console.error(`ERROR: ${message}`);
  process.exit(1);
}
