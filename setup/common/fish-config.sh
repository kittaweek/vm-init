#!/usr/bin/env bash
set -euo pipefail

info() { echo "  [+] $*"; }

FISH_CONFIG_DIR="${HOME}/.config/fish"
FISH_CONFIG="${FISH_CONFIG_DIR}/config.fish"

mkdir -p "$FISH_CONFIG_DIR"

info "Writing fish config to $FISH_CONFIG ..."

cat >"$FISH_CONFIG" <<'FISH'
# ── Path ───────────────────────────────────────────────────────────────────────
fish_add_path /usr/local/bin
fish_add_path $HOME/.local/bin

# ── zoxide (z command) ────────────────────────────────────────────────────────
if command -q zoxide
    zoxide init fish | source
end

# ── starship prompt ───────────────────────────────────────────────────────────
if command -q starship
    starship init fish | source
end

# ── atuin (shell history) ─────────────────────────────────────────────────────
if command -q atuin
    atuin init fish | source
end

# ── Aliases ───────────────────────────────────────────────────────────────────

# bat → cat replacement
if command -q bat
    alias cat='bat --paging=never'
end

# eza → ls replacement
if command -q eza
    alias ls='eza --icons --group-directories-first'
    alias ll='eza --icons --group-directories-first -l'
    alias la='eza --icons --group-directories-first -la'
    alias lt='eza --icons --tree --level=2'
end

# neovim → vim
if command -q nvim
    alias vim='nvim'
    alias vi='nvim'
end

# git shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'

# docker shortcuts
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'

# misc
alias ..='cd ..'
alias ...='cd ../..'
alias mkdir='mkdir -p'
alias df='duf'
alias top='btop'
FISH

# ── Starship config ───────────────────────────────────────────────────────────
STARSHIP_CONFIG_DIR="${HOME}/.config"
STARSHIP_CONFIG="${STARSHIP_CONFIG_DIR}/starship.toml"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$STARSHIP_CONFIG_DIR"

if [[ -f "${SCRIPT_DIR}/starship.toml" ]]; then
  info "Writing starship config to $STARSHIP_CONFIG ..."
  cp "${SCRIPT_DIR}/starship.toml" "$STARSHIP_CONFIG"
fi

info "fish config written."
