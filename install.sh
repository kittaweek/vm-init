#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Detect OS ──────────────────────────────────────────────────────────────────
case "$(uname -s)" in
  Linux*) OS="linux" ;;
  Darwin*) OS="darwin" ;;
  MINGW* | MSYS* | CYGWIN*) OS="windows" ;;
  *)
    echo "Unsupported OS: $(uname -s)"
    exit 1
    ;;
esac

# ── Detect Architecture ────────────────────────────────────────────────────────
ARCH="$(uname -m)"
case "$ARCH" in
  arm64 | aarch64) IS_ARM=true ;;
  *) IS_ARM=false ;;
esac

export OS ARCH IS_ARM SCRIPT_DIR

echo "==> OS: $OS | ARCH: $ARCH | ARM: $IS_ARM"

# ── Pre-install: system update, sudo setup, swap (OS-specific) ────────────────
if [[ -f "$SCRIPT_DIR/setup/$OS/pre-install.sh" ]]; then
  echo "==> Running pre-install setup..."
  bash "$SCRIPT_DIR/setup/$OS/pre-install.sh"
fi

# ── Run common setup ───────────────────────────────────────────────────────────
echo "==> Running common setup..."
bash "$SCRIPT_DIR/setup/common/packages.sh"

# ── Run OS-specific setup ──────────────────────────────────────────────────────
echo "==> Running $OS setup..."
bash "$SCRIPT_DIR/setup/$OS/packages.sh"

# ── Docker (non-ARM only) ──────────────────────────────────────────────────────
if [[ "$IS_ARM" == "false" && "$OS" != "windows" ]]; then
  echo "==> Installing Docker (non-ARM)..."
  bash "$SCRIPT_DIR/setup/$OS/docker.sh"
fi

# ── Set default shell to fish ──────────────────────────────────────────────────
echo "==> Setting default shell to fish..."
bash "$SCRIPT_DIR/setup/common/set-fish-shell.sh"

# ── Apply fish config & aliases ────────────────────────────────────────────────
echo "==> Applying fish config..."
bash "$SCRIPT_DIR/setup/common/fish-config.sh"

echo ""
echo "==> Setup complete! Please restart your terminal."
