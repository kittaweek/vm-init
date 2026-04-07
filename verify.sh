#!/usr/bin/env bash
# verify.sh — Check that all expected tools from install.sh are present
set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

pass=0
fail=0
skip=0

# ── Helpers ────────────────────────────────────────────────────────────────────
check() {
  local label="$1"
  local cmd="${2:-$1}"
  if command -v "$cmd" &>/dev/null; then
    printf "  ${GREEN}✓${NC} %s\n" "$label"
    ((pass++))
  else
    printf "  ${RED}✗${NC} %s\n" "$label"
    ((fail++))
  fi
}

check_service() {
  local name="$1"
  if systemctl is-active --quiet "$name" 2>/dev/null; then
    printf "  ${GREEN}✓${NC} %s (service active)\n" "$name"
    ((pass++))
  else
    printf "  ${RED}✗${NC} %s (service not active)\n" "$name"
    ((fail++))
  fi
}

skip_item() {
  printf "  ${YELLOW}–${NC} %s\n" "$1"
  ((skip++))
}

section() {
  printf "\n${BOLD}── %s ──${NC}\n" "$*"
}

# ── Detect platform ────────────────────────────────────────────────────────────
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

printf "${BOLD}Platform:${NC} %s / %s\n" "$OS" "$ARCH"

# ── Common tools (Linux + macOS) ───────────────────────────────────────────────
section "Common tools"
check fish
check starship
# zoxide installer defaults to $HOME/.local/bin; install.sh forces /usr/local/bin
# Check both to handle pre-fix installs
if command -v zoxide &>/dev/null || [[ -x "${HOME}/.local/bin/zoxide" ]]; then
  printf "  ${GREEN}✓${NC} zoxide\n"
  ((pass++))
else
  printf "  ${RED}✗${NC} zoxide\n"
  ((fail++))
fi
# atuin installs to ~/.atuin/bin (no sudo) — not in system PATH by default
if command -v atuin &>/dev/null || [[ -x "${HOME}/.atuin/bin/atuin" ]]; then
  printf "  ${GREEN}✓${NC} atuin\n"
  ((pass++))
else
  printf "  ${RED}✗${NC} atuin\n"
  ((fail++))
fi
check fzf
check htop
check btop
check ncdu
check mtr
check ripgrep rg
check fd
check bat
check eza
check delta
check duf
check jq
check fx
check glow
check yazi
check rclone
check tldr
check tmux
check neovim nvim
check vim

# ── Linux-specific ─────────────────────────────────────────────────────────────
if [[ "$OS" == "linux" ]]; then
  section "Linux packages"
  check ssh
  check strace
  check ufw
  check "fail2ban" fail2ban-client
  check "unattended-upgrades" unattended-upgrade
  check tailscale

  section "Linux services"
  check_service ufw
  check_service fail2ban
  check_service unattended-upgrades
fi

# ── macOS-specific ─────────────────────────────────────────────────────────────
if [[ "$OS" == "darwin" ]]; then
  section "macOS packages"
  # Tailscale is installed as a cask; CLI may or may not be in PATH
  if command -v tailscale &>/dev/null || brew list --cask tailscale &>/dev/null 2>&1; then
    printf "  ${GREEN}✓${NC} tailscale\n"
    ((pass++))
  else
    printf "  ${RED}✗${NC} tailscale\n"
    ((fail++))
  fi
fi

# ── Docker (x86_64 / amd64 only) ──────────────────────────────────────────────
section "Docker (non-ARM)"
if [[ "$ARCH" == "x86_64" || "$ARCH" == "amd64" ]]; then
  check docker

  if docker compose version &>/dev/null 2>&1; then
    printf "  ${GREEN}✓${NC} docker compose plugin\n"
    ((pass++))
  else
    printf "  ${RED}✗${NC} docker compose plugin\n"
    ((fail++))
  fi

  check lazydocker

  # ctop: Linux + macOS only (not Windows, handled in verify.ps1)
  check ctop
else
  skip_item "Docker tools (ARM architecture — not installed)"
fi

# ── Summary ────────────────────────────────────────────────────────────────────
printf "\n%s\n" "────────────────────────────────"
printf "  ${GREEN}Passed :${NC}  %d\n" "$pass"
if [[ $fail -gt 0 ]]; then
  printf "  ${RED}Failed :${NC}  %d\n" "$fail"
else
  printf "  Failed :  %d\n" "$fail"
fi
if [[ $skip -gt 0 ]]; then
  printf "  ${YELLOW}Skipped:${NC}  %d\n" "$skip"
fi
printf "%s\n" "────────────────────────────────"
