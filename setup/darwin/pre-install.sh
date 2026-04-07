#!/usr/bin/env bash
set -euo pipefail

info() { echo "  [+] $*"; }

# ── Ensure brew is in PATH ─────────────────────────────────────────────────────
if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# ── System update (works on both Apple Silicon ARM64 and Intel x86_64) ─────────
echo ""
echo "── System update ──"
info "Running brew update & upgrade..."
brew update --quiet
brew upgrade
info "Homebrew packages up to date."
