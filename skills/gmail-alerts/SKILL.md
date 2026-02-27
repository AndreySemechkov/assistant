---
name: gmail-alerts
description: Monitor Gmail for forwarded emails and send a WhatsApp summary to Andrey for each one.
metadata: { "openclaw": { "emoji": "📧", "requires": { "bins": ["gog", "wacli"] } } }
---

# gmail-alerts

Monitor Gmail for forwarded emails and notify Andrey on WhatsApp with a concise summary of each one.

## Prerequisites

- `gog` authenticated with Gmail (see OAuth Setup below)
- `wacli` authenticated (WhatsApp)
- Andrey's WhatsApp JID — run `wacli chats list --query "Andrey"` to find it, or use his phone number directly: `"+XXXXXXXXXXXX"`

## Check for forwarded emails

Search Gmail for unread forwarded emails (covers both manually forwarded `Fwd:` and auto-forwarded):

```bash
# Manually forwarded (subject starts with Fwd:)
gog gmail messages search "subject:Fwd is:unread" --max 20 --json --account you@gmail.com

# Auto-forwarded (arrived via a forwarding rule, no Fwd: subject prefix)
gog gmail messages search "is:unread deliveredto:you@gmail.com" --max 20 --json --account you@gmail.com

# Combined — catches both patterns
gog gmail messages search "is:unread (subject:Fwd OR label:forwarded)" --max 20 --json --account you@gmail.com
```

## Read an email body

```bash
gog gmail get <messageId> --json --account you@gmail.com
```

## Workflow: forwarded email → WhatsApp summary

For each unread forwarded email found:

1. Fetch the full message with `gog gmail get <messageId> --json`
2. Extract: sender, original subject, date, and body text
3. Write a short summary (2–4 lines): who forwarded it, from whom originally, and what it's about
4. Send to Andrey via WhatsApp:

```bash
wacli send text --to "+XXXXXXXXXXXX" --message "📧 Forwarded email summary:

From: <original sender>
Subject: <subject>
Forwarded by: <forwarder>

<2-3 sentence summary of the email content>"
```

5. Mark the email as read so it's not re-processed:

```bash
gog gmail messages modify <messageId> --remove-labels UNREAD --account you@gmail.com
```

## Full example (single email)

```bash
# 1. Find forwarded unread emails
MSGS=$(gog gmail messages search "subject:Fwd is:unread" --max 5 --json --results-only --account you@gmail.com)

# 2. For each message ID, fetch and process
echo "$MSGS" | jq -r '.[].id' | while read msgId; do
  BODY=$(gog gmail get "$msgId" --json --account you@gmail.com)
  # Summarize BODY and send via wacli, then mark read
  gog gmail messages modify "$msgId" --remove-labels UNREAD --account you@gmail.com
done
```

## OAuth Setup (one-time)

See the **OAuth Setup** section below.

---

## OAuth Setup for Gmail

### Step 1 — Create a Google Cloud project

1. Go to https://console.cloud.google.com/
2. Click **Select a project** → **New Project**
3. Name it (e.g. `openclaw-gmail`) → **Create**

### Step 2 — Enable the Gmail API

1. In your project, go to **APIs & Services** → **Library**
2. Search for **Gmail API** → click it → **Enable**

### Step 3 — Configure the OAuth consent screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Choose **External** → **Create**
3. Fill in:
   - App name: `openclaw`
   - User support email: your Gmail
   - Developer contact: your Gmail
4. Click **Save and Continue** through Scopes and Test Users
5. On **Test users**, click **Add users** → add your Gmail address
6. **Save and Continue** → **Back to Dashboard**

### Step 4 — Create OAuth credentials

1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth client ID**
3. Application type: **Desktop app**
4. Name: `openclaw-desktop` → **Create**
5. Click **Download JSON** → save as `client_secret.json`

### Step 5 — Place credentials in the .openclaw volume

The container mounts `~/.openclaw` at `/home/node/.openclaw`. Save the file there on the host:

```bash
mkdir -p ~/.openclaw/credentials
cp /path/to/client_secret.json ~/.openclaw/credentials/client_secret.json
```

### Step 6 — Register credentials with gog

```bash
docker exec -it assistant-openclaw-gateway-1 bash -c \
  '/home/linuxbrew/.linuxbrew/bin/gog auth credentials set /home/node/.openclaw/credentials/client_secret.json'
```

### Step 7 — Authorize your Gmail account

```bash
docker exec -it assistant-openclaw-gateway-1 bash -c \
  '/home/linuxbrew/.linuxbrew/bin/gog auth add you@gmail.com --services gmail'
```

This prints a URL. Open it in your browser, sign in with your Google account, grant access, then paste the authorization code back into the terminal.

### Step 8 — Verify

```bash
docker exec assistant-openclaw-gateway-1 bash -c \
  '/home/linuxbrew/.linuxbrew/bin/gog auth list'
```

You should see your Gmail address listed as authenticated.

### Step 9 — Test

```bash
docker exec assistant-openclaw-gateway-1 bash -c \
  '/home/linuxbrew/.linuxbrew/bin/gog gmail search "is:unread" --max 3 --account you@gmail.com'
```

---

## Notes

- `gog` binary: `/home/linuxbrew/.linuxbrew/bin/gog` (v0.11.0)
- Config stored at: `/home/node/.config/gogcli/config.json`
- Set `GOG_ACCOUNT=you@gmail.com` to avoid repeating `--account` every command
- Use `--json --results-only` for scripting
- Gmail query `subject:Fwd` catches manually forwarded emails; auto-forwarded emails from Gmail settings won't have that prefix — adjust the query to match your setup
