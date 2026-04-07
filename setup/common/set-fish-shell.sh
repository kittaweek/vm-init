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
# When invoked via `sudo bash install.sh`, $USER is root — use SUDO_USER to
# get the actual logged-in user whose shell should be changed
REAL_USER="${SUDO_USER:-$USER}"

case "$(uname -s)" in
  Darwin) CURRENT_SHELL="$(dscl . -read "/Users/$REAL_USER" UserShell 2>/dev/null | awk '{print $2}')" ;;
  *) CURRENT_SHELL="$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f7 || true)" ;;
esac

if [[ "$CURRENT_SHELL" == "$FISH_PATH" ]]; then
  info "fish is already the default shell."
else
  info "Changing default shell to fish for $REAL_USER..."
  sudo chsh -s "$FISH_PATH" "$REAL_USER"
  info "Default shell changed. Re-login to apply."
fi
