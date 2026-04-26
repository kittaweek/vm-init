#!/usr/bin/env bash
set -euo pipefail

# ── Helpers ────────────────────────────────────────────────────────────────────
info() { echo "  [+] $*"; }

gh_latest() {
  local repo="$1"
  local strip_v="${2:-false}"
  local auth_header=()
  [[ -n "${GITHUB_TOKEN:-}" ]] && auth_header=(-H "Authorization: token $GITHUB_TOKEN")
  local ver
  ver=$(curl -fsSL "${auth_header[@]}" \
    "https://api.github.com/repos/${repo}/releases/latest" |
    grep '"tag_name"' | cut -d'"' -f4)
  if [[ -z "$ver" ]]; then
    echo "  [!] Failed to fetch version for ${repo} — check network or GITHUB_TOKEN" >&2
    return 1
  fi
  [[ "$strip_v" == "true" ]] && ver="${ver#v}"
  echo "$ver"
}

# ── macOS: ensure Homebrew is installed ────────────────────────────────────────
_ensure_brew() {
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # Add brew to PATH (Apple Silicon or Intel)
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    export PATH="/opt/homebrew/bin:$PATH"
  elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
    export PATH="/usr/local/bin:$PATH"
  fi
}

# ── Linux (apt) ────────────────────────────────────────────────────────────────
_install_linux() {
  export DEBIAN_FRONTEND=noninteractive

  sudo apt-get update -qq

  # ── apt packages ────────────────────────────────────────────────────────────
  APT_PKGS=(
    unzip zip tar curl wget rsync lsof tmux cron
    vim neovim
    fzf htop ncdu mtr
    ripgrep fd-find
    jq
    bat # → batcat on Ubuntu; symlink handled below
  )
  sudo apt-get install -y --no-install-recommends "${APT_PKGS[@]}"

  # btop: not available in older Ubuntu/Debian repos — install from GitHub binary
  if ! command -v btop &>/dev/null; then
    if sudo apt-get install -y --no-install-recommends btop 2>/dev/null; then
      info "btop installed via apt"
    else
      info "Installing btop from GitHub..."
      {
        BTOP_VER="$(gh_latest aristocratos/btop)"
        ARCH_B="$(uname -m)"
        case "$ARCH_B" in
          x86_64) ARCH_B="x86_64" ;;
          aarch64) ARCH_B="aarch64" ;;
        esac
        BTOP_TGZ="btop-${ARCH_B}-linux-musl.tbz"
        curl -fsSL "https://github.com/aristocratos/btop/releases/download/${BTOP_VER}/${BTOP_TGZ}" \
          -o /tmp/btop.tbz
        sudo tar -xjf /tmp/btop.tbz -C /tmp/
        sudo install -m 755 /tmp/btop/bin/btop /usr/local/bin/btop
        rm -rf /tmp/btop.tbz /tmp/btop
      } || echo "  [!] btop install failed, continuing..."
    fi
  fi

  # bat ships as 'batcat' on Debian/Ubuntu — create symlink if missing
  if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    sudo ln -sf "$(command -v batcat)" /usr/local/bin/bat
  fi

  # fd ships as 'fdfind' on Debian/Ubuntu — create symlink if missing
  if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
  fi

  # ── fish ─────────────────────────────────────────────────────────────────────
  if ! command -v fish &>/dev/null; then
    info "Installing fish..."
    _DISTRO_ID="$(. /etc/os-release 2>/dev/null && echo "${ID:-unknown}")"
    _DISTRO_LIKE="$(. /etc/os-release 2>/dev/null && echo "${ID_LIKE:-}")"
    if [[ "$_DISTRO_ID" == "ubuntu" ]] || echo "$_DISTRO_LIKE" | grep -q "ubuntu"; then
      # Ubuntu (and Ubuntu-based distros like Mint): use official Launchpad PPA
      sudo apt-get install -y software-properties-common
      sudo apt-add-repository -y ppa:fish-shell/release-4
      sudo apt-get update -qq
      sudo apt-get install -y fish
    else
      # Debian and other Debian-based distros: use OBS build service
      _VER_ID="$(. /etc/os-release 2>/dev/null && echo "${VERSION_ID:-12}")"
      sudo mkdir -p /etc/apt/keyrings
      curl -fsSL "https://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_${_VER_ID}/Release.key" |
        sudo gpg --dearmor -o /etc/apt/keyrings/fish.gpg
      echo "deb [signed-by=/etc/apt/keyrings/fish.gpg] https://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_${_VER_ID}/ /" |
        sudo tee /etc/apt/sources.list.d/fish.list
      sudo apt-get update -qq
      sudo apt-get install -y fish
    fi
  fi

  # ── starship ────────────────────────────────────────────────────────────────
  if ! command -v starship &>/dev/null; then
    info "Installing starship..."
    curl -fsSL https://starship.rs/install.sh | sudo sh -s -- --yes ||
      echo "  [!] starship install failed, continuing..."
  fi

  # ── zoxide ──────────────────────────────────────────────────────────────────
  if ! command -v zoxide &>/dev/null; then
    info "Installing zoxide..."
    # Pass --bin-dir so the binary lands in system PATH regardless of $HOME
    # (running as `sudo sh` sets HOME=/root, which would install to /root/.local/bin)
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh |
      sudo sh -s -- --bin-dir /usr/local/bin ||
      echo "  [!] zoxide install failed, continuing..."
  fi

  # ── atuin ───────────────────────────────────────────────────────────────────
  if ! command -v atuin &>/dev/null; then
    info "Installing atuin..."
    curl -fsSL https://setup.atuin.sh | bash ||
      echo "  [!] atuin install failed, continuing..."
  fi

  # ── eza ─────────────────────────────────────────────────────────────────────
  if ! command -v eza &>/dev/null; then
    info "Installing eza..."
    sudo apt-get install -y gpg
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc |
      sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" |
      sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt-get update -qq
    sudo apt-get install -y eza
  fi

  # ── delta ───────────────────────────────────────────────────────────────────
  if ! command -v delta &>/dev/null; then
    info "Installing delta..."
    DELTA_VER="$(gh_latest dandavison/delta)"
    DELTA_DEB="git-delta_${DELTA_VER}_$(dpkg --print-architecture).deb"
    curl -fsSLO "https://github.com/dandavison/delta/releases/download/${DELTA_VER}/${DELTA_DEB}"
    if sudo dpkg -i "$DELTA_DEB"; then
      rm -f "$DELTA_DEB"
    else
      rm -f "$DELTA_DEB"
      echo "  [!] delta install failed, continuing..." >&2
    fi
  fi

  # ── duf ─────────────────────────────────────────────────────────────────────
  if ! command -v duf &>/dev/null; then
    info "Installing duf..."
    DUF_VER="$(gh_latest muesli/duf true)"
    DUF_DEB="duf_${DUF_VER}_linux_$(dpkg --print-architecture).deb"
    curl -fsSLO "https://github.com/muesli/duf/releases/download/v${DUF_VER}/${DUF_DEB}"
    if sudo dpkg -i "$DUF_DEB"; then
      rm -f "$DUF_DEB"
    else
      rm -f "$DUF_DEB"
      echo "  [!] duf install failed, continuing..." >&2
    fi
  fi

  # ── glow ────────────────────────────────────────────────────────────────────
  if ! command -v glow &>/dev/null; then
    info "Installing glow..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key |
      sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" |
      sudo tee /etc/apt/sources.list.d/charm.list
    sudo apt-get update -qq
    sudo apt-get install -y glow
  fi

  # ── fx ──────────────────────────────────────────────────────────────────────
  if ! command -v fx &>/dev/null; then
    info "Installing fx..."
    {
      FX_VER="$(gh_latest antonmedv/fx)"
      ARCH_FX="$(uname -m)"
      case "$ARCH_FX" in
        x86_64) ARCH_FX="amd64" ;;
        aarch64) ARCH_FX="arm64" ;;
      esac
      curl -fsSL "https://github.com/antonmedv/fx/releases/download/${FX_VER}/fx_linux_${ARCH_FX}" \
        -o /tmp/fx
      sudo install -m 755 /tmp/fx /usr/local/bin/fx
      rm -f /tmp/fx
    } || echo "  [!] fx install failed, continuing..."
  fi

  # ── yazi ────────────────────────────────────────────────────────────────────
  if ! command -v yazi &>/dev/null; then
    info "Installing yazi..."
    {
      YAZI_VER="$(gh_latest sxyazi/yazi)"
      ARCH_Y="$(uname -m)"
      case "$ARCH_Y" in
        x86_64) ARCH_Y="x86_64" ;;
        aarch64) ARCH_Y="aarch64" ;;
      esac
      # Release format changed from .tar.gz to .zip
      YAZI_ZIP="yazi-${ARCH_Y}-unknown-linux-musl.zip"
      curl -fsSL "https://github.com/sxyazi/yazi/releases/download/${YAZI_VER}/${YAZI_ZIP}" \
        -o /tmp/yazi.zip
      sudo unzip -oq /tmp/yazi.zip "yazi-${ARCH_Y}-unknown-linux-musl/yazi" -d /tmp/yazi_extract
      sudo install -m 755 "/tmp/yazi_extract/yazi-${ARCH_Y}-unknown-linux-musl/yazi" /usr/local/bin/yazi
      rm -rf /tmp/yazi.zip /tmp/yazi_extract
    } || echo "  [!] yazi install failed, continuing..."
  fi

  # ── rclone ──────────────────────────────────────────────────────────────────
  if ! command -v rclone &>/dev/null; then
    info "Installing rclone..."
    curl -fsSL https://rclone.org/install.sh | sudo bash ||
      echo "  [!] rclone install failed, continuing..."
  fi

  # ── tldr (tealdeer) ─────────────────────────────────────────────────────────
  if ! command -v tldr &>/dev/null; then
    info "Installing tldr (tealdeer)..."
    {
      # Repo moved to tealdeer-rs; filename arch suffix simplified
      TLDR_VER="$(gh_latest tealdeer-rs/tealdeer)"
      ARCH_T="$(uname -m)"
      case "$ARCH_T" in
        x86_64) ARCH_T="x86_64-musl" ;;
        aarch64) ARCH_T="aarch64-musl" ;;
      esac
      curl -fsSL "https://github.com/tealdeer-rs/tealdeer/releases/download/${TLDR_VER}/tealdeer-linux-${ARCH_T}" \
        -o /tmp/tldr
      sudo install -m 755 /tmp/tldr /usr/local/bin/tldr
      rm -f /tmp/tldr
    } || echo "  [!] tldr install failed, continuing..."
  fi
}

# ── macOS (brew) ───────────────────────────────────────────────────────────────
_install_darwin() {
  _ensure_brew

  BREW_PKGS=(
    unzip curl wget rsync lsof tmux
    vim neovim
    fish
    zoxide starship fzf
    htop btop ncdu mtr
    ripgrep fd
    bat eza
    atuin
    delta duf
    jq fx glow
    yazi rclone
    tldr
    tailscale
  )

  brew install "${BREW_PKGS[@]}"
}

# ── Dispatch ───────────────────────────────────────────────────────────────────
case "${OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}" in
  linux) _install_linux ;;
  darwin) _install_darwin ;;
  *)
    echo "common/packages.sh: unsupported OS '$OS'"
    exit 1
    ;;
esac

info "Common packages installed."
