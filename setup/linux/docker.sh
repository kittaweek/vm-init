#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

info() { echo "  [+] $*"; }

# ── Docker Engine + Compose plugin ────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
  info "Installing Docker Engine..."
  sudo apt-get install -y --no-install-recommends ca-certificates curl gnupg

  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg |
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
    sudo tee /etc/apt/sources.list.d/docker.list

  sudo apt-get update -qq
  sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
fi

# Enable & start Docker
sudo systemctl enable --now docker

# Add current user to docker group (no sudo needed after re-login)
if ! groups "$USER" | grep -q docker; then
  info "Adding $USER to docker group..."
  sudo usermod -aG docker "$USER"
fi

# ── lazydocker ────────────────────────────────────────────────────────────────
if ! command -v lazydocker &>/dev/null; then
  info "Installing lazydocker..."
  LAZY_VER=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazydocker/releases/latest |
    grep '"tag_name"' | cut -d'"' -f4 | tr -d 'v')
  ARCH_L="$(uname -m)"
  case "$ARCH_L" in
    x86_64) ARCH_L="x86_64" ;;
    *) ARCH_L="x86_64" ;; # fallback; non-ARM guard is in install.sh
  esac
  curl -fsSL \
    "https://github.com/jesseduffield/lazydocker/releases/download/v${LAZY_VER}/lazydocker_${LAZY_VER}_Linux_${ARCH_L}.tar.gz" |
    sudo tar -xz -C /usr/local/bin lazydocker
fi

# ── ctop ─────────────────────────────────────────────────────────────────────
if ! command -v ctop &>/dev/null; then
  info "Installing ctop..."
  CTOP_VER=$(curl -fsSL https://api.github.com/repos/bcicen/ctop/releases/latest |
    grep '"tag_name"' | cut -d'"' -f4)
  sudo curl -fsSL \
    "https://github.com/bcicen/ctop/releases/download/${CTOP_VER}/ctop-${CTOP_VER}-linux-amd64" \
    -o /usr/local/bin/ctop
  sudo chmod +x /usr/local/bin/ctop
fi

info "Docker setup complete. Re-login for group changes to take effect."
