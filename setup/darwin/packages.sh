#!/usr/bin/env bash
set -euo pipefail

info() { echo "  [+] $*"; }

# ── Xcode Command Line Tools ───────────────────────────────────────────────────
if ! xcode-select -p &>/dev/null; then
  info "Installing Xcode Command Line Tools..."
  xcode-select --install
  # Wait for installation to complete
  until xcode-select -p &>/dev/null; do sleep 5; done
fi

# ── Homebrew ───────────────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Add brew to PATH (Apple Silicon: /opt/homebrew, Intel: /usr/local)
if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

brew update --quiet

# ── Tailscale (via brew cask for macOS app) ────────────────────────────────────
if ! brew list --cask tailscale &>/dev/null 2>&1; then
  info "Installing Tailscale..."
  brew install --cask tailscale
fi

# ── macOS-specific sensible defaults ──────────────────────────────────────────
info "Applying macOS defaults..."

# Show hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show file extensions in Finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Disable .DS_Store on network / USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Faster key repeat
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Restart Finder to apply changes
killall Finder 2>/dev/null || true

info "macOS-specific setup complete."
