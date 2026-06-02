#!/usr/bin/env node
// Resolve the project-installed tsx binary, then run the TypeScript transcriber.

import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = dirname(fileURLToPath(import.meta.url));
const transcribeScript = join(scriptDir, "transcribe.ts");
const audioFile = process.argv[2];

if (!audioFile) {
  console.error("Usage: run-transcribe.mjs <audio-file-path>");
  process.exit(1);
}

function candidateRoots() {
  const roots = [
    process.env.OPENCLAW_REPO_ROOT,
    process.env.OPENCLAW_PROJECT_DIR,
    process.env.INIT_CWD,
    process.cwd(),
    resolve(scriptDir, "../../.."),
    "/workspace",
    "/app",
    "/home/node/openclaw",
  ];

  return [...new Set(roots.filter(Boolean).map((root) => resolve(root)))];
}

function findTsxBin() {
  for (const root of candidateRoots()) {
    const candidate = join(root, "node_modules", ".bin", "tsx");
    if (existsSync(candidate)) {
      return candidate;
    }
  }
  return null;
}

const tsxBin = findTsxBin();
if (!tsxBin) {
  console.error(
    "ERROR: tsx binary not found. Run `pnpm install` in the OpenClaw project or set OPENCLAW_REPO_ROOT.",
  );
  process.exit(1);
}

const result = spawnSync(tsxBin, [transcribeScript, audioFile], {
  env: process.env,
  stdio: "inherit",
});

if (result.error) {
  console.error(`ERROR: failed to run tsx: ${result.error.message}`);
  process.exit(1);
}

process.exit(result.status ?? 1);
