#!/usr/bin/env bash
set -euo pipefail

# ── Helpers ────────────────────────────────────────────────────────────────────
info() { echo "  [+] $*"; }

# ── macOS: ensure Homebrew is installed ────────────────────────────────────────
_ensure_brew() {
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for Apple Silicon
    if [[ -f /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
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
    fzf htop btop ncdu mtr
    ripgrep fd-find
    jq
    bat # → batcat on Ubuntu; symlink handled below
  )
  sudo apt-get install -y --no-install-recommends "${APT_PKGS[@]}"

  # bat ships as 'batcat' on Debian/Ubuntu — create symlink if missing
  if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    sudo ln -sf "$(command -v batcat)" /usr/local/bin/bat
  fi

  # fd ships as 'fdfind' on Debian/Ubuntu — create symlink if missing
  if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
  fi

  # ── fish (official PPA) ──────────────────────────────────────────────────────
  if ! command -v fish &>/dev/null; then
    info "Installing fish via PPA..."
    sudo apt-get install -y software-properties-common
    sudo apt-add-repository -y ppa:fish-shell/release-3
    sudo apt-get update -qq
    sudo apt-get install -y fish
  fi

  # ── starship ────────────────────────────────────────────────────────────────
  if ! command -v starship &>/dev/null; then
    info "Installing starship..."
    curl -fsSL https://starship.rs/install.sh | sudo sh -s -- --yes
  fi

  # ── zoxide ──────────────────────────────────────────────────────────────────
  if ! command -v zoxide &>/dev/null; then
    info "Installing zoxide..."
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sudo sh
  fi

  # ── atuin ───────────────────────────────────────────────────────────────────
  if ! command -v atuin &>/dev/null; then
    info "Installing atuin..."
    curl -fsSL https://setup.atuin.sh | bash
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
    DELTA_VER=$(curl -fsSL https://api.github.com/repos/dandavison/delta/releases/latest |
      grep '"tag_name"' | cut -d'"' -f4)
    DELTA_DEB="git-delta_${DELTA_VER}_$(dpkg --print-architecture).deb"
    curl -fsSLO "https://github.com/dandavison/delta/releases/download/${DELTA_VER}/${DELTA_DEB}"
    sudo dpkg -i "$DELTA_DEB"
    rm -f "$DELTA_DEB"
  fi

  # ── duf ─────────────────────────────────────────────────────────────────────
  if ! command -v duf &>/dev/null; then
    info "Installing duf..."
    DUF_VER=$(curl -fsSL https://api.github.com/repos/muesli/duf/releases/latest |
      grep '"tag_name"' | cut -d'"' -f4 | tr -d 'v')
    DUF_DEB="duf_${DUF_VER}_linux_$(dpkg --print-architecture).deb"
    curl -fsSLO "https://github.com/muesli/duf/releases/download/v${DUF_VER}/${DUF_DEB}"
    sudo dpkg -i "$DUF_DEB"
    rm -f "$DUF_DEB"
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
    FX_VER=$(curl -fsSL https://api.github.com/repos/antonmedv/fx/releases/latest |
      grep '"tag_name"' | cut -d'"' -f4)
    ARCH_FX="$(uname -m)"
    case "$ARCH_FX" in
      x86_64) ARCH_FX="amd64" ;;
      aarch64) ARCH_FX="arm64" ;;
    esac
    curl -fsSL "https://github.com/antonmedv/fx/releases/download/${FX_VER}/fx_linux_${ARCH_FX}" \
      -o /tmp/fx
    sudo install -m 755 /tmp/fx /usr/local/bin/fx
    rm -f /tmp/fx
  fi

  # ── yazi ────────────────────────────────────────────────────────────────────
  if ! command -v yazi &>/dev/null; then
    info "Installing yazi..."
    YAZI_VER=$(curl -fsSL https://api.github.com/repos/sxyazi/yazi/releases/latest |
      grep '"tag_name"' | cut -d'"' -f4)
    ARCH_Y="$(uname -m)"
    case "$ARCH_Y" in
      x86_64) ARCH_Y="x86_64" ;;
      aarch64) ARCH_Y="aarch64" ;;
    esac
    YAZI_TGZ="yazi-${ARCH_Y}-unknown-linux-musl.tar.gz"
    curl -fsSL "https://github.com/sxyazi/yazi/releases/download/${YAZI_VER}/${YAZI_TGZ}" |
      sudo tar -xz -C /usr/local/bin --strip-components=1 \
        "yazi-${ARCH_Y}-unknown-linux-musl/yazi"
  fi

  # ── rclone ──────────────────────────────────────────────────────────────────
  if ! command -v rclone &>/dev/null; then
    info "Installing rclone..."
    curl -fsSL https://rclone.org/install.sh | sudo bash
  fi

  # ── tldr (tealdeer) ─────────────────────────────────────────────────────────
  if ! command -v tldr &>/dev/null; then
    info "Installing tldr (tealdeer)..."
    TLDR_VER=$(curl -fsSL https://api.github.com/repos/dbrgn/tealdeer/releases/latest |
      grep '"tag_name"' | cut -d'"' -f4)
    ARCH_T="$(uname -m)"
    case "$ARCH_T" in
      x86_64) ARCH_T="x86_64-unknown-linux-musl" ;;
      aarch64) ARCH_T="aarch64-unknown-linux-musl" ;;
    esac
    curl -fsSL "https://github.com/dbrgn/tealdeer/releases/download/${TLDR_VER}/tealdeer-linux-${ARCH_T}" \
      -o /tmp/tldr
    sudo install -m 755 /tmp/tldr /usr/local/bin/tldr
    rm -f /tmp/tldr
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
