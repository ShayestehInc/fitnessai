#!/usr/bin/env bash
#
# One-time DigitalOcean Droplet setup for FitnessAI.
# Run as root on a fresh Ubuntu 22.04 droplet:
#   curl -sSL https://raw.githubusercontent.com/ShayestehInc/fitnessai/main/deploy/server-setup.sh | bash
#
set -euo pipefail

echo "=== FitnessAI Droplet Setup ==="

# --- 1. System updates ---
echo "[1/7] Updating system packages..."
apt-get update && apt-get upgrade -y

# --- 2. Install Docker ---
echo "[2/7] Installing Docker..."
if ! command -v docker &> /dev/null; then
    apt-get install -y ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl enable docker
    systemctl start docker
    echo "Docker installed successfully."
else
    echo "Docker already installed, skipping."
fi

# --- 3. Create deploy user ---
echo "[3/7] Creating deploy user..."
if ! id "deploy" &> /dev/null; then
    adduser --disabled-password --gecos "Deploy User" deploy
    usermod -aG docker deploy

    # Copy root SSH keys to deploy user
    mkdir -p /home/deploy/.ssh
    cp /root/.ssh/authorized_keys /home/deploy/.ssh/authorized_keys
    chown -R deploy:deploy /home/deploy/.ssh
    chmod 700 /home/deploy/.ssh
    chmod 600 /home/deploy/.ssh/authorized_keys
    echo "deploy user created."
else
    echo "deploy user already exists, ensuring docker group membership."
    usermod -aG docker deploy
fi

# --- 4. SSH hardening ---
echo "[4/7] Hardening SSH..."
SSHD_CONFIG="/etc/ssh/sshd_config"
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONFIG"
sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' "$SSHD_CONFIG"
sed -i 's/^#\?UsePAM.*/UsePAM no/' "$SSHD_CONFIG"
systemctl restart sshd
echo "SSH hardened: root login disabled, password auth disabled."

# --- 5. UFW firewall ---
echo "[5/7] Configuring firewall..."
apt-get install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP
ufw --force enable
echo "Firewall enabled: ports 22, 80 open."

# --- 6. Create 2GB swap ---
echo "[6/7] Setting up swap..."
if [ ! -f /swapfile ]; then
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    # Tune swappiness for a server
    sysctl vm.swappiness=10
    echo 'vm.swappiness=10' >> /etc/sysctl.conf
    echo "2GB swap created."
else
    echo "Swap already exists, skipping."
fi

# --- 7. Create app directory and backup cron ---
echo "[7/7] Setting up app directory and backups..."
mkdir -p /opt/fitnessai/backups
chown -R deploy:deploy /opt/fitnessai

# Install backup cron (runs daily at 3 AM UTC as deploy user)
CRON_LINE="0 3 * * * /opt/fitnessai/deploy/backup.sh >> /opt/fitnessai/backups/backup.log 2>&1"
(crontab -u deploy -l 2>/dev/null | grep -v "backup.sh"; echo "$CRON_LINE") | crontab -u deploy -
echo "Backup cron installed for deploy user."

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. SSH in as 'deploy': ssh deploy@$(curl -s ifconfig.me)"
echo "  2. Clone the repo:     cd /opt/fitnessai && git clone https://github.com/ShayestehInc/fitnessai ."
echo "  3. Copy env file:      cp .env.production.example .env.production"
echo "  4. Edit .env.production with real values"
echo "  5. Start services:     docker compose -f docker-compose.prod.yml --env-file .env.production up -d --build"
echo "  6. Seed admin:         docker exec fitnessai_backend python manage.py seed_admin"
echo ""
