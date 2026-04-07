# VM Init

Based on <https://github.com/kahnwong/nix>

One-command setup for a fresh Linux, macOS, or Windows machine.

## Usage

### Linux / macOS

```bash
git clone <repo-url> vm-init && cd vm-init
bash install.sh
```

### Windows (PowerShell as Administrator)

```powershell
git clone <repo-url> vm-init; cd vm-init
.\install.ps1
```

## Features

- Detects OS (Linux / macOS / Windows) and CPU architecture (ARM64 or x86)
- Installs common CLI tools on all platforms
- Applies OS-specific security hardening (Linux only)
- Installs Docker + Compose plugin + lazydocker + ctop on **non-ARM** machines
- Sets **fish** as the default shell
- Writes a shared `~/.config/fish/config.fish` with aliases and tool integrations

## Tools installed

| Tool | Description |
| ---- | ----------- |
| `fish` | Default shell |
| `starship` | Cross-shell prompt |
| `zoxide` | Smarter `cd` |
| `atuin` | Shell history sync |
| `fzf` | Fuzzy finder |
| `bat` | `cat` with syntax highlighting (aliased as `cat`) |
| `eza` | Modern `ls` (aliased as `ls`, `ll`, `la`, `lt`) |
| `ripgrep` | Fast grep (`rg`) |
| `fd` | Fast `find` |
| `delta` | Better git diffs |
| `yazi` | Terminal file manager |
| `rclone` | Cloud storage sync |
| `glow` | Markdown renderer |
| `fx` | JSON viewer |
| `jq` | JSON processor |
| `duf` | Disk usage (aliased as `df`) |
| `btop` | System monitor (aliased as `top`) |
| `htop` | Process viewer |
| `ncdu` | Disk usage navigator |
| `mtr` | Network diagnostics |
| `tldr` | Simplified man pages |
| `tmux` | Terminal multiplexer |
| `neovim` | Text editor (aliased as `vim`) |
| `tailscale` | VPN mesh network |
| `rclone` | Cloud sync |

## Linux only

| Tool | Description |
| ---- | ----------- |
| `ufw` | Firewall (deny in, allow SSH) |
| `fail2ban` | Brute-force protection |
| `unattended-upgrades` | Auto security updates |
| `strace` | System call tracer |
| `openssh-client` | SSH client |

## Docker (non-ARM only)

| Tool | Description |
| ---- | ----------- |
| `docker` + compose plugin | Container runtime |
| `lazydocker` | TUI for Docker |
| `ctop` | Container metrics (Linux/macOS only) |

## Structure

```text
.
├── install.sh          # Entrypoint for Linux/macOS
├── install.ps1         # Entrypoint for Windows
└── setup/
    ├── common/
    │   ├── packages.sh       # Common tools (all platforms)
    │   ├── set-fish-shell.sh # Set fish as default shell
    │   └── fish-config.sh    # fish config.fish + aliases
    ├── linux/
    │   ├── packages.sh       # Linux-specific packages & hardening
    │   └── docker.sh         # Docker for Linux (non-ARM)
    ├── darwin/
    │   ├── packages.sh       # Homebrew + macOS defaults
    │   └── docker.sh         # Docker Desktop for macOS (non-ARM)
    └── windows/
        ├── packages.ps1      # winget packages
        └── docker.ps1        # Docker Desktop for Windows (non-ARM)
```
