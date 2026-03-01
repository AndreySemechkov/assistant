---
name: gmail-alerts
description: Monitor Gmail for unread emails and send a WhatsApp summary to <CREATOR-NAME-FROM-MEMORY>.
metadata: { "openclaw": { "emoji": "📧", "requires": { "bins": ["gog", "wacli"] } } }
---

# gmail-alerts

Monitor Gmail for **unread** emails and notify <CREATOR-NAME-FROM-MEMORY> on WhatsApp with a concise summary.

## Rules

- Always include `is:unread` in every Gmail query.
- Never scan the full inbox unless explicitly asked.
- Mark each email as read after processing.

## Workflow

```bash
# 1. Find unread emails
MSGS=$(gog gmail messages search "is:unread" --max 10 --json --results-only --account <YOUR-EMAIL-FROM-MEMORY>)

# 2. For each message, fetch, summarize, send, mark read
echo "$MSGS" | jq -r '.[].id' | while read msgId; do
  gog gmail get "$msgId" --json --account <YOUR-EMAIL-FROM-MEMORY>
  # summarize and send via wacli
  wacli send text --to "<CREATOR-NUMBER-FROM-MEMORY>" --message "📧 From: <sender>\nSubject: <subject>\n\n<summary>"
  gog gmail messages modify "$msgId" --remove-labels UNREAD --account <YOUR-EMAIL-FROM-MEMORY>
done
```

## Common queries

| Intent           | Query                                              |
| ---------------- | -------------------------------------------------- |
| All unread       | `"is:unread"`                                      |
| Forwarded (Fwd:) | `"is:unread subject:Fwd"`                          |
| Auto-forwarded   | `"is:unread deliveredto:<YOUR-EMAIL-FROM-MEMORY>"` |

## Notes

- `gog` binary: `/home/linuxbrew/.linuxbrew/bin/gog` (v0.11.0)
- Config stored at: `/home/node/.config/gogcli/config.json`
- Set `GOG_ACCOUNT=<YOUR-EMAIL-FROM-MEMORY>` to avoid repeating `--account` every command
- Use `--json --results-only` for scripting
- Gmail query `subject:Fwd` catches manually forwarded emails; auto-forwarded emails from Gmail settings won't have that prefix — adjust the query to match your setup
