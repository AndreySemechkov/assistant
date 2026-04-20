#!/bin/bash
set -euo pipefail

# OpenClaw Secure Setup Script
# - Updates Ubuntu system packages
# - Mounts attached persistent disk to /home/openclaw
# - Creates openclaw user and group
# - Installs Docker and runs OpenClaw container

LOG_FILE="/var/log/openclaw-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "=== OpenClaw Setup Started: $(date) ==="

# GCP attached disk uses /dev/disk/by-id/google-{device_name}
DISK_DEVICE="/dev/disk/by-id/google-openclaw-data"
OPENCLAW_HOME="/home/openclaw"

# Get configuration from instance metadata
METADATA_URL="http://metadata.google.internal/computeMetadata/v1/instance/attributes"
METADATA_HEADER="Metadata-Flavor: Google"

CONTAINER_IMAGE=$(curl -sf "$METADATA_URL/CONTAINER_IMAGE" -H "$METADATA_HEADER" || echo "")
DOCKER_RUN_ARGS=$(curl -sf "$METADATA_URL/DOCKER_RUN_ARGS" -H "$METADATA_HEADER" || echo "")
GOOGLE_CLOUD_PROJECT=$(curl -sf "$METADATA_URL/GOOGLE_CLOUD_PROJECT" -H "$METADATA_HEADER" || echo "")

if [ -z "$CONTAINER_IMAGE" ]; then
    echo "ERROR: CONTAINER_IMAGE metadata not set"
    exit 1
fi

echo "Container image: $CONTAINER_IMAGE"
echo "Docker run args: $DOCKER_RUN_ARGS"

# 1) Update Ubuntu system packages
echo "[1/11] Updating Ubuntu system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq
apt-get dist-upgrade -y -qq
apt-get autoremove -y -qq
apt-get autoclean -qq

# 2) Create openclaw group and user
echo "[2/11] Creating openclaw group and user..."
if ! getent group openclaw > /dev/null; then
    groupadd --system openclaw
fi

if ! id "openclaw" &>/dev/null; then
    useradd --system \
        --gid openclaw \
        --create-home \
        --home-dir "$OPENCLAW_HOME" \
        --shell /bin/bash \
        openclaw
fi

# 3) Format and mount attached persistent disk
echo "[3/11] Configuring attached persistent disk..."
if [ -b "$DISK_DEVICE" ]; then
    # Check if already formatted
    if ! blkid "$DISK_DEVICE" | grep -q ext4; then
        echo "Formatting $DISK_DEVICE as ext4..."
        mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard "$DISK_DEVICE"
    fi

    # Create mount point
    mkdir -p "$OPENCLAW_HOME"

    # Add to fstab if not already there
    if ! grep -q "$DISK_DEVICE" /etc/fstab; then
        echo "$DISK_DEVICE $OPENCLAW_HOME ext4 discard,defaults,nofail 0 2" >> /etc/fstab
    fi

    # Mount if not already mounted
    if ! mountpoint -q "$OPENCLAW_HOME"; then
        mount "$OPENCLAW_HOME"
    fi

    echo "Disk mounted at $OPENCLAW_HOME"
else
    echo "WARNING: $DISK_DEVICE not found, using local storage"
    mkdir -p "$OPENCLAW_HOME"
fi

# 4) Set ownership of home directory
echo "[4/11] Setting directory ownership..."
chown openclaw:openclaw "$OPENCLAW_HOME"
chmod 750 "$OPENCLAW_HOME"

# 5) Create OpenClaw directory structure
echo "[5/11] Creating OpenClaw directories..."
mkdir -p "$OPENCLAW_HOME/.clawdbot"
mkdir -p "$OPENCLAW_HOME/.openclaw/workspace/canvas"
mkdir -p "$OPENCLAW_HOME/data"

# 6) Lock Down SSH
echo "[6/11] Hardening SSH configuration..."
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sshd -t && systemctl reload ssh || systemctl reload sshd || true

# 7) Configure UFW firewall
echo "[7/11] Configuring UFW firewall..."
apt-get install -y -qq ufw

ufw default deny incoming
ufw default allow outgoing

# Allow SSH from GCP IAP range only
ufw allow from 35.235.240.0/20 to any port 22 proto tcp comment 'GCP IAP SSH'

# Allow localhost access to OpenClaw ports (for SSH tunnel)
ufw allow from 127.0.0.1 to any port 18789 proto tcp comment 'OpenClaw Gateway'
ufw allow from 127.0.0.1 to any port 18793 proto tcp comment 'OpenClaw Canvas'
ufw allow from 127.0.0.1 to any port 18791 proto tcp comment 'OpenClaw Browser CDP'

ufw --force enable

# 8) Install fail2ban
echo "[8/11] Installing fail2ban..."
apt-get install -y -qq fail2ban
systemctl enable --now fail2ban

# 9) Install Docker
echo "[9/11] Installing Docker..."
apt-get install -y -qq ca-certificates curl gnupg

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Configure Docker daemon
systemctl enable docker
systemctl start docker

# Add openclaw user to docker group
usermod -aG docker openclaw

# 10) Set permissions on clawdbot files
echo "[10/11] Setting file permissions..."
chown -R openclaw:openclaw "$OPENCLAW_HOME/.clawdbot"
chown -R openclaw:openclaw "$OPENCLAW_HOME/.openclaw"
chown -R openclaw:openclaw "$OPENCLAW_HOME/data"
chmod 700 "$OPENCLAW_HOME/.clawdbot"
chmod 700 "$OPENCLAW_HOME/.openclaw"
chmod 750 "$OPENCLAW_HOME/data"

# 11) Create systemd service and start container
echo "[11/11] Creating systemd service and starting container..."

OPENCLAW_UID=$(id -u openclaw)
OPENCLAW_GID=$(id -g openclaw)

cat > /etc/systemd/system/openclaw.service << EOF
[Unit]
Description=OpenClaw AI Assistant Container
After=docker.service network-online.target
Requires=docker.service
Wants=network-online.target

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=10
EnvironmentFile=/etc/default/openclaw

ExecStartPre=-/usr/bin/docker stop openclaw
ExecStartPre=-/usr/bin/docker rm openclaw
ExecStartPre=/usr/bin/docker pull $CONTAINER_IMAGE

ExecStart=/usr/bin/docker run --name openclaw \
    --user $OPENCLAW_UID:$OPENCLAW_GID \
    $DOCKER_RUN_ARGS \
    $CONTAINER_IMAGE

ExecStop=/usr/bin/docker stop openclaw

[Install]
WantedBy=multi-user.target
EOF

# Create environment file for the service
cat > /etc/default/openclaw << EOF
GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT
EOF

systemctl daemon-reload
systemctl enable openclaw
systemctl start openclaw

# Verify
echo ""
echo "=== OpenClaw Setup Complete: $(date) ==="
echo ""
echo "--- System Status ---"
echo "UFW Status:"
ufw status verbose

echo ""
echo "Docker Status:"
systemctl status docker --no-pager || true

echo ""
echo "OpenClaw Container Status:"
systemctl status openclaw --no-pager || true

echo ""
echo "Disk Usage:"
df -h "$OPENCLAW_HOME"

echo ""
echo "Setup complete. See README.md for access instructions."
