# OpenClaw GCP Deployment

Secure deployment of OpenClaw AI Assistant on GCP Free Tier.

## Prerequisites

- GCP project with billing enabled
- Terraform >= 1.9.0

## GCP Authentication Setup

### 1. Install gcloud CLI

```bash
# macOS
brew install google-cloud-sdk

# Linux
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

### 2. Authenticate with GCP

```bash
# Login to your Google account
gcloud auth login

# Set your project
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable compute.googleapis.com
gcloud services enable iap.googleapis.com

# Setup application default credentials (for Terraform)
gcloud auth application-default login
```

### 3. Verify Authentication

```bash
gcloud auth list
gcloud config get-value project
```

## Terraform Deployment

### 1. Initialize

```bash
cd gcp/openclaw
terraform init
```

### 2. Review Variables

Create a `terraform.tfvars` file:

```hcl
project_id      = "your-gcp-project-id"
container_image = "docker.io/andreysemechkov/openclaw:latest"

# Optional overrides
region            = "us-west1"
machine_type      = "e2-micro"
boot_disk_size_gb = 10
data_disk_size_gb = 20
```

### 3. Plan and Apply

```bash
terraform plan
terraform apply
```

### 4. Note the Outputs

```bash
terraform output ssh_tunnel_command
```

## IAP Tunnel Access

### 1. Authenticate for IAP

```bash
# Ensure you're logged in
gcloud auth login

# Grant yourself IAP tunnel permissions (if not already)
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="user:YOUR_EMAIL@example.com" \
  --role="roles/iap.tunnelResourceAccessor"
```

### 2. Establish SSH Tunnel

```bash
gcloud compute ssh openclaw \
  --zone=us-west1-a \
  --tunnel-through-iap \
  -- -L 18789:localhost:18789 \
     -L 18793:localhost:18793 \
     -L 18791:localhost:18791
```

Or use terraform output:

```bash
$(terraform output -raw ssh_tunnel_command)
```

### 3. Access Services (while tunnel is open)

| Service | URL | Description |
|---------|-----|-------------|
| Gateway | http://localhost:18789 | Main UI, API, WebSocket |
| Canvas | http://localhost:18793 | File server |
| Browser | http://localhost:18791 | CDP control |

## Storage

All OpenClaw data is stored on the attached persistent disk mounted at `/home/openclaw`:

```
/home/openclaw/           ← 20GB attached persistent disk
├── .clawdbot/            ← Configuration (chmod 700)
├── .openclaw/            ← Workspace
│   └── workspace/canvas/
└── data/                 ← Container data volume
```

The disk persists across VM restarts and can be resized via Terraform (`data_disk_size_gb` variable).

## Backup

**Disabled by default** (snapshots not in free tier, ~$1/month).

To enable daily snapshots, uncomment the backup resources in `main.tf`.

| Setting | Default | Variable |
|---------|---------|----------|
| Schedule | Daily at 03:00 UTC | `snapshot_start_time` |
| Retention | 3 snapshots | `snapshot_retention_days` |

### Manual Snapshot

```bash
gcloud compute disks snapshot openclaw-data \
  --zone=us-west1-a \
  --snapshot-names=openclaw-manual-$(date +%Y%m%d)
```

### Restore from Snapshot

```bash
# List available snapshots
gcloud compute snapshots list --filter="sourceDisk~openclaw-data"

# Create a new disk from snapshot
gcloud compute disks create openclaw-data-restored \
  --source-snapshot=SNAPSHOT_NAME \
  --zone=us-west1-a
```

## Configuration

SSH into the VM and edit the config:

```bash
sudo nano /home/openclaw/.clawdbot/config.json
```

Add your Telegram ID to `allowFrom`:

```json
{
  "allowFrom": ["YOUR_TELEGRAM_ID"]
}
```

Restart the service:

```bash
sudo systemctl restart openclaw
```

## Docker Run Command

The default docker run command executed by the systemd service:

```bash
docker run --name openclaw \
  --user <openclaw_uid>:<openclaw_gid> \
  --network host \
  --restart unless-stopped \
  -v /home/openclaw/.clawdbot:/home/openclaw/.clawdbot \
  -v /home/openclaw/.openclaw:/home/openclaw/.openclaw \
  -v /home/openclaw/data:/data \
  -e HOME=/home/openclaw \
  <container_image>
```

Custom args can be passed via `docker_run_args` terraform variable.

## Logs

```bash
# Startup script log
sudo tail -f /var/log/openclaw-setup.log

# Container service logs
sudo journalctl -u openclaw -f

# Docker container logs
sudo docker logs -f openclaw
```

## Troubleshooting

### IAP Tunnel Fails

```bash
# Check IAP permissions
gcloud projects get-iam-policy YOUR_PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.role:roles/iap.tunnelResourceAccessor"

# Check VM is running
gcloud compute instances describe openclaw --zone=us-west1-a
```

### Container Not Starting

```bash
# SSH into VM
gcloud compute ssh openclaw --zone=us-west1-a --tunnel-through-iap

# Check service status
sudo systemctl status openclaw

# Check docker
sudo docker ps -a
sudo docker logs openclaw
```

## GCP Free Tier Limits

| Resource | Allocation | Limit |
|----------|------------|-------|
| VM | e2-micro | 1/month in us-west1, us-central1, us-east1 |
| Boot disk | 10GB pd-standard | 30GB total |
| Data disk | 20GB pd-standard | (included above) |
| Egress | - | 1GB/month |

## Cleanup

```bash
terraform destroy -var="project_id=YOUR_PROJECT_ID" -var="container_image=docker.io/andreysemechkov/openclaw:latest"
```
