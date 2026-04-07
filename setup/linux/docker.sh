#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

info() { echo "  [+] $*"; }

# ── Helpers ────────────────────────────────────────────────────────────────────
gh_latest() {
  local repo="$1"
  local auth_header=()
  [[ -n "${GITHUB_TOKEN:-}" ]] && auth_header=(-H "Authorization: token $GITHUB_TOKEN")
  local ver
  ver=$(curl -fsSL "${auth_header[@]}" \
    "https://api.github.com/repos/${repo}/releases/latest" |
    grep '"tag_name"' | cut -d'"' -f4)
  if [[ -z "$ver" ]]; then
    echo "  [!] Failed to fetch latest version for ${repo}" >&2
    return 1
  fi
  echo "$ver"
}

# ── Detect distro ─────────────────────────────────────────────────────────────
. /etc/os-release
DISTRO_ID="${ID:-ubuntu}"
DISTRO_CODENAME="${VERSION_CODENAME:-}"

# Debian may not have VERSION_CODENAME — fall back to VERSION_ID mapping
if [[ -z "$DISTRO_CODENAME" ]]; then
  case "${VERSION_ID:-}" in
    "12") DISTRO_CODENAME="bookworm" ;;
    "11") DISTRO_CODENAME="bullseye" ;;
    "10") DISTRO_CODENAME="buster" ;;
    *) DISTRO_CODENAME="bookworm" ;; # safe default
  esac
fi

# Docker supports ubuntu and debian repos directly
case "$DISTRO_ID" in
  ubuntu) DOCKER_REPO="ubuntu" ;;
  debian) DOCKER_REPO="debian" ;;
  *) DOCKER_REPO="ubuntu" ;; # best-effort for derivatives
esac

# ── Arch ───────────────────────────────────────────────────────────────────────
ARCH_DEB="$(dpkg --print-architecture)"
ARCH_RAW="$(uname -m)"
case "$ARCH_RAW" in
  x86_64) ARCH_BIN="amd64" ;;
  aarch64) ARCH_BIN="arm64" ;;
  *) ARCH_BIN="amd64" ;;
esac

# ── Docker Engine + Compose plugin ────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
  info "Installing Docker Engine (${DOCKER_REPO}/${DISTRO_CODENAME})..."
  sudo apt-get install -y --no-install-recommends ca-certificates curl gnupg

  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL "https://download.docker.com/linux/${DOCKER_REPO}/gpg" |
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo "deb [arch=${ARCH_DEB} signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/${DOCKER_REPO} ${DISTRO_CODENAME} stable" |
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
  LAZY_VER="$(gh_latest jesseduffield/lazydocker | tr -d 'v')"
  curl -fsSL \
    "https://github.com/jesseduffield/lazydocker/releases/download/v${LAZY_VER}/lazydocker_${LAZY_VER}_Linux_x86_64.tar.gz" |
    sudo tar -xz -C /usr/local/bin lazydocker
fi

# ── ctop ─────────────────────────────────────────────────────────────────────
if ! command -v ctop &>/dev/null; then
  info "Installing ctop..."
  CTOP_VER="$(gh_latest bcicen/ctop | tr -d 'v')"
  sudo curl -fsSL \
    "https://github.com/bcicen/ctop/releases/download/v${CTOP_VER}/ctop-${CTOP_VER}-linux-${ARCH_BIN}" \
    -o /usr/local/bin/ctop
  sudo chmod +x /usr/local/bin/ctop
fi

info "Docker setup complete. Re-login for group changes to take effect."
