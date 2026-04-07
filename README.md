# VM Init

One-command setup for a fresh Linux, macOS, or Windows machine.

## Usage

> **Prerequisites:** Install [Git](https://git-scm.com/install/) before running the commands below.

### Linux / macOS

```bash
git clone https://github.com/kittaweek/vm-init.git vm-init && cd vm-init
bash install.sh
```

### Windows (PowerShell as Administrator)

```powershell
git clone https://github.com/kittaweek/vm-init.git vm-init; cd vm-init
.\install.ps1
```

## Pre-install steps (run automatically before packages)

| Step | Linux | macOS | Windows |
| ---- | ----- | ----- | ------- |
| Add current user to sudo/admin | ✓ (with confirmation prompt) | — | — |
| System update | `apt-get update && upgrade` | `brew update && upgrade` | `winget upgrade --all` |
| Swap file | ✓ (prompts for size in GB, persists via `/etc/fstab`) | — | — |

> All steps support both **ARM64** and **x86_64** architectures.

## Features

- Detects OS (Linux / macOS / Windows) and CPU architecture (ARM64 or x86)
- Installs common CLI tools on all platforms
- Applies OS-specific security hardening (Linux only)
- Installs Docker + Compose plugin + lazydocker + ctop on **non-ARM** machines
- Sets **fish** as the default shell
- Writes a shared `~/.config/fish/config.fish` with aliases and tool integrations

## Tools installed

| Tool        | Description                                       |
| ----------- | ------------------------------------------------- |
| `fish`      | Default shell                                     |
| `starship`  | Cross-shell prompt                                |
| `zoxide`    | Smarter `cd`                                      |
| `atuin`     | Shell history sync                                |
| `fzf`       | Fuzzy finder                                      |
| `bat`       | `cat` with syntax highlighting (aliased as `cat`) |
| `eza`       | Modern `ls` (aliased as `ls`, `ll`, `la`, `lt`)   |
| `ripgrep`   | Fast grep (`rg`)                                  |
| `fd`        | Fast `find`                                       |
| `delta`     | Better git diffs                                  |
| `yazi`      | Terminal file manager                             |
| `rclone`    | Cloud storage sync                                |
| `glow`      | Markdown renderer                                 |
| `fx`        | JSON viewer                                       |
| `jq`        | JSON processor                                    |
| `duf`       | Disk usage (aliased as `df`)                      |
| `btop`      | System monitor (aliased as `top`)                 |
| `htop`      | Process viewer                                    |
| `ncdu`      | Disk usage navigator                              |
| `mtr`       | Network diagnostics                               |
| `tldr`      | Simplified man pages                              |
| `tmux`      | Terminal multiplexer                              |
| `neovim`    | Text editor (aliased as `vim`)                    |
| `tailscale` | VPN mesh network                                  |

## Linux only

| Tool                  | Description                   |
| --------------------- | ----------------------------- |
| `ufw`                 | Firewall (deny in, allow SSH) |
| `fail2ban`            | Brute-force protection        |
| `unattended-upgrades` | Auto security updates         |
| `strace`              | System call tracer            |
| `openssh-client`      | SSH client                    |

## Docker (non-ARM only)

| Tool                      | Description                          |
| ------------------------- | ------------------------------------ |
| `docker` + compose plugin | Container runtime                    |
| `lazydocker`              | TUI for Docker                       |
| `ctop`                    | Container metrics (Linux/macOS only) |

## Verify installation

After running `install.sh` / `install.ps1`, check that all tools were installed successfully:

Linux / macOS:

```bash
bash verify.sh
```

Windows (PowerShell as Administrator):

```powershell
.\verify.ps1
```

Each tool is reported as installed (`✓`), missing (`✗`), or skipped (`–`) due to platform or architecture constraints. The script always runs to completion and shows a final pass/fail/skip count.

## Structure

```text
.
├── install.sh          # Entrypoint for Linux/macOS
├── install.ps1         # Entrypoint for Windows
└── setup/
    ├── common/
    │   ├── packages.sh       # Common tools (all platforms)
    │   ├── set-fish-shell.sh # Set fish as default shell
    │   ├── fish-config.sh    # fish config.fish + aliases
    │   └── starship.toml     # Starship prompt preset
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
