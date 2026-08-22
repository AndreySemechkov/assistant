#!/usr/bin/env node
// Run the TypeScript transcriber with Node's built-in type stripping.

import { spawnSync } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = dirname(fileURLToPath(import.meta.url));
const transcribeScript = join(scriptDir, "transcribe.ts");
const audioFile = process.argv[2];

if (!audioFile) {
  console.error("Usage: run-transcribe.mjs <audio-file-path>");
  process.exit(1);
}

const result = spawnSync(process.execPath, [transcribeScript, audioFile], {
  env: process.env,
  stdio: "inherit",
});

if (result.error) {
  console.error(`ERROR: failed to run transcriber: ${result.error.message}`);
  process.exit(1);
}

process.exit(result.status ?? 1);
