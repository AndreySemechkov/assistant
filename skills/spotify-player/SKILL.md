---
name: spotify-player
description: Terminal Spotify playback/search via spotify_player (preferred) or spogo.
homepage: https://www.spotify.com
metadata: {"clawdbot":{"emoji":"🎵","requires":{"anyBins":["spotify_player","spogo"]},"install":[{"id":"brew","kind":"brew","formula":"spotify_player","bins":["spotify_player"],"label":"Install spotify_player (brew)"},{"id":"brew","kind":"brew","formula":"spogo","tap":"steipete/tap","bins":["spogo"],"label":"Install spogo (brew)"}]}}
---

# spotify_player / spogo

Use `spotify_player` **(preferred)** for Spotify playback/search. Fall back to `spogo` if needed.

Requirements
- Spotify Premium account.
- Either `spogo` or `spotify_player` installed.

spotify_player commands (preferred)
- Search: `spotify_player search "query"`
- Playback: `spotify_player playback play|pause|next|previous`
- Connect device: `spotify_player connect`
- Like track: `spotify_player like`

spogo setup (fallback)
- Import cookies: `spogo auth import --browser chrome`

spogo commands (fallback)
- Search: `spogo search track "query"`
- Playback: `spogo play|pause|next|prev`
- Devices: `spogo device list`, `spogo device set "<name|id>"`
- Status: `spogo status`

Notes
- Docker config folder: `/home/node/.openclaw/spotify-player` (e.g., `/home/node/.openclaw/spotify-player/app.toml`).
- Docker symlink: `/home/node/.config/spotify-player` -> `/home/node/.openclaw/spotify-player`.
- For Spotify Connect integration, set a user `client_id` in config.
- TUI shortcuts are available via `?` in the app.
