#!/usr/bin/env bash
set -euo pipefail

info() { echo "  [+] $*"; }

# ── Find fish binary ───────────────────────────────────────────────────────────
FISH_PATH="$(command -v fish 2>/dev/null || true)"

if [[ -z "$FISH_PATH" ]]; then
  echo "  [!] fish not found in PATH — skipping default shell setup."
  exit 0
fi

info "fish found at $FISH_PATH"

# ── Add fish to /etc/shells if missing ────────────────────────────────────────
if ! grep -qxF "$FISH_PATH" /etc/shells; then
  info "Adding $FISH_PATH to /etc/shells..."
  echo "$FISH_PATH" | sudo tee -a /etc/shells
fi

# ── Set fish as default shell ─────────────────────────────────────────────────
case "$(uname -s)" in
  Darwin) CURRENT_SHELL="$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')" ;;
  *) CURRENT_SHELL="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || true)" ;;
esac

if [[ "$CURRENT_SHELL" == "$FISH_PATH" ]]; then
  info "fish is already the default shell."
else
  info "Changing default shell to fish..."
  sudo chsh -s "$FISH_PATH" "$USER"
  info "Default shell changed. Re-login to apply."
fi
