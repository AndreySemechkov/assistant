import { defineConfig } from "openclaw";

export default defineConfig({
  agents: {
    defaults: {
      sandbox: {
        mode: "all",
        scope: "shared",
        workspaceAccess: "rw",
      },
    },
  },
  tools: {
    media: {
      audio: {
        enabled: true,
        maxBytes: 20971520,
        models: [
          {
            provider: "openai",
            model: "gpt-4o-mini-transcribe",
          },
          {
            type: "cli",
            command: "/home/linuxbrew/.linuxbrew/bin/whisper-cli",
            args: [
              "-m",
              "/home/node/.openclaw/models/whisper/base.bin",
              "-f",
              "{{MediaPath}}",
              "--output-txt",
            ],
            timeoutSeconds: 45,
          },
        ],
      },
    },
  },
});
