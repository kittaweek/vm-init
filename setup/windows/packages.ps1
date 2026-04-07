#Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Info($msg) { Write-Host "  [+] $msg" -ForegroundColor Cyan }

# ── Ensure winget is available ─────────────────────────────────────────────────
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Info "Installing winget (App Installer)..."
    $uri = "https://aka.ms/getwinget"
    $tmp = "$env:TEMP\AppInstaller.msixbundle"
    Invoke-WebRequest -Uri $uri -OutFile $tmp -UseBasicParsing
    Add-AppxPackage -Path $tmp
    Remove-Item $tmp
}

# ── winget packages ────────────────────────────────────────────────────────────
$packages = @(
    # Editors
    "vim.vim",
    "Neovim.Neovim",

    # Shell & prompt
    "Starship.Starship",
    "ajeetdsouza.zoxide",
    "fish-shell.fish",        # Windows build (preview)

    # Search & navigation
    "junegunn.fzf",
    "BurntSushi.ripgrep.MSVC",
    "sharkdp.fd",

    # File tools
    "7zip.7zip",
    "sharkdp.bat",
    "eza-community.eza",
    "sxyazi.yazi",
    "Rclone.Rclone",

    # System monitoring
    "aristocratos.btop4win",
    "muesli.duf",

    # Network
    "Tailscale.Tailscale",

    # Data & text
    "jqlang.jq",
    "charmbracelet.glow",

    # Git tools
    "dandavison.delta",

    # Shell history
    "atuinsh.atuin",

    # Misc
    "dbrgn.tealdeer",         # tldr
    "antonmedv.fx"
)

foreach ($pkg in $packages) {
    Info "Installing $pkg ..."
    winget install --id $pkg --silent --accept-package-agreements --accept-source-agreements
}

# ── Set fish as default shell for current user ─────────────────────────────────
# Note: Windows Terminal profile update is preferred over chsh
$fishPath = "$env:LOCALAPPDATA\Programs\fish\fish.exe"
if (Test-Path $fishPath) {
    Info "fish found at $fishPath"
    Info "To use fish: open Windows Terminal and set fish as default profile."
} else {
    Write-Warning "fish not found at expected path. Check winget install output."
}

# ── Reload PATH ────────────────────────────────────────────────────────────────
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path","User")

Info "Windows packages installed. Please restart your terminal."
