#!/usr/bin/env bash
set -euo pipefail

info() { echo "  [+] $*"; }

# Ensure brew is in PATH
if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# ── Docker Desktop (includes compose plugin) ──────────────────────────────────
if ! brew list --cask docker &>/dev/null 2>&1; then
  info "Installing Docker Desktop..."
  brew install --cask docker
fi

# ── lazydocker ────────────────────────────────────────────────────────────────
if ! command -v lazydocker &>/dev/null; then
  info "Installing lazydocker..."
  brew install lazydocker
fi

# ── ctop ─────────────────────────────────────────────────────────────────────
if ! command -v ctop &>/dev/null; then
  info "Installing ctop..."
  brew install ctop
fi

info "Docker setup complete."
info "Launch Docker Desktop from Applications to complete the initial setup."
