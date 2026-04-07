---
name: newsfeed
description: Scan Google Drive for docs created or modified today/yesterday and send links to <CREATOR-NUMBER-FROM-MEMORY> via WhatsApp. Use when checking for recent document activity.
metadata: { "openclaw": { "emoji": "📰", "requires": { "bins": ["gog", "wacli"] } } }
---

# newsfeed

Scan Google Drive for documents from today or yesterday and send links to <CREATOR-NUMBER-FROM-MEMORY>.

## Rules

- Only scan docs modified today or yesterday — never the full Drive.
- Send document links, not summaries.
- Do not open or read document contents.

## Workflow

```bash
# 1. Calculate yesterday's date (ISO)
YESTERDAY=$(date -u -d "yesterday" '+%Y-%m-%dT00:00:00' 2>/dev/null || date -u -v-1d '+%Y-%m-%dT00:00:00')

# 2. Search Drive for recent Google Docs
DOCS=$(gog drive search "modifiedTime > '$YESTERDAY' and mimeType='application/vnd.google-apps.document'" --max 20 --json --account <YOUR-EMAIL-FROM-MEMORY>)

# 3. Build a message with links
# Each doc link: https://docs.google.com/document/d/<docId>/edit
echo "$DOCS" | jq -r '.[] | "📄 \(.name)\nhttps://docs.google.com/document/d/\(.id)/edit\n"' > /tmp/newsfeed.txt

# 4. Send to <CREATOR-NUMBER-FROM-MEMORY>
wacli send text --to "<CREATOR-NUMBER-FROM-MEMORY>" --message "$(cat /tmp/newsfeed.txt)"
```

## Notes

- `gog` binary: `/home/linuxbrew/.linuxbrew/bin/gog`
- Config: `/home/node/.config/gogcli/config.json`
- Set `GOG_ACCOUNT=<YOUR-EMAIL-FROM-MEMORY>` to avoid repeating `--account`
- Use `--json` for structured output
- If no docs found, send "No new documents today" to <CREATOR-NUMBER-FROM-MEMORY>
