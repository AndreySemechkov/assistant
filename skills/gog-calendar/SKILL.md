---
name: gog-calendar
description: Add, update, list, or delete Google Calendar events using gog. Use when the user asks to schedule something, add an event, create a reminder on the calendar, or check upcoming events.
metadata: { "openclaw": { "emoji": "📅", "requires": { "bins": ["gog"] } } }
---

# gog-calendar

Manage Google Calendar events via `gog`.

## Binary path (in Docker)

`/home/linuxbrew/.linuxbrew/bin/gog`

## Important rules

- Always confirm the event details (title, date, time, duration) before creating.
- Use Israel time (Asia/Jerusalem) for display; convert to RFC3339 with the correct UTC offset for API calls.
- **Football/soccer games: always set duration to 1.5 hours** (90 minutes), regardless of what the user says, unless they explicitly specify a different end time.
- Use `primary` as the calendarId unless the user specifies a different calendar.

## Find available calendars

```bash
gog calendar calendars --json --account <YOUR-EMAIL-FROM-MEMORY>
```

## List upcoming events

```bash
gog calendar events primary --from <RFC3339> --to <RFC3339> --json --account <YOUR-EMAIL-FROM-MEMORY>
```

## Create an event

```bash
gog calendar create primary \
  --summary "Event title" \
  --from "2026-03-10T20:00:00+02:00" \
  --to   "2026-03-10T21:30:00+02:00" \
  --description "Optional details" \
  --account <YOUR-EMAIL-FROM-MEMORY> \
  --json
```

### Football game (always 1.5h)

```bash
gog calendar create primary \
  --summary "Man City vs Arsenal" \
  --from "2026-03-10T20:00:00+02:00" \
  --to   "2026-03-10T21:30:00+02:00" \
  --description "Premier League – Etihad Stadium" \
  --account <YOUR-EMAIL-FROM-MEMORY> \
  --json
```

`--to` = `--from` + 90 minutes. Always.

### Optional flags

| Flag                          | Purpose                                          |
| ----------------------------- | ------------------------------------------------ |
| `--location "Etihad Stadium"` | Physical or broadcast location                   |
| `--event-color <1-11>`        | Color (see below)                                |
| `--reminder popup:30m`        | Popup reminder 30 min before                     |
| `--reminder email:1d`         | Email reminder 1 day before                      |
| `--all-day`                   | All-day event (use date-only in `--from`/`--to`) |
| `--rrule "RRULE:FREQ=WEEKLY"` | Recurring event                                  |

## Update an event

```bash
gog calendar update primary <eventId> \
  --summary "New title" \
  --from "2026-03-10T21:00:00+02:00" \
  --to   "2026-03-10T22:30:00+02:00" \
  --account <YOUR-EMAIL-FROM-MEMORY>
```

## Delete an event

```bash
gog calendar delete primary <eventId> --account <YOUR-EMAIL-FROM-MEMORY>
```

## Search events

```bash
gog calendar search "Man City" --json --account <YOUR-EMAIL-FROM-MEMORY>
```

## Calendar colors

| ID  | Color               |
| --- | ------------------- |
| 1   | Lavender (#a4bdfc)  |
| 2   | Sage (#7ae7bf)      |
| 3   | Grape (#dbadff)     |
| 4   | Flamingo (#ff887c)  |
| 5   | Banana (#fbd75b)    |
| 6   | Tangerine (#ffb878) |
| 7   | Peacock (#46d6db)   |
| 8   | Graphite (#e1e1e1)  |
| 9   | Blueberry (#5484ed) |
| 10  | Sage (#51b749)      |
| 11  | Tomato (#dc2127)    |

Run `gog calendar colors` to see the live list.

## Notes

- RFC3339 format: `2026-03-10T20:00:00+02:00` (Israel standard) or `+03:00` (Israel daylight saving).
- `gog` uses `--account` to select which Google account to act on. Default account can be set via `GOG_ACCOUNT=<YOUR-EMAIL-FROM-MEMORY>`.
- For football games, use `--event-color 9` (Blueberry) to distinguish them visually.
