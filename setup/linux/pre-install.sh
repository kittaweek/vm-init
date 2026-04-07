#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

info() { echo "  [+] $*"; }
warn() { echo "  [!] $*" >&2; }

# Resolve actual user (handle `sudo bash install.sh` case)
REAL_USER="${SUDO_USER:-$USER}"

# ── 1. Sudo privileges ─────────────────────────────────────────────────────────
echo ""
echo "── Sudo privileges ──"
if groups "$REAL_USER" | grep -qE '\bsudo\b|\bwheel\b'; then
  info "$REAL_USER already has sudo privileges. Skipping."
else
  echo "  User '$REAL_USER' does not have sudo privileges."
  echo "  This will add '$REAL_USER' to the sudo group,"
  echo "  granting full administrator access to this machine."
  echo ""
  read -r -p "  Confirm? [y/N] " _confirm
  if [[ "${_confirm,,}" == "y" ]]; then
    sudo usermod -aG sudo "$REAL_USER"
    info "$REAL_USER added to the sudo group. Re-login to apply."
  else
    warn "Skipped sudo setup — some install steps may fail without sudo."
  fi
fi

# ── 2. System update (works on both x86_64 and ARM64) ─────────────────────────
echo ""
echo "── System update ──"
info "Running apt-get update & upgrade..."
sudo apt-get update -qq
sudo apt-get upgrade -y
info "System packages up to date."

# ── 3. Swap file ───────────────────────────────────────────────────────────────
echo ""
echo "── Swap file ──"
SWAP_FILE="/swapfile"

# Show current swap
CURRENT_SWAP="$(swapon --show --noheadings 2>/dev/null || true)"
if [[ -n "$CURRENT_SWAP" ]]; then
  info "Current swap:"
  swapon --show
fi

echo ""
read -r -p "  Swap file size in GB (0 or Enter to skip): " _swap_gb
_swap_gb="${_swap_gb:-0}"

if [[ "$_swap_gb" =~ ^[1-9][0-9]*$ ]]; then
  # Disable and remove existing swapfile if present
  if swapon --show --noheadings | grep -q "^${SWAP_FILE}"; then
    info "Disabling existing swapfile..."
    sudo swapoff "$SWAP_FILE"
  fi
  [[ -f "$SWAP_FILE" ]] && sudo rm -f "$SWAP_FILE"

  info "Creating ${_swap_gb}GB swap file at ${SWAP_FILE}..."
  # fallocate is faster; fall back to dd on filesystems that don't support it
  sudo fallocate -l "${_swap_gb}G" "$SWAP_FILE" 2>/dev/null ||
    sudo dd if=/dev/zero of="$SWAP_FILE" bs=1G count="$_swap_gb" status=progress

  sudo chmod 600 "$SWAP_FILE"
  sudo mkswap "$SWAP_FILE"
  sudo swapon "$SWAP_FILE"

  # Persist across reboots via /etc/fstab
  if grep -q "^${SWAP_FILE}" /etc/fstab 2>/dev/null; then
    info "Swap file already in /etc/fstab."
  else
    echo "${SWAP_FILE} none swap sw 0 0" | sudo tee -a /etc/fstab >/dev/null
    info "Swap file added to /etc/fstab (persists on reboot)."
  fi

  info "Swap active: ${_swap_gb}GB"
  swapon --show
elif [[ "$_swap_gb" == "0" ]]; then
  info "Skipping swap file setup."
else
  warn "Invalid input '$_swap_gb' — skipping swap file setup."
fi
