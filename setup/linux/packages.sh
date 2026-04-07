#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

info() { echo "  [+] $*"; }

# ── Base system packages ───────────────────────────────────────────────────────
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
  openssh-client \
  ca-certificates \
  netcat-openbsd \
  strace \
  ufw \
  fail2ban \
  unattended-upgrades

# ── Configure unattended-upgrades ──────────────────────────────────────────────
info "Enabling unattended-upgrades..."
sudo dpkg-reconfigure -f noninteractive unattended-upgrades

# ── Configure ufw (deny in, allow out, allow SSH) ─────────────────────────────
info "Configuring ufw..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw --force enable

# ── Configure fail2ban ────────────────────────────────────────────────────────
info "Configuring fail2ban..."
sudo systemctl enable --now fail2ban

# Write a local jail config only if it doesn't exist yet
JAIL_LOCAL="/etc/fail2ban/jail.local"
if [[ ! -f "$JAIL_LOCAL" ]]; then
  sudo tee "$JAIL_LOCAL" > /dev/null <<'JAIL'
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
JAIL
  sudo systemctl reload fail2ban
fi

# ── Tailscale ─────────────────────────────────────────────────────────────────
if ! command -v tailscale &>/dev/null; then
  info "Installing Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh
fi

info "Linux-specific packages installed."
